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
lib/templates/       VitePress scaffolding templates
docs/                Generated VitePress site (committed to repo)
assets/              Static assets (hero image, etc.)
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

1. Bump `version` in `package.json`
2. Commit: `git commit -m "Bump to X.Y.Z"`
3. Tag: `git tag vX.Y.Z`
4. Push: `git push origin main --tags`
5. The `docs.yml` workflow deploys the VitePress site to GitHub Pages on push to main

npm publish is manual for now:
```bash
npm login
npm publish
```

### Learn more

- [Commands reference](https://leojkwan.github.io/claudux/guide/commands) (live docs)
- [README](./README.md)

By contributing, you agree to the MIT license.

## Publishing to npm (maintainers only)

```bash
npm login
npm version patch   # or: minor | major
npm publish --access public
```

Package name: `claudux`. Requires Node 18+.
