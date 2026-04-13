## Contributing to Claudux

Thanks for your interest in contributing! This project welcomes improvements of all sizes.

### Local setup

```bash
git clone https://github.com/leojkwan/claudux.git
cd claudux
npm link            # symlink for local dev
claudux check       # verify environment
claudux update      # generate docs
claudux serve       # preview at localhost:5173
```

### Project layout

```
bin/claudux          CLI entry point (bash)
lib/                 Library modules (colors, project detection, docs generation, etc.)
lib/codex-utils.sh   Codex backend adapter (loaded when CLAUDUX_BACKEND=codex)
lib/templates/       Per-framework prompt configs (React, Next.js, iOS, Go, etc.)
lib/vitepress/       VitePress scaffolding (config template, theme, vite config)
tests/               Pure-bash test suites (183 tests, zero deps)
docs/                Generated VitePress site (committed to repo)
assets/              Static assets (banner SVG, terminal demo, hero image)
.github/             CI workflows and issue/PR templates
```

### Code style

- Shell scripts should be POSIX-friendly where possible
- Keep functions small and descriptive
- Prefer clear output and stable UX over cleverness

### Pull requests

- Describe the problem, the approach, and screenshots if UI/UX changes
- Update docs if behavior changes
- Keep diffs focused; small and frequent PRs are easier to review

### Release process

1. Bump `version` in `package.json` and `package-lock.json`
2. Update `CHANGELOG.md` with the new version's changes
3. Commit: `git commit -m "release: vX.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push origin main --tags`

What happens automatically:
- `ci.yml` runs lint, structure, syntax, version, and test jobs on every push/PR
- `publish.yml` triggers on `v*` tags, runs the full CI suite, verifies the tag matches `package.json`, and publishes to npm with provenance
- `docs.yml` deploys the VitePress site to GitHub Pages on push to main

**Prerequisite:** The `NPM_TOKEN` repository secret must be configured in GitHub repo settings before the first tag publish. Generate a token at [npmjs.com/settings/tokens](https://www.npmjs.com/settings/~/tokens) (use "Automation" type).

### Learn more

- [Commands reference](https://leojkwan.github.io/claudux/guide/commands) (live docs)
- [README](./README.md)

By contributing, you agree to the MIT license.

## Publishing to npm (maintainers only)

Publishing is automated via GitHub Actions. To release:

```bash
# 1. Ensure version is bumped in package.json + package-lock.json
# 2. Ensure CHANGELOG.md is updated
# 3. Tag and push
git tag v1.2.0
git push origin main --tags
```

The `publish.yml` workflow will:
1. Run the full CI suite (lint, structure, syntax, version, 183 tests)
2. Verify the git tag matches `package.json` version
3. Publish to npm with `--provenance --access public`

For manual publish (fallback):
```bash
npm login
npm publish --access public
```

Package name: `claudux`. Requires Node 18+. Requires `NPM_TOKEN` secret in repo settings.
