# Reproduce the demo capture

The recording runs `python3 examples/demo.py` in a loopback ttyd terminal.
The example uses the real section patcher with supplied proposals. It does not
call a model or claim to test documentation generation quality.

Install Python 3, Node 18+, Bash, ttyd, FFmpeg, and Playwright with Chromium.
From the repository root, run:

```bash
node docs/capture.mjs
```

If Playwright is already installed elsewhere, set `PLAYWRIGHT_MODULE` to its
`index.mjs` path. The script records the terminal, waits for the demo's success
line, and writes PNG, WebM, MP4, a cover, and capture metadata to `docs/public/`.
It stops its ttyd process and browser when finished. Port 8832 must be free.

The paper icon was generated for this project. The bundled Space Grotesk font
is distributed under its [Open Font License](public/OFL.txt).
