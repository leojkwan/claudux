# {{PROJECT_NAME}} Next.js - Coding Patterns & Conventions

## Architecture

- App Router with layouts and nested routes
- Server Components by default; Client Components only when needed
- Data fetching via async Server Components and route handlers in `app/api`
- Co-locate components, styles, and tests near usage

## State & Data

- Prefer React state and server mutations; avoid global state unless necessary
- Use SWR/React Query only where caching is required
- Validate inputs on the server; never trust client data

## APIs

- REST handlers in `app/api/*/route.ts`
- Use a schema validator (e.g., zod) for inputs/outputs
- Return typed JSON; centralize error shapes

## Styling

- TailwindCSS preferred; CSS Modules for component-specific styles

## Testing

- Unit tests with Jest/Vitest
- E2E with Playwright using stable `data-testid` selectors

## Performance

- Stream responses when beneficial; defer client JS
- Optimize images with Next/Image; avoid large client bundles

## Security

- Secure cookies for auth; SameSite=strict
- Sanitize user content before rendering

---

This file is a reference only; generated `claudux.md` must reflect actual patterns in the repository.
