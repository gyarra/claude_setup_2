---
name: s-run-dev-servers
description: Use when running the frontend dev server or backend services locally, especially in Docker where env files must be created from environment variables
---

# Running the Dev Servers

Steps to get the Next.js frontend and optionally the Django backend running locally.

The frontend is the primary dev server — it queries Supabase directly and doesn't depend on the backend. The backend is only needed when working on scrapers, Celery tasks, or management commands.

## Step 1: Install Dependencies

```bash
# Backend
cd backend
if [[ ! -f .venv/bin/activate ]]; then ./scripts/setup.sh; fi
source .venv/bin/activate
```

```bash
# Frontend
cd frontend
npm install
```

## Step 2: Create .env Files

Both apps read configuration from `.env` files, not from shell environment variables.

### If running locally (not Docker)

Copy the example files and fill in your values:

```bash
cp backend/.env.example backend/.env      # if example exists
cp frontend/.env.local.example frontend/.env.local  # if example exists
```

**backend/.env** needs at minimum:
- `DATABASE_URL` — Supabase-hosted PostgreSQL connection string
- `DJANGO_SECRET_KEY`
- `TMDB_READ_ACCESS_TOKEN` — for movie metadata matching

**frontend/.env.local** needs:
- `NEXT_PUBLIC_SUPABASE_URL` — Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — Supabase anonymous key

### If running in Docker

The Docker container has env vars injected via `--env-file`. Bridge them into the `.env` files the apps expect:

**backend/.env:**
```bash
cat > backend/.env << EOF
DATABASE_URL=${DATABASE_URL}
DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
TMDB_READ_ACCESS_TOKEN=${TMDB_READ_ACCESS_TOKEN}
CELERY_BROKER_URL=${CELERY_BROKER_URL:-redis://localhost:6379/0}
SENTRY_DSN=${SENTRY_DSN}
DEBUG=True
EOF
```

**frontend/.env.local:**
```bash
cat > frontend/.env.local << EOF
NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY}
EOF
```

## Step 3: Run Database Migrations

```bash
cd backend
source .venv/bin/activate
python manage.py migrate
```

In Docker, this connects to the remote Supabase-hosted PostgreSQL via `DATABASE_URL`. No local Postgres needed.

## Step 4: Start Servers

### Frontend only (most common)

```bash
cd frontend
npm run dev &
```

Wait a few seconds, then verify:
```bash
sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/
```

### Backend + Celery (when working on scrapers)

```bash
# Django (rarely needed as a web server — mainly for management commands)
cd backend
source .venv/bin/activate
python manage.py runserver 8000 &

# Celery worker (for scraper tasks)
celery -A config.celery_app worker --loglevel=info &

# Celery beat (for scheduled tasks)
celery -A config.celery_app beat --loglevel=info &
```

Redis must be running for Celery (`redis-server` or via Docker).

## Gotchas

1. **No local PostgreSQL in Docker** — the project defaults to `localhost:5432` if `DATABASE_URL` isn't set, which fails. Must use the remote Supabase DB via `DATABASE_URL`.
2. **Env vars vs .env files** — Docker injects env vars into the shell, but Django (via `python-dotenv`) and Next.js (via `.env.local`) read from files. You must bridge them.
3. **Redis required for Celery** — Celery tasks won't run without a Redis broker. Default is `redis://localhost:6379/0`.
4. **Git clone in Docker** — use `gh repo clone` instead of `git clone` (gh credentials are mounted, git credentials are not).
