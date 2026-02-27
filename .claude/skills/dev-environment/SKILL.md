---
name: dev-environment
description: Generates Docker Compose files and dev scripts from tech stack config. Creates environment-specific infrastructure for local development, QA, and production.
user-invokable: true
argument-hint: "[dev | qa | production | reset]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Dev Environment Generator

## Reference
- **ID**: S-ENG-D04
- **Category**: Engineering — DevOps
- **Inputs**: company.config.yaml (tech_stack section), existing docker-compose files
- **Outputs**: Docker Compose files, .env.example, convenience scripts
- **Used by**: User (directly), DevOps Engineer sub-agent
- **Tool scripts**: none (generates files directly)

## Purpose

Read the tech stack from `company.config.yaml` and generate Docker Compose files with environment-specific service configurations, plus convenience shell scripts for starting, stopping, and resetting the dev environment.

## When to Use

- After `/setup` completes — to set up local infrastructure
- When adding a new service to the tech stack (e.g., adding Redis for caching)
- When creating environment-specific configurations (dev, qa, production)
- When resetting the dev environment to a clean state

## Procedure

### Step 1: Read Configuration

Read `company.config.yaml` and extract:

- `company.name` — used as the Docker Compose project name
- `tech_stack.database` — PostgreSQL, MySQL, MongoDB, SQLite
- `tech_stack.cache` — Redis, Memcached, none
- `tech_stack.queue` — BullMQ, RabbitMQ, SQS, none
- `tech_stack.search` — Elasticsearch, Meilisearch, Typesense, none

If the tech stack is empty or unconfigured, advise the user to run `/setup` first.

### Step 2: Check for Existing Files

Scan the project for existing infrastructure files:

- `docker-compose.yml`, `docker-compose.*.yml` in the project root
- `infra/docker-compose.*.yml` in the infra directory
- `Dockerfile` in the project root
- `.env`, `.env.example`, `.env.local`

If existing Docker Compose files are found:
1. Present what was found to the user
2. Offer options: **review** existing files, **merge** new services into them, or **generate alongside** in `infra/`
3. Wait for user decision before proceeding
4. **Never overwrite** existing files without explicit approval

If no existing files are found, proceed to Step 3.

### Step 3: Look Up Current Docker Images

Before generating, use Context7 to verify current best-practice Docker images for each configured service. Fall back to the defaults below if Context7 is unavailable:

| Config Value | Docker Service | Default Image | Default Port |
|---|---|---|---|
| `PostgreSQL` | `postgres` | `postgres:16-alpine` | 5432 |
| `MySQL` | `mysql` | `mysql:8.0` | 3306 |
| `MongoDB` | `mongo` | `mongo:7` | 27017 |
| `Redis` | `redis` | `redis:7-alpine` | 6379 |
| `Memcached` | `memcached` | `memcached:1.6-alpine` | 11211 |
| `RabbitMQ` | `rabbitmq` | `rabbitmq:3-management-alpine` | 5672, 15672 |
| `BullMQ` | (uses Redis) | (reuse redis service) | — |
| `Elasticsearch` | `elasticsearch` | `elasticsearch:8.12.0` | 9200 |
| `Meilisearch` | `meilisearch` | `getmeili/meilisearch:latest` | 7700 |
| `Typesense` | `typesense` | `typesense/typesense:27.1` | 8108 |

### Step 3.5: Detect Services and Resolve App Ports

In addition to infrastructure services, detect what application services the project will run. Read from `company.config.yaml`:

- `tech_stack.framework` — determines the primary server type
- `platforms.targets` — if includes `web` and framework is backend-only, a separate web frontend exists
- `platforms.mobile_framework` — if includes `expo` or `react-native`, a mobile dev server exists
- `tech_stack.queue` — if not empty/none, a worker process likely exists

**Framework Defaults Table** — use this to derive port, start command, and health path for each framework:

| Framework | Type | Default Port | Start Command | Health Path |
|-----------|------|-------------|---------------|-------------|
| Next.js | fullstack | 3000 | `npm run dev` | `/api/health` |
| SvelteKit | fullstack | 5173 | `npm run dev` | `/` |
| NestJS | backend | 3000 | `npm run start:dev` | `/health` |
| Express | backend | 3000 | `npm run dev` | `/health` |
| FastAPI | backend | 8000 | `uvicorn main:app --reload` | `/health` |
| Django | backend | 8000 | `python manage.py runserver` | `/health` |
| Flask | backend | 5000 | `flask run --reload` | `/health` |
| Gin | backend | 8080 | `go run main.go` | `/health` |
| Rails | backend | 3000 | `bin/rails server` | `/up` |
| Spring Boot | backend | 8080 | `./mvnw spring-boot:run` | `/actuator/health` |
| Laravel | backend | 8000 | `php artisan serve` | `/health` |
| React (Vite) | frontend | 5173 | `npm run dev` | `/` |

**Service detection rules:**

| Config Signals | Service | Port Variable | Default |
|---------------|---------|--------------|---------|
| Framework is fullstack (Next.js, SvelteKit) | Combined web+API | `PORT` | From table above |
| Framework is backend-only | API server | `API_PORT` | From table above |
| `platforms.targets` includes `web` AND framework is backend-only | Web frontend | `WEB_PORT` | 5173 |
| `platforms.mobile_framework` includes `expo` or `react-native` | Mobile dev server | `EXPO_PORT` | 8081 |
| `tech_stack.queue` is not empty/none | Worker process | `WORKER_PORT` | 9000 |

