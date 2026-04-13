# Architecture

## Overview

[PROJECT_DESCRIPTION]

## System Components

```
[PROJECT_NAME]/
├── backend/             # [BACKEND_FRAMEWORK] backend (Python)
│   ├── config/          # Project settings
│   ├── [APP_NAME]/      # Core app
│   │   ├── models/      # Database models
│   │   ├── services/    # Business logic
│   │   ├── tasks/       # Background tasks
│   │   ├── management/  # Management commands
│   │   └── utils/       # Utilities
│   └── scripts/         # Setup and utility scripts
├── frontend/            # [FRONTEND_FRAMEWORK] frontend (TypeScript)
│   ├── src/app/         # Pages and API routes
│   ├── src/components/  # Reusable components
│   └── src/lib/         # Client libraries and types
└── docs/                # Documentation
```

## Data Flow

<!-- Describe how data flows through your system -->
<!-- e.g., User request → Frontend → API/Database → Response -->

## Key Design Decisions

<!-- Document important architectural choices and their rationale -->
<!-- e.g., "Frontend accesses database directly via [DATABASE_CLIENT] rather than through a REST API because..." -->

## External Services

<!-- List external APIs and services your project depends on -->
<!-- e.g., Database hosting, authentication provider, CDN, monitoring -->
