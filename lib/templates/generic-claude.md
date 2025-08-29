# {{PROJECT_NAME}} - AI Coding Assistant Rules

## Project Context
ALWAYS understand that this is a {{PROJECT_TYPE}} project. Follow the specific patterns and conventions found in this codebase.

## Code Style Rules

### MUST Follow
- USE the exact naming conventions found in existing files
- FOLLOW the import/dependency patterns already established
- MAINTAIN the existing directory structure and organization
- RUN tests before committing any changes
- FOLLOW the error handling patterns used throughout the codebase

### File Organization
- NEW files MUST follow the naming pattern found in similar existing files
- PLACE files in directories that match their purpose (follow existing structure)
- NEVER create files in directories that don't exist unless explicitly requested

## Testing Requirements
- ALWAYS write tests when adding new functionality
- USE the same testing framework and patterns found in existing test files
- RUN the test suite before committing: [DETECT AND INSERT ACTUAL TEST COMMAND]

## Common Patterns to Use
- FOLLOW the architectural patterns established in the codebase
- USE the same state management approach found in existing components
- IMPLEMENT error handling consistent with existing code

## Anti-Patterns to Avoid
- NEVER introduce new dependencies without checking if alternatives exist
- NEVER change established patterns without good reason
- NEVER commit directly to main branch (if git workflow detected)

## Project-Specific Commands
- BUILD: [DETECT AND INSERT ACTUAL BUILD COMMAND]
- TEST: [DETECT AND INSERT ACTUAL TEST COMMAND] 
- LINT: [DETECT AND INSERT ACTUAL LINT COMMAND]
- FORMAT: [DETECT AND INSERT ACTUAL FORMAT COMMAND]

This template should be populated with ACTUAL patterns found in the analyzed codebase.