If `platforms.targets` is empty but framework is fullstack, assume web is included (no separate `WEB_PORT`).

If the framework is not in the table, default to port 3000, `npm run dev`, `/health` and flag it to the user.

### Step 4: Generate Files

Determine the environment from the argument (default: `dev`).

**Always generate these files:**

#### `infra/docker-compose.dev.yml`

```yaml
# Generated by Company OS — /dev-environment
# Services derived from company.config.yaml tech_stack

services:
  # [services based on tech_stack config]
  # Each service includes:
  #   - Named volume for data persistence
  #   - Health check
  #   - Exposed ports (dev only)
  #   - Environment variables referencing .env

volumes:
  # Named volumes for each service
```

**Dev environment specifics:**
- Expose all service ports to localhost
- Use named volumes for data persistence across restarts
- Include health checks for each service
- Set `restart: unless-stopped`
- Use environment variables from `.env` file

#### `.env.example`

Template with all required environment variables. Include **app service ports** (from Step 3.5) before infrastructure vars:

```bash
# --- App Ports (from Step 3.5 service detection) ---
# Naming convention: SERVICE_PORT (e.g., API_PORT, WEB_PORT, EXPO_PORT)
# For fullstack frameworks (Next.js, SvelteKit), use PORT instead
API_PORT=8000          # FastAPI default — change if port conflicts
WEB_PORT=3000          # React/Vite frontend
# EXPO_PORT=8081       # Uncomment if mobile dev server needed
# WORKER_PORT=9000     # Uncomment if background workers used

# --- Infrastructure ---
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_dev
DB_USER=postgres
DB_PASSWORD=postgres

# Cache (if configured)
REDIS_URL=redis://localhost:6379

# Queue (if configured)
# ...
```

Only include the port variables for services detected in Step 3.5. Comment out ports for services not configured. Always add a comment noting the framework default and that it can be changed if there are port conflicts.

#### `tools/dev/start.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
docker compose -f infra/docker-compose.dev.yml up -d
echo "Dev environment started. Services:"
docker compose -f infra/docker-compose.dev.yml ps
```

#### `tools/dev/stop.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
docker compose -f infra/docker-compose.dev.yml down
echo "Dev environment stopped."
```

#### `tools/dev/reset.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Resetting dev environment (removing volumes)..."
docker compose -f infra/docker-compose.dev.yml down -v
docker compose -f infra/docker-compose.dev.yml up -d
echo "Dev environment reset. Fresh state."
```

**On request** (when argument specifies other environments):

#### `infra/docker-compose.qa.yml`
- Production-like settings
- No exposed ports (services communicate via Docker network only)
- Resource limits defined
- Production image tags

#### `infra/docker-compose.production.yml`
- For VPS deployments via docker-compose
- Restart policies: `always`
- No volume mounts to host
- Production-grade passwords (reference from environment)

### Step 5: Make Scripts Executable

Run `chmod +x tools/dev/start.sh tools/dev/stop.sh tools/dev/reset.sh` to ensure scripts are executable.

### Step 6: Validate (Optional)

If Docker is available on the system, validate the generated compose file:

```bash
docker compose -f infra/docker-compose.dev.yml config
```

If validation fails, fix the issue and re-validate. If Docker is not installed, skip this step and note it in the summary.

### Step 7: Summary

Present what was generated, including both infrastructure services and app service start commands:

```
## Dev Environment Generated

Files created:
  infra/docker-compose.dev.yml    — [N] infrastructure services configured
  .env.example                    — environment variables (app ports + infra)
  tools/dev/start.sh              — start infrastructure services
  tools/dev/stop.sh               — stop infrastructure services
  tools/dev/reset.sh              — reset to clean state

Infrastructure services:
  postgres    — localhost:5432 (user: postgres, db: myapp_dev)
  redis       — localhost:6379

App services (from Step 3.5):
  API server  — http://localhost:{API_PORT}  → {start_command}
  Web frontend— http://localhost:{WEB_PORT}  → {start_command}
  (list each detected service with its port and start command)

Quick start:
  cp .env.example .env            # create your local env file
  bash tools/dev/start.sh         # start infrastructure
  {start_command}                 # start your app
```

## Subcommand: reset

When invoked as `/dev-environment reset`:

1. Check if `infra/docker-compose.dev.yml` exists
2. If yes: run `docker compose -f infra/docker-compose.dev.yml down -v && docker compose -f infra/docker-compose.dev.yml up -d`
3. If no: advise the user to run `/dev-environment` first to generate the files

## Rules

- **Basics only** — generate only the services declared in config. No monitoring, tracing, or observability services unless the user explicitly requests them
- **Shell scripts only** — no Makefiles
- **Never overwrite** existing docker-compose files — always offer to review/merge first
- **Respect VPS deployments** — some users deploy with docker-compose in production, not just local dev
- **SQLite exception** — if database is SQLite, skip the database service (SQLite is file-based, no container needed). Note this in the summary

## Quality Checklist

- [ ] company.config.yaml was read and tech_stack values extracted
- [ ] Existing docker-compose files were checked before generating
- [ ] Docker images are current (verified via Context7 or defaults used)
- [ ] All generated files follow the project's conventions
- [ ] Scripts are executable (chmod +x)
- [ ] .env.example covers all service connection variables
- [ ] Summary shows connection strings for each service
