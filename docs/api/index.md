# API Reference

[Home](/) > API

Welcome to the Claudux API reference. This section provides comprehensive documentation for both the command-line interface and the internal library functions.

## Overview

Claudux is built with a modular architecture consisting of:

- **CLI Interface** - The main command-line interface provided by `bin/claudux`
- **Core Libraries** - Modular Bash libraries in `lib/` providing specific functionality
- **Templates & Configuration** - Project-specific templates and configuration files

## Structure

### [CLI Interface](/api/cli)
Complete documentation of all available commands, options, flags, and usage patterns for the `claudux` command-line tool.

### [Library Functions](/api/library) 
Reference documentation for the internal Bash functions that power Claudux, including function signatures, parameters, and usage examples.

## Architecture Principles

Claudux follows Unix philosophy with these key principles:

- **Modular Design** - Each `lib/*.sh` file handles a specific domain (project detection, content protection, etc.)
- **Bash-First** - Core functionality implemented in Bash for maximum compatibility
- **Error Handling** - Consistent error handling with `set -u` and `set -o pipefail`
- **Function Validation** - All functions checked for existence before calling with `check_function()`

## Environment Variables

Claudux behavior can be controlled via these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDUX_VERBOSE` | Verbosity level (0-2) | `0` |
| `FORCE_MODEL` | Claude model selection (`opus`/`sonnet`) | `opus` |
| `CLAUDUX_MESSAGE` | Default directive for update command | - |
| `NO_COLOR` | Disable colored output | - |

## Development Guidelines

When extending Claudux:

1. **Follow naming conventions** - Use `snake_case` for functions and variables
2. **Use absolute paths** - Resolve paths with `resolve_script_path()`  
3. **Handle errors gracefully** - Use `error_exit()` function for consistent error reporting
4. **Validate dependencies** - Check command availability with `command -v`
5. **Clean up resources** - Use trap handlers for temporary files and background processes

## Next Steps

- Explore the [CLI Interface](/api/cli) for command-line usage
- Browse [Library Functions](/api/library) for internal API reference
- Check the [technical documentation](/technical/) for implementation details