#!/bin/bash

# Validate README links, VitePress config routes, and local documentation links.

set -u

OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            shift
            OUTPUT_FILE="${1:-}"
            shift || true
            ;;
        *)
            shift
            ;;
    esac
done

echo "🔍 Validating documentation links..."

if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js is required for documentation link validation"
    exit 1
fi

node - "$OUTPUT_FILE" <<'NODE'
const fs = require('fs');
const path = require('path');

const projectRoot = process.cwd();
const docsRoot = path.resolve(projectRoot, 'docs');
const publicRoot = path.join(docsRoot, 'public');
const readmeFile = path.join(projectRoot, 'README.md');
const outputFile = process.argv[2] || '';

function fail(message) {
    console.error(`❌ ${message}`);
    process.exit(1);
}

function repoPath(filePath) {
    return (path.relative(projectRoot, filePath) || '.').split(path.sep).join('/');
}

function lineAt(source, index) {
    return source.slice(0, index).split('\n').length;
}

function isWithin(rootPath, targetPath) {
    const relativePath = path.relative(rootPath, targetPath);
    return relativePath === ''
        || (!relativePath.startsWith(`..${path.sep}`) && relativePath !== '..' && !path.isAbsolute(relativePath));
}

function blankRange(characters, start, end) {
    for (let index = start; index < end; index += 1) {
        if (characters[index] !== '\n' && characters[index] !== '\r') {
            characters[index] = ' ';
        }
    }
}

function linesWithOffsets(source) {
    const lines = [];
    let start = 0;
    for (let index = 0; index <= source.length; index += 1) {
        if (index === source.length || source[index] === '\n') {
            lines.push({
                start,
                end: index === source.length ? index : index + 1,
                body: source.slice(start, index).replace(/\r$/, '')
            });
            start = index + 1;
        }
    }
    return lines;
}

