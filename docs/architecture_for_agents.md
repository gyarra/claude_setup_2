# Architecture Reference for AI Agents

This document provides the context an AI agent needs to work effectively in this codebase. Keep it up to date as the architecture evolves.

## Project Summary

[PROJECT_DESCRIPTION]

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | [BACKEND_FRAMEWORK] | [BACKEND_NOTES] |
| Frontend | [FRONTEND_FRAMEWORK] | [FRONTEND_NOTES] |
| Database | [DATABASE] | [DATABASE_NOTES] |
| Task Queue | [TASK_QUEUE] | [TASK_QUEUE_NOTES] |

## Directory Map

<!-- List the most important directories and what they contain -->
<!-- Focus on what an agent needs to find things quickly -->

## Models / Schema

<!-- List your core models and their relationships -->
<!-- An agent needs this to write correct queries and migrations -->

## Services

<!-- List your service classes and what each is responsible for -->
<!-- Helps agents know where to add new logic vs. where to find existing logic -->

## Common Patterns

<!-- Document patterns that repeat across the codebase -->
<!-- e.g., "All background tasks inherit from BaseTask and use the track_run context manager" -->

## Testing Conventions

<!-- How to write tests in this project -->
<!-- e.g., "Use fixtures from conftest.py, not Model.objects.create()" -->

## Gotchas

<!-- Things that have tripped up agents (or humans) before -->
<!-- e.g., "Table names use underscore_case via Meta.db_table, not Django's default CamelCase" -->
