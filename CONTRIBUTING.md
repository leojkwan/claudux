## Contributing to Claudux

Thanks for your interest in contributing! This project welcomes improvements of all sizes.

Start with the in-repo docs for a full overview:

- Development guide: `docs/development/index.md`
- Contributing: `docs/development/contributing.md`
- Testing: `docs/development/testing.md`

Quick local setup:

```bash
git clone https://github.com/leokwan/claudux.git
cd claudux
npm i -g claudux  # optional: link globally

# Generate and preview docs
claudux update
claudux serve
```

Code style:

- Shell scripts should be POSIX-friendly where possible
- Keep functions small and descriptive
- Prefer clear output and stable UX over cleverness

Pull requests:

- Describe the problem, the approach, and screenshots if UI/UX changes
- Update docs if behavior changes
- Keep diffs focused; small and frequent PRs are easier to review

By contributing, you agree to the MIT license.