function maskMarkdownBlocks(source) {
    const characters = source.split('');
    const lines = linesWithOffsets(source);
    let inFrontmatter = false;
    let fence = null;

    lines.forEach((line, lineIndex) => {
        if (lineIndex === 0 && /^\uFEFF?---\s*$/.test(line.body)) {
            inFrontmatter = true;
            blankRange(characters, line.start, line.end);
            return;
        }
        if (inFrontmatter) {
            blankRange(characters, line.start, line.end);
            if (/^(?:---|\.\.\.)\s*$/.test(line.body.trim())) {
                inFrontmatter = false;
            }
            return;
        }
        if (fence) {
            blankRange(characters, line.start, line.end);
            if (new RegExp(`^ {0,3}${fence.character}{${fence.length},}\\s*$`).test(line.body)) {
                fence = null;
            }
            return;
        }

        const openingFence = line.body.match(/^ {0,3}(`{3,}|~{3,})/);
        if (openingFence) {
            fence = {
                character: openingFence[1][0],
                length: openingFence[1].length
            };
            blankRange(characters, line.start, line.end);
        }
    });

    let masked = characters.join('');
    masked = masked.replace(/<!--[\s\S]*?(?:-->|$)/g, (comment) => comment.replace(/[^\r\n]/g, ' '));
    return masked;
}

function maskInlineCode(source) {
    const characters = source.split('');
    for (let index = 0; index < source.length; index += 1) {
        if (source[index] !== '`') {
            continue;
        }

        let length = 1;
        while (source[index + length] === '`') {
            length += 1;
        }

        const delimiter = '`'.repeat(length);
        let closing = source.indexOf(delimiter, index + length);
        while (closing !== -1
            && (source[closing - 1] === '`' || source[closing + length] === '`')) {
            closing = source.indexOf(delimiter, closing + length);
        }
        if (closing !== -1) {
            blankRange(characters, index, closing + length);
            index = closing + length - 1;
        }
    }
    return characters.join('');
}

function decodeEntities(value) {
    const named = { amp: '&', apos: "'", gt: '>', lt: '<', nbsp: ' ', quot: '"' };
    return value
        .replace(/&#x([0-9a-f]+);/gi, (_, digits) => String.fromCodePoint(Number.parseInt(digits, 16)))
        .replace(/&#([0-9]+);/g, (_, digits) => String.fromCodePoint(Number.parseInt(digits, 10)))
        .replace(/&([a-z]+);/gi, (match, name) => named[name.toLowerCase()] || match);
}

function unescapeMarkdown(value) {
    let result = '';
    for (let index = 0; index < value.length; index += 1) {
        if (value[index] === '\\' && index + 1 < value.length) {
            result += value[index + 1];
            index += 1;
        } else {
            result += value[index];
        }
    }
    return decodeEntities(result);
}

function normalizeLabel(value) {
    return unescapeMarkdown(value).trim().replace(/\s+/g, ' ').toLowerCase();
}

function referenceDefinitions(source) {
    const definitions = new Map();
    const ranges = [];
    linesWithOffsets(source).forEach((line) => {
        const match = line.body.match(/^ {0,3}\[([^\]]+)\]:[ \t]*(?:<([^>]+)>|(\S+))/);
        if (match) {
            definitions.set(normalizeLabel(match[1]), unescapeMarkdown(match[2] || match[3]));
            ranges.push([line.start, line.end]);
        }
    });
    return { definitions, ranges };
}

function closingBracket(source, opening) {
    let depth = 1;
    for (let index = opening + 1; index < source.length; index += 1) {
        if (source[index] === '\\') {
            index += 1;
        } else if (source[index] === '[') {
            depth += 1;
        } else if (source[index] === ']' && --depth === 0) {
            return index;
        }
    }
    return -1;
}

function skipWhitespace(source, start) {
    let index = start;
    while (index < source.length && /[ \t\r\n]/.test(source[index])) {
        index += 1;
    }
    return index;
}

function closingAfterTitle(source, start) {
    let index = skipWhitespace(source, start);
    if (source[index] === ')') {
        return index;
    }

    const opener = source[index];
    const closer = opener === '(' ? ')' : opener;
    if (opener !== '"' && opener !== "'" && opener !== '(') {
        return -1;
    }
    for (index += 1; index < source.length; index += 1) {
        if (source[index] === '\\') {
            index += 1;
        } else if (source[index] === closer) {
            index = skipWhitespace(source, index + 1);
            return source[index] === ')' ? index : -1;
        }
    }
    return -1;
}

function inlineDestination(source, openingParen) {
    let index = skipWhitespace(source, openingParen + 1);
    if (source[index] === ')') {
        return { target: '', closing: index };
    }

    if (source[index] === '<') {
        let target = '';
        for (index += 1; index < source.length; index += 1) {
            if (source[index] === '\\' && index + 1 < source.length) {
                target += source[index] + source[index + 1];
                index += 1;
            } else if (source[index] === '>') {
                const closing = closingAfterTitle(source, index + 1);
                return closing === -1 ? null : { target: unescapeMarkdown(target), closing };
            } else if (source[index] === '\n') {
                return null;
            } else {
                target += source[index];
            }
        }
        return null;
    }

    let target = '';
    let depth = 0;
    for (; index < source.length; index += 1) {
        const character = source[index];
        if (character === '\\' && index + 1 < source.length) {
            target += character + source[index + 1];
            index += 1;
        } else if (character === '(') {
            depth += 1;
            target += character;
        } else if (character === ')' && depth > 0) {
            depth -= 1;
            target += character;
        } else if (character === ')' || (/[ \t\r\n]/.test(character) && depth === 0)) {
            const closing = character === ')' ? index : closingAfterTitle(source, index);
            return closing === -1 ? null : { target: unescapeMarkdown(target), closing };
        } else {
            target += character;
        }
    }
    return null;
}

function markdownReferences(source, sourceFile) {
    const { definitions, ranges } = referenceDefinitions(source);
    const characters = source.split('');
    ranges.forEach(([start, end]) => blankRange(characters, start, end));
    const scan = characters.join('');
    const references = [];

    for (let index = 0; index < scan.length; index += 1) {
        if (scan[index] === '\\') {
            index += 1;
            continue;
        }

        const image = scan[index] === '!' && scan[index + 1] === '[';
        const link = scan[index] === '[' && scan[index - 1] !== '!';
        if (!image && !link) {
            continue;
        }

        const opening = image ? index + 1 : index;
        const closing = closingBracket(scan, opening);
        if (closing === -1) {
            continue;
        }

        const label = scan.slice(opening + 1, closing);
        let target = null;
        let end = closing;
        if (scan[closing + 1] === '(') {
            const parsed = inlineDestination(scan, closing + 1);
            if (parsed) {
                target = parsed.target;
                end = parsed.closing;
            }
        } else if (scan[closing + 1] === '[') {
            const referenceEnd = closingBracket(scan, closing + 1);
            if (referenceEnd !== -1) {
                const explicitLabel = scan.slice(closing + 2, referenceEnd) || label;
                target = definitions.get(normalizeLabel(explicitLabel)) ?? null;
                end = referenceEnd;
            }
        } else {
            target = definitions.get(normalizeLabel(label)) ?? null;
        }

        if (target !== null) {
            references.push({
                target,
                kind: image ? 'image' : 'link',
                sourceFile,
                sourceType: 'markdown',
                line: lineAt(source, index)
            });
            index = end;
        } else {
            index = closing;
        }
    }
    return references;
}

function plainHeading(value) {
    return value
        .replace(/`+([^`]+)`+/g, '$1')
        .replace(/!\[([^\]]*)\]\([^)]*\)/g, '')
        .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
        .replace(/<[^>]+>/g, '')
        .replace(/\\(.)/g, '$1')
        .replace(/[*_~]/g, '')
        .trim();
}

function vitePressSlug(value) {
    return value
        .normalize('NFKD')
        .replace(/[\u0300-\u036F]/g, '')
        .replace(/[\u0000-\u001f]/g, '')
        .replace(/[\s~`!@#$%^&*()\-_+=[\]{}|\\;:"'“”‘’<>,.?/]+/g, '-')
        .replace(/-{2,}/g, '-')
        .replace(/^-+|-+$/g, '')
        .replace(/^(\d)/, '_$1')
        .toLowerCase();
}

function pageAnchors(source, sourceFile) {
    const anchors = new Set();
    const duplicates = [];
    const lines = linesWithOffsets(source);

    for (let index = 0; index < lines.length; index += 1) {
        let heading = null;
        const atx = lines[index].body.match(/^ {0,3}#{1,6}(?:[ \t]+|$)(.*)$/);
        if (atx) {
            heading = atx[1].replace(/[ \t]+#+[ \t]*$/, '').trim();
        } else if (lines[index].body.trim()
            && index + 1 < lines.length
            && /^ {0,3}(?:=+|-+)[ \t]*$/.test(lines[index + 1].body)) {
            heading = lines[index].body.trim();
            index += 1;
        }
        if (heading === null) {
            continue;
        }

        const explicit = heading.match(/\s*\{#([^{}\s]+)\}\s*$/);
        if (explicit) {
            if (anchors.has(explicit[1])) {
                duplicates.push({
                    sourceFile,
                    line: lineAt(source, lines[index].start),
                    target: `${repoPath(sourceFile)}#${explicit[1]}`,
                    outputTarget: `${repoPath(sourceFile)}#${explicit[1]}`,
                    reason: `Duplicate explicit anchor '#${explicit[1]}'`
                });
            } else {
                anchors.add(explicit[1]);
            }
            continue;
        }

        const base = vitePressSlug(plainHeading(heading));
        let anchor = base;
        let suffix = 1;
        while (anchors.has(anchor)) {
            anchor = `${base}-${suffix}`;
            suffix += 1;
        }
        anchors.add(anchor);
    }

    return { anchors, duplicates };
}

function parseMarkdownFile(sourceFile) {
    const source = fs.readFileSync(sourceFile, 'utf8');
    const blockMasked = maskMarkdownBlocks(source);
    const inlineMasked = maskInlineCode(blockMasked);
    const { anchors, duplicates } = pageAnchors(blockMasked, sourceFile);
    return {
        anchors,
        duplicates,
        references: markdownReferences(inlineMasked, sourceFile)
    };
}

function markdownFiles(directory) {
    const files = [];
    fs.readdirSync(directory, { withFileTypes: true }).forEach((entry) => {
        if (entry.name === '.vitepress' || entry.name === 'node_modules' || entry.name === 'public') {
            return;
        }
        const entryPath = path.join(directory, entry.name);
        if (entry.isDirectory()) {
            files.push(...markdownFiles(entryPath));
        } else if (entry.isFile() && entry.name.endsWith('.md')) {
            files.push(entryPath);
        }
    });
    return files;
}

function skipJavaScriptTrivia(source, start) {
    let index = start;
    while (index < source.length) {
        if (/\s/.test(source[index])) {
            index += 1;
        } else if (source[index] === '/' && source[index + 1] === '/') {
            const end = source.indexOf('\n', index + 2);
            index = end === -1 ? source.length : end + 1;
        } else if (source[index] === '/' && source[index + 1] === '*') {
            const end = source.indexOf('*/', index + 2);
            index = end === -1 ? source.length : end + 2;
        } else {
            break;
        }
    }
    return index;
}

function javascriptString(source, start) {
    const quote = source[start];
    if (quote !== "'" && quote !== '"' && quote !== '`') {
        return null;
    }

    let value = '';
    let dynamic = false;
    for (let index = start + 1; index < source.length; index += 1) {
        if (source[index] === '\\' && index + 1 < source.length) {
            value += source[index + 1];
            index += 1;
        } else if (quote === '`' && source[index] === '$' && source[index + 1] === '{') {
            dynamic = true;
            index += 1;
        } else if (source[index] === quote) {
            return { value, dynamic, end: index + 1 };
        } else {
            value += source[index];
        }
    }
    return { value, dynamic: true, end: source.length };
}

function javascriptToken(source, start) {
    const string = javascriptString(source, start);
    if (string) {
        return string;
    }
    if (!/[A-Za-z_$]/.test(source[start])) {
        return null;
    }
    let end = start + 1;
    while (end < source.length && /[A-Za-z0-9_$]/.test(source[end])) {
        end += 1;
    }
    return { value: source.slice(start, end), dynamic: false, end };
}

function configReferences(configFile) {
    const source = fs.readFileSync(configFile, 'utf8');
    const references = [];
    let index = 0;

    while (index < source.length) {
        index = skipJavaScriptTrivia(source, index);
        const start = index;
        const token = javascriptToken(source, index);
        if (!token) {
            index += 1;
            continue;
        }
        index = token.end;
        if (token.value !== 'link') {
            continue;
        }

        let valueStart = skipJavaScriptTrivia(source, index);
        if (source[valueStart] !== ':') {
            continue;
        }
        valueStart = skipJavaScriptTrivia(source, valueStart + 1);
        const value = javascriptString(source, valueStart);
        if (value && !value.dynamic) {
            references.push({
                target: value.value,
                kind: 'link',
                sourceFile: configFile,
                sourceType: 'config',
                line: lineAt(source, start)
            });
            index = value.end;
        }
    }
    return references;
}

function isExternal(target) {
    return target.startsWith('//') || /^[A-Za-z][A-Za-z0-9+.-]*:/.test(target);
}

function localTarget(target) {
    const hash = target.indexOf('#');
    const beforeHash = hash === -1 ? target : target.slice(0, hash);
    const query = beforeHash.indexOf('?');
    return {
        encodedPath: query === -1 ? beforeHash : beforeHash.slice(0, query),
        encodedAnchor: hash === -1 ? '' : target.slice(hash + 1)
    };
}

function decodePart(value, label) {
    try {
        const decoded = decodeURIComponent(value);
        if (decoded.includes('\0')) {
            throw new Error();
        }
        return decoded;
    } catch (error) {
        throw new Error(`Invalid ${label} encoding`);
    }
}

function resolveReference(reference, targetPath) {
    const trailingSlash = targetPath.endsWith('/');
    const extension = path.posix.extname(targetPath.replace(/\/+$/, '')).toLowerCase();
    const kind = reference.kind === 'image'
        || (extension && extension !== '.md' && extension !== '.html' && extension !== '.htm')
        ? 'asset'
        : 'page';
    const sourceIsDocumentation = reference.sourceType === 'config'
        || isWithin(docsRoot, reference.sourceFile);
    const sourceRoot = sourceIsDocumentation ? docsRoot : projectRoot;
    const boundaryLabel = sourceIsDocumentation ? 'documentation root' : 'repository root';

    if (!targetPath) {
        return {
            kind,
            filePath: reference.sourceType === 'markdown'
                ? reference.sourceFile
                : path.join(docsRoot, 'index.md'),
            containmentRoot: sourceRoot,
            boundaryLabel
        };
    }

    const rooted = targetPath.startsWith('/');
    const base = sourceIsDocumentation && kind === 'asset' && rooted
        ? publicRoot
        : rooted || reference.sourceType === 'config'
            ? sourceRoot
            : path.dirname(reference.sourceFile);
    const containmentRoot = sourceIsDocumentation && kind === 'asset' && rooted
        ? publicRoot
        : sourceRoot;
    const relativeTarget = rooted ? targetPath.replace(/^\/+/, '') : targetPath;
    const unresolved = path.resolve(base, relativeTarget || '.');
    if (!isWithin(containmentRoot, unresolved)) {
        return { kind, escaped: true, boundaryLabel };
    }

    let filePath = unresolved;
    if (kind === 'page') {
        if (trailingSlash) {
            filePath = path.join(unresolved, 'index.md');
        } else if (extension === '.html' || extension === '.htm') {
            filePath = unresolved.slice(0, -extension.length) + '.md';
        } else if (extension !== '.md' && !(!sourceIsDocumentation
            && !extension && fs.existsSync(unresolved) && fs.statSync(unresolved).isFile())) {
            filePath = `${unresolved}.md`;
        }
    }
    return isWithin(containmentRoot, filePath)
        ? { kind, filePath, containmentRoot, boundaryLabel }
        : { kind, escaped: true, boundaryLabel };
}

function inspectFile(filePath, containmentRoot) {
    if (!fs.existsSync(filePath)) {
        return { exists: false };
    }
    try {
        const realPath = fs.realpathSync(filePath);
        if (!isWithin(containmentRoot, realPath)) {
            return { exists: false, escaped: true };
        }
        return { exists: fs.statSync(realPath).isFile(), realPath };
    } catch (error) {
        return { exists: false };
    }
}

function addBroken(broken, reference, target, reason, outputTarget) {
    broken.push({
        sourceFile: reference.sourceFile,
        line: reference.line,
        target: target || '(empty target)',
        reason,
        outputTarget: outputTarget || target || '(empty target)'
    });
}

function main() {
    if (!fs.existsSync(docsRoot) || !fs.statSync(docsRoot).isDirectory()) {
        fail('docs/ directory not found');
    }

    const configFile = [
        path.join(docsRoot, '.vitepress', 'config.ts'),
        path.join(docsRoot, '.vitepress', 'config.mjs'),
        path.join(docsRoot, '.vitepress', 'config.js')
    ].find((candidate) => fs.existsSync(candidate));
    if (!configFile) {
        fail('docs/.vitepress/config.(ts|mjs|js) not found');
    }

    const cache = new Map();
    const references = configReferences(configFile);
    const duplicateAnchors = [];

    if (fs.existsSync(readmeFile) && fs.statSync(readmeFile).isFile()) {
        const parsed = parseMarkdownFile(readmeFile);
        cache.set(fs.realpathSync(readmeFile), parsed);
        references.push(...parsed.references);
        duplicateAnchors.push(...parsed.duplicates);
    }

    markdownFiles(docsRoot).forEach((markdownFile) => {
        const parsed = parseMarkdownFile(markdownFile);
        cache.set(fs.realpathSync(markdownFile), parsed);
        references.push(...parsed.references);
        duplicateAnchors.push(...parsed.duplicates);
    });

    console.log('🔍 Checking for duplicate heading IDs...');
    if (duplicateAnchors.length === 0) {
        console.log('✅ No duplicate heading IDs found');
    } else {
        console.log('❌ Duplicate heading IDs found:');
        duplicateAnchors.forEach((duplicate) => {
            console.log(`   ${repoPath(duplicate.sourceFile)}:${duplicate.line}: ${duplicate.reason}`);
        });
    }

    const broken = [...duplicateAnchors];
    let valid = 0;
    let external = 0;

    references.forEach((reference) => {
        const target = reference.target.trim();
        if (isExternal(target)) {
            external += 1;
            return;
        }

        const { encodedPath, encodedAnchor } = localTarget(target);
        let targetPath;
        let anchor;
        try {
            targetPath = decodePart(encodedPath, 'path');
            anchor = decodePart(encodedAnchor, 'anchor');
        } catch (error) {
            addBroken(broken, reference, target, error.message, target);
            return;
        }

        if (reference.kind === 'image' && !targetPath) {
            addBroken(broken, reference, target, 'Image target is empty', target);
            return;
        }

        const resolved = resolveReference(reference, targetPath);
        if (resolved.escaped) {
            addBroken(broken, reference, target, `Path escapes ${resolved.boundaryLabel}`, target);
            return;
        }

        const inspected = inspectFile(resolved.filePath, resolved.containmentRoot);
        if (inspected.escaped) {
            addBroken(
                broken,
                reference,
                target,
                `Resolved path escapes ${resolved.boundaryLabel} through a symlink`,
                target
            );
            return;
        }

        const displayPath = repoPath(resolved.filePath);
        if (!inspected.exists) {
            const label = resolved.kind === 'asset' ? 'Missing asset' : 'Missing page';
            addBroken(broken, reference, target, `${label}: ${displayPath}`, displayPath);
            return;
        }

        if (anchor && resolved.kind === 'page') {
            let parsed = cache.get(inspected.realPath);
            if (!parsed) {
                parsed = parseMarkdownFile(inspected.realPath);
                cache.set(inspected.realPath, parsed);
            }
            if (!parsed.anchors.has(anchor)) {
                addBroken(
                    broken,
                    reference,
                    target,
                    `Missing anchor '#${anchor}' in ${displayPath}`,
                    `${displayPath}#${anchor}`
                );
                return;
            }
        }

        valid += 1;
    });

    if (outputFile) {
        const report = broken.length > 0
            ? `${broken.map((entry) => entry.outputTarget).join('\n')}\n`
            : '';
        fs.writeFileSync(outputFile, report);
    }

    console.log('');
    console.log('📊 Link validation summary:');
    console.log(`   ✅ Valid links: ${valid}`);
    if (external > 0) {
        console.log(`   🔗 External links: ${external} (skipped)`);
    }

    if (broken.length === 0) {
        console.log('');
        console.log('✅ All internal links validated successfully!');
        return;
    }

    console.log(`   ❌ Broken links: ${broken.length}`);
    console.log('');
    console.log('Broken links found:');
    broken.forEach((entry) => {
        console.log(`   ❌ ${repoPath(entry.sourceFile)}:${entry.line}: ${entry.target} → ${entry.reason}`);
    });
    console.log('These targets may need to be created or the links updated.');
    process.exitCode = 1;
}

main();
NODE
