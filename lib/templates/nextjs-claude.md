# {{PROJECT_NAME}} Next.js - AI Coding Assistant Rules

## Project Type: Next.js Application
This is a Next.js project. ALWAYS respect the Next.js conventions and patterns found in this specific codebase.

## Architecture Rules

### MUST Follow Next.js Patterns
- ALWAYS use App Router (app/) if that's what the project uses, OR Pages Router (pages/) if that's the pattern
- CREATE Server Components by default; only use 'use client' when absolutely necessary
- IMPLEMENT data fetching via async Server Components and route handlers in `app/api/*/route.ts`
- COLOCATE components, styles, and tests near their usage

### Component Patterns
- FOLLOW the existing component structure found in the codebase
- USE the same import patterns as existing components
- PLACE new components in the same directory structure as similar existing ones

## State Management Rules
- PREFER React state and server mutations over global state
- USE the same state management approach found in existing components
- ONLY add SWR/React Query/etc if it's already being used in the project
- VALIDATE inputs on the server; never trust client data

## API Development
- CREATE REST handlers in `app/api/*/route.ts` following existing patterns
- USE the same validation approach found in existing API routes
- RETURN typed JSON responses consistent with existing endpoints
- FOLLOW the error handling patterns established in the codebase

## Styling Rules
- USE the same CSS approach found in the project (Tailwind/CSS Modules/styled-components/etc.)
- FOLLOW existing className patterns and organization
- NEVER introduce new styling approaches without explicit request

## Testing Requirements
- WRITE tests using the same framework found in existing test files
- USE stable `data-testid` selectors if that's the pattern
- FOLLOW existing test file naming and organization
- RUN tests before committing: [INSERT ACTUAL TEST COMMAND FOUND IN PROJECT]

## Performance Rules
- OPTIMIZE images with next/image following existing patterns
- AVOID large client bundles by following existing code-splitting patterns
- STREAM responses when beneficial (if pattern exists in codebase)

## Security Rules
- USE secure cookies for auth following existing auth patterns
- SANITIZE user content before rendering (follow existing patterns)
- VALIDATE all inputs on server side following established patterns

## Build and Development Commands
- BUILD: [INSERT ACTUAL BUILD COMMAND]
- DEV: [INSERT ACTUAL DEV COMMAND]
- TEST: [INSERT ACTUAL TEST COMMAND]
- LINT: [INSERT ACTUAL LINT COMMAND]

This template should be populated with ACTUAL patterns found in the analyzed Next.js codebase.