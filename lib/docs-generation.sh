#!/bin/bash
# Documentation generation and update functions

STATE_FILE=".claudux-state.json"
CLAUDUX_PROMPT_VERSION="${CLAUDUX_PROMPT_VERSION:-docs-generation-v1}"
CLAUDUX_GENERATION_PROMPT_FILE=""
CLAUDUX_GENERATION_LOG_FILE=""

# Ephemeral temp files: honor TMPDIR (never hardcode /tmp). Pattern arg is the
# mktemp template basename, e.g. claudux-prompt-XXXXXX.
claudux_mktemp() {
    local template="${1:-claudux.XXXXXX}"
    local dir="${TMPDIR:-/tmp}"
    dir="${dir%/}"
    mktemp "$dir/$template" 2>/dev/null || mktemp
}

claudux_mktemp_dir() {
    local template="${1:-claudux.XXXXXX}"
    local dir="${TMPDIR:-/tmp}"
    dir="${dir%/}"
    mktemp -d "$dir/$template" 2>/dev/null || mktemp -d
}

# Build deterministic checkpoint metadata from the static analysis index.
# This stays best-effort so state saving never fails after successful docs output.
build_deterministic_state_metadata_json() {
    local prompt_version="${CLAUDUX_PROMPT_VERSION:-docs-generation-v1}"
    local index_file="${CLAUDUX_STATIC_INDEX_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/static-analysis.json}"

    if ! command -v node >/dev/null 2>&1; then
        printf '{"prompt_version":"%s","index":null,"manifest_hash":null,"source_hashes":[],"doc_section_hashes":[],"source_to_section_coverage":[]}' "$prompt_version"
        return 0
    fi

    node - "$prompt_version" "$index_file" <<'NODE'
const fs = require('fs');
const crypto = require('crypto');

const promptVersion = process.argv[2];
const indexFile = process.argv[3];

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function fallback(error) {
  return {
    prompt_version: promptVersion,
    index: null,
    manifest_hash: null,
    source_hashes: [],
    doc_section_hashes: [],
    source_to_section_coverage: [],
    error: error ? String(error.message || error) : undefined,
  };
}

function sectionHash(pagePath, section) {
  if (!section || !section.heading || !section.level || !fs.existsSync(pagePath)) {
    return null;
  }

  const lines = fs.readFileSync(pagePath, 'utf8').split(/\r?\n/);
  const headingPattern = new RegExp(
    `^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*$`
  );
  const start = lines.findIndex(line => headingPattern.test(line));
  if (start === -1) return null;

  let end = lines.length;
  for (let i = start + 1; i < lines.length; i += 1) {
    const match = lines[i].match(/^(#{1,6})\s+/);
    if (match && match[1].length <= section.level) {
      end = i;
      break;
    }
  }

  return sha256(lines.slice(start, end).join('\n'));
}

let metadata = fallback();

try {
  if (fs.existsSync(indexFile)) {
    const index = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
    const ownership = Array.isArray(index.source_ownership) ? index.source_ownership : [];

    metadata = {
      prompt_version: promptVersion,
      index: {
        path: indexFile,
        version: index.version ?? null,
        head_sha: index.head_sha ?? null,
      },
      manifest_hash: index.manifest?.sha256 ?? null,
      source_hashes: Array.isArray(index.source_files)
        ? index.source_files.map(file => ({ path: file.path, sha256: file.sha256 }))
        : [],
      doc_section_hashes: [],
      source_to_section_coverage: [],
    };

    for (const page of ownership) {
      for (const pattern of page.source_patterns || []) {
        metadata.source_to_section_coverage.push({
          source_pattern: pattern,
          page_id: page.page_id,
          section_id: null,
          path: page.path,
        });
      }

      for (const section of page.sections || []) {
        for (const pattern of section.source_patterns || []) {
          metadata.source_to_section_coverage.push({
            source_pattern: pattern,
            page_id: page.page_id,
            section_id: section.section_id,
            path: page.path,
          });
        }

        const digest = sectionHash(page.path, section);
        if (digest) {
          metadata.doc_section_hashes.push({
            path: page.path,
            page_id: page.page_id,
            section_id: section.section_id,
            heading: section.heading,
            pinned: section.pinned === true,
            sha256: digest,
          });
        }
      }
    }
  }
} catch (error) {
  metadata = fallback(error);
}

console.log(JSON.stringify(metadata, null, 2));
NODE
}

# Save a change-tracking checkpoint after successful doc generation.
# Records HEAD SHA, timestamp, backend used, and which files were documented.
save_claudux_state() {
    local head_sha
    head_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local backend="${CLAUDUX_BACKEND:-claude}"
    local deterministic_state
    deterministic_state=$(build_deterministic_state_metadata_json)

    # Collect documented files (everything under docs/ tracked by git + untracked new)
    local files_json="[]"
    if command -v git >/dev/null 2>&1; then
        local raw_files
        raw_files=$(git ls-files docs/ 2>/dev/null | sort | while IFS= read -r f; do
            # Escape backslashes and double-quotes for valid JSON strings
            local escaped
            escaped=$(printf '%s' "$f" | sed 's/\\/\\\\/g; s/"/\\"/g')
            printf '"%s",' "$escaped"
        done | sed 's/,$//')
        if [[ -n "$raw_files" ]]; then
            files_json="[$raw_files]"
        fi
        # files_json stays "[]" when docs/ has no tracked files
    fi

    cat > "$STATE_FILE" <<EOJSON
{
  "last_sha": "$head_sha",
  "last_run": "$timestamp",
  "backend": "$backend",
  "files_documented": $files_json,
  "deterministic": $deterministic_state
}
EOJSON
    info "Checkpoint saved to $STATE_FILE (sha: ${head_sha:0:7})"
}

# Load existing state file. Prints JSON to stdout.
# Returns 0 on success, 1 if no state file exists, 2 if state is corrupt.
load_claudux_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    # Validate JSON if jq is available; otherwise trust the file
    if command -v jq >/dev/null 2>&1; then
        if ! jq . "$STATE_FILE" >/dev/null 2>&1; then
            return 2
        fi
    fi
    cat "$STATE_FILE"
    return 0
}

# Print newline-delimited docs/manifest pathspecs used for incremental freshness.
claudux_docs_manifest_pathspecs() {
    printf '%s\n' \
        'docs/' \
        'docs-structure.json' \
        'docs-map.md' \
        '.ai-docs-style.md' \
        'docs-site-plan.json'
}

claudux_path_is_unsafe_generation_target() {
    local path="${1#./}"
    local component current="" remaining="$path"

    [[ -n "$path" ]] || return 1
    case "$path" in
        /*|..|../*|*/../*|*/..) return 0 ;;
    esac

    while [[ -n "$remaining" ]]; do
        if [[ "$remaining" == */* ]]; then
            component="${remaining%%/*}"
            remaining="${remaining#*/}"
        else
            component="$remaining"
            remaining=""
        fi

        [[ -z "$component" || "$component" == "." ]] && continue
        current="${current:+$current/}$component"
        [[ -L "$current" ]] && return 0
    done

    return 1
}

claudux_existing_generation_boundary_violations() {
    local path configured_manifest

    if [[ -e docs || -L docs ]]; then
        find docs \
            -type l -print0 -o \
            \( -type d \( \
                -name node_modules -o \
                -path '*/.vitepress/cache' -o \
                -path '*/.vitepress/dist' -o \
                -path '*/.vitepress/temp' \
            \) -prune \) 2>/dev/null
    fi

    if [[ -e .claudux || -L .claudux ]]; then
        find .claudux -type l -print0 2>/dev/null
    fi

    for path in \
        docs-structure.json \
        docs-map.md \
        .ai-docs-style.md \
        docs-site-plan.json \
        .claudux-state.json; do
        if claudux_path_is_unsafe_generation_target "$path"; then
            printf '%s\0' "$path"
        fi
    done

    if declare -F docs_structure_path >/dev/null 2>&1; then
        configured_manifest="$(docs_structure_path)"
        if [[ -n "$configured_manifest" ]] && claudux_path_is_unsafe_generation_target "$configured_manifest"; then
            printf '%s\0' "${configured_manifest#./}"
        fi
    fi
}

validate_generation_write_boundary() {
    local path
    local -a violations=()

    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if [[ ${#violations[@]} -eq 0 ]] || ! claudux_path_in_args "$path" "${violations[@]}"; then
            violations[${#violations[@]}]="$path"
        fi
    done < <(claudux_existing_generation_boundary_violations)

    if [[ ${#violations[@]} -eq 0 ]]; then
        return 0
    fi

    warn "DOCUMENTATION BOUNDARY VIOLATION: generation paths must stay repository-relative and not traverse symlinks"
    for path in "${violations[@]}"; do
        printf '   • %s\n' "$(claudux_format_generation_path "$path")" >&2
    done
    warn "Replace unsafe documentation paths with regular repository paths before claudux update."
    return 1
}

# True when generation is allowed to touch a repo path (docs tree, manifest
# config, or local claudux checkpoint/cache artifacts).
claudux_path_is_generation_allowed() {
    local path="${1#./}"
    local allowed=false

    [[ -z "$path" ]] && return 1
    [[ "$path" == docs/* ]] && allowed=true
    [[ "$path" == .claudux/* ]] && allowed=true

    # Honor a configured manifest path (CLAUDUX_DOCS_STRUCTURE /
    # DOCS_STRUCTURE_FILE) so legitimate updates to the active manifest are not
    # flagged as source boundary violations when it differs from the default.
    if declare -F docs_structure_path >/dev/null 2>&1; then
        local configured_manifest
        configured_manifest="$(docs_structure_path)"
        configured_manifest="${configured_manifest#./}"
        if [[ -n "$configured_manifest" && "$path" == "$configured_manifest" ]]; then
            allowed=true
        fi
    fi

    case "$path" in
        docs-structure.json|docs-map.md|.ai-docs-style.md|docs-site-plan.json|.claudux-state.json)
            allowed=true
            ;;
    esac

    $allowed || return 1
    ! claudux_path_is_unsafe_generation_target "$path"
}

_claudux_git_status_has_second_path() {
    case "$1" in
        *R*|*C*) return 0 ;;
    esac
    return 1
}

# NUL-delimited paths from git status. Renames emit BOTH sides so a source→docs
# move (e.g. `git mv src/foo.ts docs/foo.ts`) is caught on its removed source
# side rather than passing on the allowed destination alone.
claudux_git_status_paths() {
    local record status path original_path

    while IFS= read -r -d '' record; do
        [[ ${#record} -lt 3 ]] && continue
        status="${record:0:2}"
        path="${record:3}"
        printf '%s\0' "$path"

        if _claudux_git_status_has_second_path "$status"; then
            original_path=""
            IFS= read -r -d '' original_path || original_path=""
            if [[ -n "$original_path" ]]; then
                printf '%s\0' "$original_path"
            fi
        fi
    done < <(git status --porcelain=v1 -z --untracked-files=all 2>/dev/null)
}

# NUL-delimited non-allowed paths with uncommitted working-tree changes.
claudux_non_allowed_dirty_paths() {
    local path
    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if ! claudux_path_is_generation_allowed "$path"; then
            printf '%s\0' "$path"
        fi
    done < <(claudux_git_status_paths)
}

# NUL-delimited non-allowed paths changed in commits since start_sha..HEAD.
claudux_non_allowed_committed_paths_since() {
    local start_sha="$1"
    local path
    [[ -z "$start_sha" ]] && return 0
    # --no-renames so a source→docs move surfaces as delete(source)+add(docs)
    # and the removed source side is validated instead of being collapsed into
    # a single allowed rename destination.
    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if ! claudux_path_is_generation_allowed "$path"; then
            printf '%s\0' "$path"
        fi
    done < <(git diff --name-only -z --no-renames "$start_sha"..HEAD 2>/dev/null)
}

claudux_nul_file_contains_path() {
    local file="$1"
    local expected="$2"
    local candidate

    [[ -f "$file" ]] || return 1
    while IFS= read -r -d '' candidate; do
        [[ "$candidate" == "$expected" ]] && return 0
    done < "$file"
    return 1
}

claudux_path_in_args() {
    local expected="$1"
    shift
    local candidate

    for candidate in "$@"; do
        [[ "$candidate" == "$expected" ]] && return 0
    done
    return 1
}

claudux_path_mode() {
    local path="$1"
    # GNU stat -f reports the containing FILESYSTEM (with live free-block and
    # free-inode counters), not the file's permission bits, and still exits
    # successfully enough to shadow the fallback. Detect GNU first so the mode
    # string is deterministic on both stat flavors.
    if stat --version >/dev/null 2>&1; then
        stat -c '%a' "$path" 2>/dev/null || printf 'unknown'
    else
        stat -f '%Lp' "$path" 2>/dev/null || printf 'unknown'
    fi
}

claudux_path_kind() {
    local path="$1"

    if [[ -L "$path" ]]; then
        printf 'symlink'
    elif [[ -d "$path" ]]; then
        printf 'directory'
    elif [[ -e "$path" ]]; then
        printf 'file'
    else
        printf 'absent'
    fi
}

claudux_backup_generation_path() {
    local path="$1"
    local slot="$2"
    local kind
    kind=$(claudux_path_kind "$path")
    printf '%s\n' "$kind" > "$slot.kind"

    case "$kind" in
        symlink)
            readlink "$path" > "$slot.target"
            ;;
        directory)
            claudux_path_mode "$path" > "$slot.mode"
            cp -pR "$path" "$slot.data"
            ;;
        file)
            claudux_path_mode "$path" > "$slot.mode"
            cp -p "$path" "$slot.data"
            ;;
    esac
}

claudux_generation_backup_index_for_path() {
    local expected="$1"
    local paths_file="${CLAUDUX_GENERATION_START_DIRTY_FILE:-}"
    local path index=0

    [[ -f "$paths_file" ]] || return 1
    while IFS= read -r -d '' path; do
        if [[ "$path" == "$expected" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
        index=$((index + 1))
    done < "$paths_file"
    return 1
}

claudux_generation_path_matches_backup() {
    local path="$1"
    local index="$2"
    local slot="${CLAUDUX_GENERATION_SOURCE_BACKUP_DIR}/items/$index"
    local expected_kind actual_kind expected_mode actual_mode

    [[ -f "$slot.kind" ]] || return 1
    expected_kind=$(cat "$slot.kind")
    actual_kind=$(claudux_path_kind "$path")
    [[ "$actual_kind" == "$expected_kind" ]] || return 1

    case "$expected_kind" in
        absent)
            return 0
            ;;
        symlink)
            [[ "$(readlink "$path" 2>/dev/null)" == "$(cat "$slot.target")" ]]
            ;;
        directory)
            expected_mode=$(cat "$slot.mode")
            actual_mode=$(claudux_path_mode "$path")
            [[ "$actual_mode" == "$expected_mode" ]] || return 1
            diff -qr "$slot.data" "$path" >/dev/null 2>&1
            ;;
        file)
            expected_mode=$(cat "$slot.mode")
            actual_mode=$(claudux_path_mode "$path")
            [[ "$actual_mode" == "$expected_mode" ]] || return 1
            cmp -s "$slot.data" "$path"
            ;;
        *)
            return 1
            ;;
    esac
}

claudux_restore_generation_backup_path() {
    local path="$1"
    local index="$2"
    local slot="${CLAUDUX_GENERATION_SOURCE_BACKUP_DIR}/items/$index"
    local kind

    [[ -f "$slot.kind" ]] || return 1
    kind=$(cat "$slot.kind")
    rm -rf -- "$path"

    case "$kind" in
        absent)
            return 0
            ;;
        symlink)
            mkdir -p -- "$(dirname "$path")"
            ln -s -- "$(cat "$slot.target")" "$path"
            ;;
        directory)
            mkdir -p -- "$(dirname "$path")"
            cp -pR "$slot.data" "$path"
            ;;
        file)
            mkdir -p -- "$(dirname "$path")"
            cp -p "$slot.data" "$path"
            ;;
        *)
            return 1
            ;;
    esac
}

claudux_tree_contains_path() {
    local tree="$1"
    local expected="$2"
    local path=""

    [[ -n "$tree" ]] || return 1
    IFS= read -r -d '' path < <(git ls-tree --name-only -z "$tree" -- "$expected" 2>/dev/null) || true
    [[ "$path" == "$expected" ]]
}

claudux_restore_generation_index_path() {
    local path="$1"
    local source_tree="${CLAUDUX_GENERATION_START_INDEX_TREE:-${CLAUDUX_GENERATION_START_HEAD:-}}"

    if claudux_tree_contains_path "$source_tree" "$path"; then
        git restore --source="$source_tree" --staged -- "$path" >/dev/null 2>&1
    else
        git update-index --force-remove -- "$path" >/dev/null 2>&1 || true
    fi
}

claudux_restore_generation_worktree_path() {
    local path="$1"
    local backup_index=""
    local start_head="${CLAUDUX_GENERATION_START_HEAD:-}"

    backup_index=$(claudux_generation_backup_index_for_path "$path" 2>/dev/null || true)
    if [[ -n "$backup_index" ]]; then
        claudux_restore_generation_backup_path "$path" "$backup_index"
    elif claudux_tree_contains_path "$start_head" "$path"; then
        git restore --source="$start_head" --worktree -- "$path" >/dev/null 2>&1
    else
        rm -rf -- "$path"
    fi
}

rollback_generation_workspace_changes() {
    local current_head path rollback_failed=false
    local start_head="${CLAUDUX_GENERATION_START_HEAD:-}"

    current_head=$(git rev-parse HEAD 2>/dev/null || echo "")
    if [[ -n "$start_head" && -n "$current_head" && "$current_head" != "$start_head" ]]; then
        if ! git reset --soft "$start_head" >/dev/null 2>&1; then
            rollback_failed=true
        fi
    fi

    for path in "$@"; do
        if ! claudux_restore_generation_index_path "$path"; then
            rollback_failed=true
        fi
        if ! claudux_restore_generation_worktree_path "$path"; then
            rollback_failed=true
        fi
    done

    ! $rollback_failed
}

cleanup_generation_workspace_snapshot() {
    if [[ -n "${CLAUDUX_GENERATION_SOURCE_BACKUP_DIR:-}" ]]; then
        rm -rf -- "$CLAUDUX_GENERATION_SOURCE_BACKUP_DIR"
    fi
    CLAUDUX_GENERATION_SOURCE_BACKUP_DIR=""
    CLAUDUX_GENERATION_START_DIRTY_FILE=""
    CLAUDUX_GENERATION_START_INDEX_TREE=""
}

cleanup_docs_generation_runtime() {
    if [[ -n "${CLAUDUX_GENERATION_PROMPT_FILE:-}" ]]; then
        rm -f -- "$CLAUDUX_GENERATION_PROMPT_FILE"
    fi
    if [[ -n "${CLAUDUX_GENERATION_LOG_FILE:-}" ]]; then
        rm -f -- "$CLAUDUX_GENERATION_LOG_FILE"
    fi
    CLAUDUX_GENERATION_PROMPT_FILE=""
    CLAUDUX_GENERATION_LOG_FILE=""
    cleanup_generation_workspace_snapshot
}

claudux_format_generation_path() {
    local path="$1"

    if declare -F _format_git_path >/dev/null 2>&1; then
        _format_git_path "$path"
        return
    fi

    path=${path//\\/\\\\}
    path=${path//\"/\\\"}
    path=${path//$'\t'/\\t}
    path=${path//$'\n'/\\n}
    path=${path//$'\r'/\\r}
    printf '"%s"' "$path"
}

# Snapshot repo boundary before backend generation (issue #121 direction 3).
capture_generation_workspace_snapshot() {
    CLAUDUX_GENERATION_START_HEAD=""
    CLAUDUX_GENERATION_START_DIRTY_FILE=""
    CLAUDUX_GENERATION_START_INDEX_TREE=""
    CLAUDUX_GENERATION_SOURCE_BACKUP_DIR=""

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi

    validate_generation_write_boundary || return 1

    CLAUDUX_GENERATION_START_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")
    CLAUDUX_GENERATION_START_INDEX_TREE=$(git write-tree 2>/dev/null || echo "")
    CLAUDUX_GENERATION_SOURCE_BACKUP_DIR=$(claudux_mktemp_dir claudux-gen-source-XXXXXX) || return 1
    mkdir -p "$CLAUDUX_GENERATION_SOURCE_BACKUP_DIR/items"
    CLAUDUX_GENERATION_START_DIRTY_FILE="$CLAUDUX_GENERATION_SOURCE_BACKUP_DIR/paths"
    : > "$CLAUDUX_GENERATION_START_DIRTY_FILE"

    local path index=0
    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if claudux_nul_file_contains_path "$CLAUDUX_GENERATION_START_DIRTY_FILE" "$path"; then
            continue
        fi
        printf '%s\0' "$path" >> "$CLAUDUX_GENERATION_START_DIRTY_FILE"
        claudux_backup_generation_path "$path" "$CLAUDUX_GENERATION_SOURCE_BACKUP_DIR/items/$index" || {
            cleanup_generation_workspace_snapshot
            return 1
        }
        index=$((index + 1))
    done < <(claudux_non_allowed_dirty_paths)
}

# Fail closed and restore the pre-generation source state when generation
# touched paths outside docs/ + manifest config.
validate_generation_workspace_unchanged() {
    local retain_snapshot=false
    if [[ "${1:-}" == "--retain-snapshot" ]]; then
        retain_snapshot=true
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi
    if [[ -z "${CLAUDUX_GENERATION_START_HEAD:-}" ]]; then
        return 0
    fi

    local -a unexpected=()
    local path backup_index

    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if [[ ${#unexpected[@]} -eq 0 ]]; then
            unexpected[0]="$path"
        elif ! claudux_path_in_args "$path" "${unexpected[@]}"; then
            unexpected[${#unexpected[@]}]="$path"
        fi
    done < <(claudux_non_allowed_committed_paths_since "$CLAUDUX_GENERATION_START_HEAD")

    while IFS= read -r -d '' path; do
        [[ -z "$path" ]] && continue
        if claudux_nul_file_contains_path "${CLAUDUX_GENERATION_START_DIRTY_FILE:-}" "$path"; then
            continue
        fi
        if [[ ${#unexpected[@]} -eq 0 ]]; then
            unexpected[0]="$path"
        elif ! claudux_path_in_args "$path" "${unexpected[@]}"; then
            unexpected[${#unexpected[@]}]="$path"
        fi
    done < <(claudux_non_allowed_dirty_paths)

    if [[ -f "${CLAUDUX_GENERATION_START_DIRTY_FILE:-}" ]]; then
        while IFS= read -r -d '' path; do
            [[ -z "$path" ]] && continue
            backup_index=$(claudux_generation_backup_index_for_path "$path" 2>/dev/null || true)
            [[ -n "$backup_index" ]] || continue
            if ! claudux_generation_path_matches_backup "$path" "$backup_index"; then
                if [[ ${#unexpected[@]} -eq 0 ]]; then
                    unexpected[0]="$path"
                elif ! claudux_path_in_args "$path" "${unexpected[@]}"; then
                    unexpected[${#unexpected[@]}]="$path"
                fi
            fi
        done < "$CLAUDUX_GENERATION_START_DIRTY_FILE"
    fi

    if [[ ${#unexpected[@]} -eq 0 ]]; then
        if ! $retain_snapshot; then
            cleanup_generation_workspace_snapshot
        fi
        return 0
    fi

    warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    warn "SOURCE BOUNDARY VIOLATION: generation touched files outside docs/ and manifest paths"
    warn "The backend must not edit or commit source files during claudux update (issue #121)."
    for path in "${unexpected[@]}"; do
        print_color "RED" "   • $(claudux_format_generation_path "$path")" >&2
    done

    if rollback_generation_workspace_changes "${unexpected[@]}"; then
        warn "Rolled back unrelated source changes; generated docs remain available for review."
    else
        warn "Automatic rollback was incomplete. Review immediately with: git status && git diff"
    fi
    warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cleanup_generation_workspace_snapshot
    return 1
}

# Files that affect generated documentation freshness even before they are
# committed. `last_sha..HEAD` alone misses the common dogfood case where
# claudux has just patched tracked docs/config files in the worktree.
claudux_docs_worktree_changes() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi

    local pathspecs=()
    while IFS= read -r spec; do
        pathspecs+=("$spec")
    done < <(claudux_docs_manifest_pathspecs)

    {
        git diff --name-only -- "${pathspecs[@]}" 2>/dev/null || true
        git diff --name-only --cached -- "${pathspecs[@]}" 2>/dev/null || true
        git ls-files --others --exclude-standard -- "${pathspecs[@]}" 2>/dev/null || true
    } | sed '/^$/d' | sort -u
}

# Show what changed since last doc generation.
# Outputs list of files that were modified since the last checkpoint SHA.
claudux_diff_since_last() {
    local state rc
    state=$(load_claudux_state)
    rc=$?
    if [[ $rc -eq 1 ]]; then
        echo "No previous checkpoint — run 'claudux update' first."
        return 1
    fi
    if [[ $rc -eq 2 ]]; then
        echo "Checkpoint file is corrupt — run 'claudux update' to refresh."
        return 1
    fi

    local last_sha
    if command -v jq >/dev/null 2>&1; then
        last_sha=$(echo "$state" | jq -r '.last_sha')
    else
        last_sha=$(echo "$state" | grep '"last_sha"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    fi

    if [[ -z "$last_sha" ]] || [[ "$last_sha" == "unknown" ]]; then
        echo "Checkpoint SHA is unknown — cannot diff."
        return 1
    fi

    # Check if the SHA still exists in history
    if ! git cat-file -t "$last_sha" >/dev/null 2>&1; then
        echo "Checkpoint SHA $last_sha no longer in history (rebase/force-push?). Full rescan needed."
        return 1
    fi

    {
        git diff --name-only "$last_sha"..HEAD 2>/dev/null || true
        claudux_docs_worktree_changes
    } | sed '/^$/d' | sort -u
}

refresh_deterministic_generation_caches() {
    local changed_files="${1:-}"
    local impact_allowlist_file="${2:-}"

    if declare -F build_static_analysis_index >/dev/null 2>&1; then
        build_static_analysis_index || return 1
    fi

    if [[ -n "$changed_files" ]] && [[ -n "$impact_allowlist_file" ]] && declare -F resolve_impacted_docs_from_changed_files >/dev/null 2>&1; then
        CLAUDUX_CHANGED_FILES="$changed_files" CLAUDUX_IMPACT_ALLOWLIST_FILE="$impact_allowlist_file" \
            resolve_impacted_docs_from_changed_files >/dev/null || return 1
        export CLAUDUX_IMPACT_ALLOWLIST_FILE="$impact_allowlist_file"
    fi

    if declare -F capture_docs_structure_guard_snapshot >/dev/null 2>&1; then
        capture_docs_structure_guard_snapshot || return 1
    fi
}

retain_generation_debug_log() {
    local log_file="$1"
    local reason="${2:-generation-failure}"

    [[ -f "$log_file" ]] || return 0
    [[ -s "$log_file" ]] || return 0

    local safe_reason retained
    safe_reason=$(printf '%s' "$reason" | tr -c 'A-Za-z0-9_.-' '-')
    retained=$(claudux_mktemp "claudux-${safe_reason}.jsonl.XXXXXX")
    cp "$log_file" "$retained" 2>/dev/null || return 0
    warn "🧾 Retained backend JSONL log:"
    echo "      $retained"
}


# Build the comprehensive prompt for Claude
build_generation_prompt() {
    local project_type="$1"
    local project_name="$2"
    local user_directive="${3:-}"
    
    # Check for configuration files
    local style_guide=""
    local template_config=""
    local docs_map=""
    
    # AI style guide locations
    for location in ".ai-docs-style.md" "$HOME/.ai-docs-style.md" "/usr/local/share/.ai-docs-style.md"; do
        if [[ -f "$location" ]]; then
            style_guide="$location"
            break
        fi
    done
    
    # Template configuration (support both directory and file naming styles)
    if [[ -f "$LIB_DIR/templates/${project_type}/config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}/config.json"
    elif [[ -f "$LIB_DIR/templates/${project_type}-project-config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}-project-config.json"
    elif [[ -f "$LIB_DIR/templates/${project_type}-config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}-config.json"
    elif [[ -f "$LIB_DIR/templates/generic/config.json" ]]; then
        template_config="$LIB_DIR/templates/generic/config.json"
    fi
    
    # Documentation map / deterministic structure manifest. Prefer the tracked
    # manifest over legacy docs-map.md whenever both exist.
    local docs_structure_manifest=""
    local legacy_docs_map=""
    if declare -F docs_structure_path >/dev/null 2>&1; then
        docs_structure_manifest="$(docs_structure_path)"
    else
        docs_structure_manifest="docs-structure.json"
    fi
    if [[ ! -f "$docs_structure_manifest" ]]; then
        docs_structure_manifest=""
    fi
    if [[ -f "docs-map.md" ]]; then
        legacy_docs_map="docs-map.md"
    fi
    if [[ -n "$docs_structure_manifest" ]]; then
        docs_map="$docs_structure_manifest"
    elif [[ -n "$legacy_docs_map" ]]; then
        docs_map="$legacy_docs_map"
    fi
    
    # Project-specific coding patterns (CLAUDE.md)
    local claudux_patterns=""
    if [[ -f "CLAUDE.md" ]]; then
        claudux_patterns="CLAUDE.md"
    fi
    
    # Documentation site preferences (claudux.md)
    local claudux_prefs=""
    if [[ -f "claudux.md" ]]; then
        claudux_prefs="claudux.md"
    fi
    
    # Build the prompt
    local prompt="Analyze this ${project_type} project (${project_name}) and intelligently update the documentation following these guidelines:

**STEP 1: Read Configuration Files**"
    
    if [[ -n "$template_config" ]]; then
        prompt+="
- Read $template_config for ${project_type}-specific documentation patterns and structure"
    fi
    
    if [[ -n "$style_guide" ]]; then
        prompt+="
- Read $style_guide for universal AI documentation principles"
    fi
    
    if [[ -n "$docs_structure_manifest" ]]; then
        prompt+="
- Read $docs_map as the deterministic docs manifest: page IDs, paths, nav order, source ownership, required sections, pinned sections, and deletion_policy are binding inputs. Preserve them unless the manifest itself changes."
        if [[ -n "$legacy_docs_map" ]]; then
            prompt+="
- Read $legacy_docs_map as supplemental legacy guidance only; if it conflicts with $docs_map, the deterministic manifest wins."
        fi
    elif [[ -n "$legacy_docs_map" ]]; then
        prompt+="
- Read $legacy_docs_map for loose documentation guidance and protected areas"
    fi
    
    if [[ -n "$claudux_patterns" ]]; then
        prompt+="
- Read $claudux_patterns for project-specific coding patterns, conventions, and architectural guidelines"
    fi
    
    if [[ -n "$claudux_prefs" ]]; then
        prompt+="
- Read $claudux_prefs for documentation site preferences: sections to include/omit, nav items and order, sidebar policy (unified '/' vs per-section), outline depth, page naming/ordering conventions, logo policy, base path policy (dev '/' with CI via DOCS_BASE), and link rules (no placeholders)"
    fi
    
    prompt+="

**STEP 2: Analyze Codebase**
- Examine the current source files, build configuration, and architecture patterns
- Identify what documentation needs updating based on the structure configuration
- Focus on the specific areas and file patterns defined in the project config

**STEP 3: Two-Phase Documentation Generation**

==== PHASE 1: COMPREHENSIVE ANALYSIS & PLANNING ====
🧠 First, analyze the entire project and create a detailed plan:

1. **Read Configuration & Templates**:
   - Load all template configs, style guides, docs-map files, and docs-structure.json when present
   - Read lib/vitepress/sidebar-example.md for sidebar configuration patterns
   - Understand the expected documentation structure from templates
   - Note any protected areas, pinned sections, source-owned pages, and deletion policies
   - Analyze existing docs structure if present

2. **Analyze Codebase Structure**:
   - Scan source code to understand architecture
   - Identify key components, APIs, and features
   - Note testing approaches and build systems
   - Find main entry points and public interfaces

3. **Audit Existing Documentation**:
   - List all existing documentation files
   - Cross-reference each doc against current code
   - Identify outdated content (with confidence scores)
   - Find missing documentation gaps

4. **Create Detailed Execution Plan**:
   - List all NEW files to create with descriptions
   - List all files to UPDATE with specific changes
   - List any OBSOLETE files with 95%+ confidence
   - Show the final documentation structure

5. **Generate VitePress Configuration**:
   - Create docs/.vitepress/config.ts based on your analysis
   - Auto-detect project name, description from package.json/README or similar manifest files
   - For projects with logos/icons, detect and use them appropriately
    - Build sidebar structure matching your planned documentation
    - Include proper navigation categories suitable for the project type
    - Set up social links based on detected repository and package registry
   - Enable 3-column layout with outline configuration
    - Generate proper VitePress configuration structure
   - Base path policy:
     * Use environment-aware base: process.env.DOCS_BASE || '/'
     * Local development defaults to '/' (no DOCS_BASE set)
     * CI/deployment sets DOCS_BASE (e.g., '/claudux/' for GitHub Pages)
   - IMPORTANT: Reference sidebar-example.md for proper sidebar configuration
   - Build nested sidebar navigation that matches your documentation hierarchy
   - Use consistent patterns for section organization
   - Apply preferences from claudux.md when present (nav items and order, sections include/omit, sidebar policy, outline depth, naming/emoji policy)
   
   The config MUST include:
   - Dynamic sidebar object matching your doc structure
   - CRITICAL: Sidebar must appear on ALL pages including root:
     * Add a '/' root section to sidebar config
     * Include the same sidebar items for '/' as other sections
     * Example: sidebar: { '/': [...items], '/guide/': [...items] }
   - outline: { level: [2, 3], label: 'On this page' }
   - Proper nav array with main sections
   - Logo path if found
   - Clean URLs enabled

6. **Validate All Links**:
   CRITICAL: Every link in config.ts MUST correspond to a file you plan to create!
   - For each sidebar item link (e.g., '/guide/setup'), ensure you're creating 'guide/setup.md'
   - For hash links (e.g., '/guide/setup#installation'), ensure that heading exists
   - For nav links, verify the target files will exist
   - Use '/guide/' for index pages (maps to '/guide/index.md')
   - NO broken links allowed - this is a quality gate

 IMPORTANT: The config.ts must have zero broken links. Cross-check every link against your planned files.

 Platform guardrails:
  - For non-iOS projects, DO NOT include iOS-specific concepts, links, or pages (e.g., Tuist, SwiftData, CloudKit, App Store, TestFlight, Xcode). Only include them for \`project_type=ios\`.
 - Resources menu must include only links with absolute URLs you can determine (e.g., detected GitHub repo). Do not add placeholder links like '#'.
 - The nav must only include sections for which you will create pages (e.g., omit '/technical/' if you are not creating 'docs/technical/index.md').

DOCUMENTATION ACCURACY GUIDELINES:
  - For CLI tools: Analyze actual command implementations (e.g., bin scripts, package.json scripts) to document only commands that exist
  - For libraries: Document only exported functions/classes that are actually available
  - Installation: Base instructions on package.json, Cargo.toml, setup.py, or other manifest files
  - Requirements: Document actual prerequisites found in the codebase (Node version, Python version, system deps)
  - Examples: Use real code examples from the actual codebase, not hypothetical ones
  - Adapt tone and structure to match the project's domain (e.g., enterprise vs open source)
  - Respect existing documentation conventions if updating an existing docs folder

VITEPRESS CONFIGURATION BEST PRACTICES:
  - Only reference assets that exist in the project or that you're creating
  - Use detected social links (GitHub, npm) rather than placeholder URLs
  - If no logo is found, the theme will show a monogram - don't force a logo reference
  - Match sidebar structure to actual documentation files you're creating

PROJECT-SPECIFIC FLEXIBILITY:
  - Adapt documentation structure to the project's needs (not all projects need all sections)
  - Small libraries may only need API reference; large apps may need architecture docs
  - Use appropriate section names for the domain (e.g., Recipes for a cookbook app)
  - Include project-specific sections that make sense (e.g., Security for auth libraries)

Output your complete analysis and plan, then proceed to Phase 2.

==== PHASE 2: EXECUTE THE PLAN ====
✏️ Now systematically execute your plan from Phase 1:

**CREATE New Documentation**:
- Generate all planned documentation files
- Use accurate, current code examples
- Follow template structures exactly
- If docs-structure.json exists, only create pages or sections that are allowed by the manifest or explicitly propose the manifest change in your plan
- Reference CLAUDE.md for project-specific coding patterns and conventions when creating technical documentation
- Ensure all internal links work

VitePress Routing Rules:
- '/guide/' → 'docs/guide/index.md'
- '/guide/setup' → 'docs/guide/setup.md'
- '/guide/setup#install' → 'docs/guide/setup.md' with ## Install heading
- Always create index.md for directory roots

**UPDATE Existing Documentation**:
- Fix all outdated information identified
- Add missing sections or details
- Update code examples to current versions
- Preserve valuable existing content
- Preserve pinned sections and page structure from docs-structure.json; patch source-owned generated sections rather than rewriting whole files

- Respect project-specific conventions from CLAUDE.md if present
- Respect site preferences from claudux.md if present

**REMOVE Obsolete Files** (95%+ confidence only):
- Delete files referencing non-existent code
- Remove docs for deleted features
- Clean up superseded duplicate content
- Never delete manifest-listed pages or pinned sections unless docs-structure.json deletion_policy allows it

🎯 Quality Checks:
- Every code example must be from actual current code
- All links must point to existing files
- Technical details must match implementation
- No hypothetical or placeholder content
- Follow project's coding standards and conventions
- Use terminology consistent with the project's domain
- Respect any custom documentation patterns in CLAUDE.md
- Follow documentation site preferences in claudux.md if present
- **CRITICAL: Ensure all heading IDs are unique** - no duplicate {#id} attributes within or across files
- Use descriptive, hierarchical IDs (e.g., {#platform-android-issues} instead of {#android} twice)"
    
    # Append user directive if provided
    if [[ -n "$user_directive" ]]; then
        prompt+="

**USER DIRECTIVE (Highest Priority)**
- ${user_directive}

Strictly adhere to this directive while keeping ZERO broken links in config.ts and ensuring every link maps to a real file you create."
    fi

    echo "$prompt"
}

# Main update function
update() {
    # Parse optional flags (e.g., -m/--message/--with for a focused run)
    local user_message="${CLAUDUX_MESSAGE:-}"
    local already_autofixed="${CLAUDUX_AUTOFIXED:-}" # env guard to avoid loops
    local strict_mode=false
    local check_mode=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message|--with)
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    shift
                    user_message="$1"
                    shift
                elif [[ $# -gt 1 ]]; then
                    error_exit "Option $1 requires a non-option argument" 2
                else
                    error_exit "Option $1 requires an argument" 2
                fi
                ;;
            --strict)
                strict_mode=true
                shift
                ;;
            --check)
                check_mode=true
                shift
                ;;
            --)
                shift; break ;;
            -*)
                error_exit "Unknown option for 'update': $1. Usage: claudux update [--with|-m \"message\"] [--strict] [--check]" 2
                ;;
            *)
                error_exit "Unexpected argument: $1" 2
                ;;
        esac
    done
    # Resolve backend up-front so subsequent prints stay accurate.
    local backend="${CLAUDUX_BACKEND:-claude}"
    local incremental_changed_files=""
    local incremental_impact_allowlist_file=""

    info "📊 Starting documentation update..."
    echo ""

    # Show current git status
    show_git_status
    echo ""

    validate_generation_write_boundary || error_exit "Documentation write boundary is unsafe"

    # Legacy hook retained for compatibility; the current implementation is a no-op.
    cleanup_docs_silent

    info "🚀 Generating documentation..."

    # Heartbeat until the backend's first output lands; the stream formatter
    # takes over from there. Typical time to first output is 30-90s.
    local progress_pid
    progress_pid=$(show_progress "Generating (first output typically lands within 30-90s)" 15)
    
    # Build the prompt
    info "📝 Building prompt for $PROJECT_TYPE project..."
    if [[ -n "$user_message" ]]; then
        info "🎯 Focused directive: ${user_message:0:120}"
    fi
    load_project_config

    if declare -F validate_docs_structure_manifest >/dev/null 2>&1; then
        validate_docs_structure_manifest || error_exit "docs-structure.json failed validation before generation"
    fi

    local static_index_context=""
    if declare -F build_static_analysis_index >/dev/null 2>&1; then
        build_static_analysis_index || error_exit "Static analysis index failed"
        static_index_context=$(format_static_analysis_index_context)
    fi

    local section_patch_mode=false
    local section_patch_context=""
    if declare -F claudux_section_patch_mode_enabled >/dev/null 2>&1 && claudux_section_patch_mode_enabled; then
        section_patch_mode=true
        export CLAUDUX_SECTION_PATCH_MODE=1
        section_patch_context=$(format_section_patch_contract)
    fi

    if $check_mode && ! $section_patch_mode; then
        error_exit "update --check requires a committed docs-structure.json (manifest mode) so the backend runs read-only" 2
    fi
    if $check_mode; then
        export CLAUDUX_CHECK_MODE=1
    fi

    if declare -F capture_docs_structure_guard_snapshot >/dev/null 2>&1; then
        capture_docs_structure_guard_snapshot || error_exit "Documentation guard snapshot failed"
    fi
    
    # Debug project config
    info "   Project: $PROJECT_NAME (type: $PROJECT_TYPE)"
    
    local prompt
    prompt=$(build_generation_prompt "$PROJECT_TYPE" "$PROJECT_NAME" "$user_message")

    if [[ -n "$static_index_context" ]]; then
        prompt="${static_index_context}

$prompt"
    fi

    if [[ -n "$section_patch_context" ]]; then
        prompt="${section_patch_context}

$prompt"
    fi

    # Incremental mode: if a checkpoint exists and is valid, scope to changed files.
    # Corrupt state or missing file falls through to full scan silently.
    if [[ -f "$STATE_FILE" ]]; then
        local changed_files diff_rc
        changed_files=$(claudux_diff_since_last 2>/dev/null)
        diff_rc=$?
        if [[ $diff_rc -eq 0 ]] && [[ -n "$changed_files" ]]; then
            local count
            count=$(echo "$changed_files" | wc -l | tr -d ' ')
            info "Incremental mode: $count file(s) changed since last run"
            local file_list
            file_list=$(echo "$changed_files" | tr '\n' ', ' | sed 's/,$//')
            local impacted_docs=""
            if declare -F resolve_impacted_docs_from_changed_files >/dev/null 2>&1; then
                local impact_allowlist_file="${CLAUDUX_IMPACT_ALLOWLIST_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/impacted-docs.json}"
                impacted_docs=$(CLAUDUX_CHANGED_FILES="$changed_files" CLAUDUX_IMPACT_ALLOWLIST_FILE="$impact_allowlist_file" resolve_impacted_docs_from_changed_files 2>/dev/null || true)
                if [[ -f "$impact_allowlist_file" ]]; then
                    export CLAUDUX_IMPACT_ALLOWLIST_FILE="$impact_allowlist_file"
                    incremental_changed_files="$changed_files"
                    incremental_impact_allowlist_file="$impact_allowlist_file"
                fi
            fi
            local base_prompt="$prompt"
            prompt="INCREMENTAL UPDATE: Only the following $count files changed since the last documentation run. Focus your analysis and updates on these files and any docs that reference them. Do a full scan only if the changes affect project structure or config.

Changed files: $file_list
"
            if [[ -n "$impacted_docs" ]]; then
                prompt+="
Manifest-owned impacted docs/sections:
$impacted_docs
"
            fi

            prompt+="
$base_prompt"
        elif [[ $diff_rc -eq 0 ]]; then
            info "No source changes since last run — running full scan"
        else
            info "Checkpoint unusable — running full scan"
        fi
    fi

    # Check if prompt was built successfully
    if [[ -z "$prompt" ]]; then
        warn "❌ Failed to build generation prompt"
        warn "   PROJECT_TYPE: $PROJECT_TYPE"
        warn "   PROJECT_NAME: $PROJECT_NAME"
        warn "   Working directory: $(pwd)"
        error_exit "Cannot continue without a valid prompt"
    else
        success "Prompt built successfully (${#prompt} chars)"
    fi
    
    # Run Claude
    echo "" # Ensure clean line before Claude output
    info "🚀 Starting documentation generation..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save prompt for debugging
    # Create unique temp files for this session
    local prompt_file
    prompt_file=$(claudux_mktemp claudux-prompt-XXXXXX)
    local claude_log
    claude_log=$(claudux_mktemp claudux-claude-XXXXXX)
    CLAUDUX_GENERATION_PROMPT_FILE="$prompt_file"
    CLAUDUX_GENERATION_LOG_FILE="$claude_log"
    
    # Ensure we got valid temp files
    if [[ -z "$prompt_file" ]] || [[ -z "$claude_log" ]]; then
        error_exit "Failed to create temporary files"
    fi
    
    echo "$prompt" > "$prompt_file"
    capture_generation_workspace_snapshot || error_exit "Failed to capture the pre-generation source snapshot"

    local claude_exit_code=0

    # Function: run Claude once and stream output; return exit code.
    # All Claude-specific setup (model settings, output-format probe, formatter,
    # verbose flag) is scoped here so the codex path never triggers Claude CLI.
    run_claude_once() {
        local started=false
        : > "$claude_log"

        local model model_name timeout_msg cost_estimate
        # shellcheck disable=SC2034 # timeout_msg/cost_estimate destructured for future use
        IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"
        info "🧠 Model: $model_name"

        # Check if --output-format flag is supported
        local output_format_flag=""
        if claude --help 2>&1 | grep -q "output-format"; then
            output_format_flag="--output-format stream-json"
            info "🔄 Streaming mode enabled for real-time progress"
        fi
        local formatter="format_claude_output"
        if [[ -n "$output_format_flag" ]]; then
            formatter="format_claude_output_stream"
        fi

        # Always be verbose when streaming JSON
        local verbose_flag="--verbose"
        local allowed_tools="Read,Write,Edit,Delete"
        if $section_patch_mode; then
            allowed_tools="Read"
            info "Section patch mode: direct docs writes disabled for Claude"
        fi

        local claude_args=(
            --print
            --model "$model"
            --allowedTools "$allowed_tools"
        )
        # Docs generation never needs a shell: Write/Edit create files and
        # directories on their own. An explicit deny mechanically blocks
        # `git commit` and shell escapes even when the operator's own
        # ~/.claude/settings.json allow-list would otherwise permit Bash
        # (observed in a stranger test: the backend committed a source file
        # mid-generation — see issue #121).
        if claude --help 2>&1 | grep -q "disallowedTools"; then
            claude_args+=(--disallowedTools "Bash")
        fi
        # Config-home neutralization (issue #121): without this, the backend
        # loads the operator's personal ~/.claude/CLAUDE.md into generation
        # context, so docs output varies with whoever runs it. Excluding the
        # `user` source drops user-level settings and user CLAUDE.md while
        # keeping the repo's own project/local context and OAuth credentials
        # (verified live: user-memory probe answers LEAK without the flag,
        # CLEAN with it, auth unaffected).
        if claude --help 2>&1 | grep -q "setting-sources"; then
            claude_args+=(--setting-sources "project,local")
        fi
        if ! $section_patch_mode; then
            claude_args+=(--permission-mode acceptEdits)
        fi
        claude_args+=("$verbose_flag")
        if [[ -n "$output_format_flag" ]]; then
            claude_args+=(--output-format stream-json)
        fi
        claude_args+=("$prompt")

        if command -v stdbuf &> /dev/null; then
            ( stdbuf -o0 -e0 claude "${claude_args[@]}" 2>&1 | tee "$claude_log" ) | $formatter &
        else
            ( claude "${claude_args[@]}" 2>&1 | tee "$claude_log" ) | $formatter &
        fi
        local stream_pid=$!

        # Wait up to 20s for first bytes written to log
        for _ in $(seq 1 20); do
            if [[ -s "$claude_log" ]]; then
                started=true
                break
            fi
            sleep 1
        done

        if ! $started; then
            warn "⏱️  No visible progress after 20s"
            kill "$stream_pid" 2>/dev/null || true
            wait "$stream_pid" 2>/dev/null || true
            return 124
        fi

        # First output arrived — the stream formatter narrates from here.
        stop_progress "${progress_pid:-}"
        progress_pid=""

        trap 'echo ""; warn "Interrupt received, stopping generation..."; kill -TERM ${stream_pid} 2>/dev/null || true; [[ -n "$progress_pid" ]] && kill $progress_pid 2>/dev/null || true; wait ${stream_pid} 2>/dev/null || true; exit 130' INT
        wait ${stream_pid}
        local ec=$?
        trap - INT
        return $ec
    }

    # Function: run Codex once and stream output; return exit code
    run_codex_once() {
        local started=false
        : > "$claude_log"

        # shellcheck disable=SC2034 # codex_model/codex_timeout_msg/codex_effort destructured for future use
        IFS='|' read -r codex_model codex_model_name codex_timeout_msg codex_effort <<< "$(get_codex_model_settings)"
        info "Model: $codex_model_name"
        if $section_patch_mode; then
            info "Section patch mode: requesting read-only Codex sandbox"
        fi

        ( run_codex_exec "$prompt" | tee "$claude_log" ) | format_codex_output_stream &
        local stream_pid=$!

        for _ in $(seq 1 30); do
            if [[ -s "$claude_log" ]]; then
                started=true
                break
            fi
            sleep 1
        done

        if ! $started; then
            warn "No visible progress after 30s"
            kill "$stream_pid" 2>/dev/null || true
            wait "$stream_pid" 2>/dev/null || true
            return 124
        fi

        # First output arrived — the stream formatter narrates from here.
        stop_progress "${progress_pid:-}"
        progress_pid=""

        trap 'echo ""; warn "Interrupt received, stopping generation..."; kill -TERM ${stream_pid} 2>/dev/null || true; [[ -n "$progress_pid" ]] && kill $progress_pid 2>/dev/null || true; wait ${stream_pid} 2>/dev/null || true; exit 130' INT
        wait ${stream_pid}
        local ec=$?
        trap - INT
        return $ec
    }

    # Launch generation — route based on CLAUDUX_BACKEND
    claude_exit_code=1
    if [[ "$backend" == "codex" ]]; then
        info "Backend: Codex"
        run_codex_once
    else
        run_claude_once
    fi
    claude_exit_code=$?
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local backend_label="Claude CLI"
    [[ "$backend" == "codex" ]] && backend_label="Codex CLI"

    # Log backend invocation result
    if [[ $claude_exit_code -ne 0 ]]; then
        warn "❌ $backend_label exited with code: $claude_exit_code"
        if [[ -f "$claude_log" ]]; then
            warn "📋 Last output from $backend_label:"
            tail -20 "$claude_log" | sed 's/^/   /'
        fi
    fi
    
    # Kill the progress indicator
    if [[ -n "$progress_pid" ]]; then
        kill "$progress_pid" 2>/dev/null || true
        wait "$progress_pid" 2>/dev/null || true
    fi
    
    echo ""

    validate_generation_workspace_unchanged --retain-snapshot \
        || error_exit "Generation modified files outside allowed docs/manifest paths"
    
    if [[ $claude_exit_code -eq 0 ]]; then
        if $section_patch_mode; then
            local section_patch_file="${CLAUDUX_SECTION_PATCH_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/section-patches.json}"
            if ! extract_section_patch_payload "$claude_log" "$section_patch_file"; then
                retain_generation_debug_log "$claude_log" "section-patch-failure"
                error_exit "Section patch mode did not produce valid patch JSON"
            fi
            local patch_apply_out patch_apply_rc=0
            patch_apply_out=$(apply_manifest_section_patches "$section_patch_file" 2>&1) || patch_apply_rc=$?
            printf '%s\n' "$patch_apply_out"
            if $check_mode; then
                if [[ $patch_apply_rc -eq 2 ]]; then
                    echo ""
                    error_exit "Docs drift detected — run 'claudux update' to regenerate (rc=2)" 2
                elif [[ $patch_apply_rc -ne 0 ]]; then
                    error_exit "Section patch validation failed during --check"
                fi
                success "No proposed documentation changes; source coverage is not established"
                echo ""
                return 0
            fi
            if [[ $patch_apply_rc -ne 0 ]]; then
                error_exit "Section patch application failed"
            fi
            local patches_applied
            patches_applied=$(printf '%s\n' "$patch_apply_out" | sed -nE 's/.*applied ([0-9]+) section patch\(es\).*/\1/p' | tail -1)
            patches_applied="${patches_applied:-0}"
            success "Applied $patches_applied section patch(es) via deterministic write boundary"
            echo ""
        fi

        success "Documentation update complete!"
        echo ""

        # Update base path in docs/.vitepress/config.ts to use DOCS_BASE env var
        if [[ -f "docs/.vitepress/config.ts" ]]; then
            # Replace base path with environment-aware setting
            if grep -q "base:" "docs/.vitepress/config.ts" 2>/dev/null; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/base:[[:space:]]*[^,]*/base: process.env.DOCS_BASE || '\/'/g" "docs/.vitepress/config.ts"
                else
                    sed -i "s/base:[[:space:]]*[^,]*/base: process.env.DOCS_BASE || '\/'/g" "docs/.vitepress/config.ts"
                fi
            fi
        fi
        
        if declare -F validate_docs_structure_manifest >/dev/null 2>&1; then
            validate_docs_structure_manifest --post-generation || error_exit "docs-structure.json validation failed after generation"
        fi

        if declare -F validate_docs_structure_guard_snapshot >/dev/null 2>&1; then
            validate_docs_structure_guard_snapshot || error_exit "Protected documentation structure changed during generation"
        fi

        validate_generation_workspace_unchanged \
            || error_exit "Generation modified files outside allowed docs/manifest paths"

        # Validate links in generated documentation
        info "🔍 Step 3: Validating documentation links..."
        if [[ -f "$LIB_DIR/validate-links.sh" ]]; then
            set +e
            "$LIB_DIR/validate-links.sh"
            VALIDATE_EXIT=$?
            set -e
            echo ""
            if [[ $VALIDATE_EXIT -ne 0 ]]; then
                warn "⚠️  Link validation found issues. Some documentation links may be broken."

                # Attempt a single auto-fix pass: collect missing files and re-run with a focused directive
                if [[ -z "$already_autofixed" ]]; then
                    # Re-run validator to collect machine-readable list
                    local missing_tmp
                    missing_tmp=$(claudux_mktemp claudux-missing-XXXXXX)
                    rm -f "$missing_tmp" 2>/dev/null || true
                    if "$LIB_DIR/validate-links.sh" --output "$missing_tmp" >/dev/null 2>&1; then
                        : # no-op; shouldn't happen because prior run failed
                    fi
                    if [[ -s "$missing_tmp" ]]; then
                        local file_list
                        file_list=$(sed 's#^docs/##' "$missing_tmp" | tr '\n' ' ')
                        warn "🛠️  Auto-fix: asking Claude to create missing pages: $file_list"
                        echo ""

                        # Build a focused directive
                        local fix_msg="Create the following missing documentation files with correct frontmatter and minimal but accurate content; update navigation accordingly. Ensure config.ts links are valid and do not introduce new links that lack files. Missing files: ${file_list}"

                        # Mark as autofixed to avoid loops and re-run in-place (second pass)
                        if $strict_mode; then
                            CLAUDUX_AUTOFIXED=1 update --strict -m "$fix_msg"
                        else
                            CLAUDUX_AUTOFIXED=1 update -m "$fix_msg"
                        fi
                        return $?
                    fi
                fi

                warn "   Consider running 'claudux update -m \"Fill all missing pages and fix broken links\"' to target the fix."
                echo ""
                # Continue instead of exiting - validation is informational
                if $strict_mode; then
                    error_exit "❌ Broken links remain after generation. Strict mode is enabled."
                fi
            fi
        fi

        if declare -F refresh_deterministic_generation_caches >/dev/null 2>&1; then
            refresh_deterministic_generation_caches "$incremental_changed_files" "$incremental_impact_allowlist_file" || error_exit "Deterministic cache refresh failed"
        fi

        # Show detailed change summary
        info "📋 Step 4: Analyzing changes made..."
        show_detailed_changes

        # Save change tracking checkpoint
        save_claudux_state

    else
        warn "$backend_label failed with exit code $claude_exit_code"
        retain_generation_debug_log "$claude_log" "backend-failure"
        echo ""
        warn "🔧 Troubleshooting steps:"
        if [[ "$backend" == "codex" ]]; then
            local codex_stderr_log
            if declare -F codex_stderr_log_path >/dev/null 2>&1; then
                codex_stderr_log="$(codex_stderr_log_path)"
            else
                codex_stderr_log="${CODEX_STDERR_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/claudux/codex-stderr.log}"
            fi
            echo "   1. Check Codex CLI is authenticated:"
            echo "      codex login status"
            echo ""
            echo "   2. Try a supported Codex model:"
            echo "      CODEX_MODEL=gpt-5.4 CLAUDUX_BACKEND=codex claudux update"
            echo ""
            echo "   3. If the selected model requires a newer Codex CLI, upgrade:"
            echo "      npm install -g @openai/codex"
            echo ""
            echo "   4. View full stderr log:"
            echo "      $codex_stderr_log"
            echo ""
            echo "   5. Check internet connection"
        else
            echo "   1. Check Claude CLI is authenticated:"
            echo "      claude auth status"
            echo ""
            echo "   2. Try with a different model:"
            echo "      FORCE_MODEL=opus claudux update"
            echo ""
            echo "   3. Check internet connection"
            echo ""
            echo "   4. View full log:"
            echo "      Check Claude logs for details"
            echo ""
            echo "   5. Report issue:"
            echo "      https://github.com/firstbitelabsllc/claudux/issues"
        fi
        
        exit "$claude_exit_code"
    fi
}
