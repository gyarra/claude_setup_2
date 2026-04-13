# Frontend CLAUDE.md

## Session Setup

```bash
cd frontend
npm install
```

## Pre-Commit Checks

```bash
npm run lint         # ESLint linting
npx tsc --noEmit     # TypeScript type checking
npm run build:local  # Build without env validation
```

## Key Directories

- `src/app/` — App Router pages and API routes
- `src/components/` — Reusable UI components
- `src/lib/` — Database client, utilities, type definitions
- `src/hooks/` — Custom React hooks

## Conventions

- User-facing text: [USER_LANGUAGE]
- Admin dashboard: English
- Use slugs for lookups and URLs, not names
