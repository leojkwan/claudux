# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.1.x   | Yes       |
| < 1.1   | No        |

Only the latest published npm release receives security fixes.

## Reporting a Vulnerability

**Do not open a public issue.** Instead, email security concerns to **leojkwan@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce
- Affected version(s)
- Impact assessment (what an attacker could do)

You should receive an acknowledgment within 72 hours. Fixes for confirmed vulnerabilities will be released as patch versions and credited in the changelog unless you prefer to remain anonymous.

## Scope

Claudux runs locally on your machine. It shells out to the Claude CLI and Node.js to generate documentation. Security-relevant areas include:

- **Shell injection** -- claudux passes user-provided arguments (project paths, messages) to shell commands. Improper quoting or escaping could allow command injection.
- **File system access** -- the tool reads source files and writes to the `docs/` directory. Path traversal bugs could read or overwrite unintended files.
- **Dependency chain** -- claudux itself has zero npm runtime dependencies, but it invokes `npx vitepress` which pulls packages at runtime. Supply-chain attacks on VitePress or its transitive dependencies are in scope.
- **Secrets in generated docs** -- if source files contain credentials, those could be reproduced in the generated documentation. Claudux does not currently scrub secrets from output.

## Out of Scope

- Vulnerabilities in the Claude CLI itself (report to [Anthropic](https://www.anthropic.com/responsible-disclosure))
- Vulnerabilities in VitePress (report to [VitePress](https://github.com/vuejs/vitepress/security))
- Issues that require physical access to the machine running claudux
- Social engineering attacks

## Security Design Decisions

- **No network requests.** Claudux makes zero outbound network calls. All AI communication goes through the locally installed Claude CLI.
- **No runtime npm dependencies.** The attack surface from `node_modules` is zero at install time.
- **No eval or dynamic code execution.** Shell scripts use `set -u` and `set -o pipefail` for safer defaults.
- **Lock file for concurrency.** Prevents multiple claudux instances from corrupting the same docs directory simultaneously.
