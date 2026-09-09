# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

CyberSaathi B2C — an AI-driven fraud recovery app. Stack: Flutter (frontend, not yet implemented — `frontend/` is a placeholder), FastAPI (`backend/`), PostgreSQL.

## Git & PR rules — follow exactly, no exceptions

- Never push directly to `main`, under any circumstance.
- Never raise a Pull Request without being explicitly told to.
- Always work on the branch the user specifies. If none is specified, ASK which branch before writing any code — never assume or create one unilaterally.
- Before pushing any commit, confirm with the user first: state exactly what will be pushed and to which branch, and wait for explicit go-ahead.
- Before raising a PR, confirm a SECOND time — even if the user already said to push. Pushing and raising a PR are separate actions, each needing its own confirmation. Never chain them automatically.
- If told "push to [branch]", push only — do not also raise a PR unless separately asked.
- If unsure whether an action is destructive (force-push, reset, deleting a branch), stop and ask before doing it.

## Current status

**Done:**
- Milestones 1–2: backend auth (`/signup`, `/login`, `/me`) and pytest suite, verified against a real Postgres instance.
- Milestones 3–4: backend Dockerized (`backend/Dockerfile`, `backend/docker-entrypoint.sh`, `backend/.dockerignore`), `docker-compose.yml` at the repo root (Postgres + backend, healthchecked, named volume, migrations run automatically on container start), and GitHub Actions CI (`.github/workflows/backend-ci.yml`, job `backend-tests`, runs against a real Postgres service container on every PR to `main`).

**Not yet done:**
- Flutter frontend (`frontend/` is still a placeholder).
- Branch protection on `main` requiring the `backend-tests` check — the user is setting this up manually.

## Commands

All commands run from `backend/`.

```bash
# setup
python -m venv .venv
.venv\Scripts\activate        # Windows
source .venv/bin/activate     # macOS/Linux
pip install -r requirements.txt
cp .env.example .env          # then fill in DATABASE_URL and JWT_SECRET

# migrations (requires DATABASE_URL + JWT_SECRET in the environment)
alembic upgrade head
alembic revision --autogenerate -m "description"

# run the API
uvicorn app.main:app --reload

# tests
pytest tests/ -v
pytest tests/test_auth.py::test_login_fails_with_wrong_password -v   # single test
```

From the repo root, to run the full stack (Postgres + backend) in Docker:

```bash
cp .env.example .env   # fill in POSTGRES_USER/PASSWORD/DB and JWT_SECRET
docker compose up --build
```

## Architecture

**Config is env-only and fails fast.** `app/config.py` instantiates a module-level `settings = Settings()` at import time, which reads `DATABASE_URL` and `JWT_SECRET` from the environment and raises `RuntimeError` immediately if either is missing — there are no hardcoded defaults or fallbacks. Because this happens at import time, anything that imports `app.database`, `app.security`, or `app.main` needs those env vars set *before* the import happens. This is why `backend/tests/conftest.py` sets `os.environ[...]` for `DATABASE_URL`/`JWT_SECRET` at the top of the file, before the `from app...` import lines — reordering those would break test collection.

**Request flow:** `app/main.py` registers two routers — `routers/auth.py` (`/signup`, `/login`) and `routers/users.py` (`/me`). Both depend on `app/database.py`'s `get_db()` for a SQLAlchemy session and `app/schemas.py` for request/response validation. Password hashing and JWT creation/decoding live in `app/security.py` (bcrypt + PyJWT directly — no passlib). `app/auth.py` defines `get_current_user`, an `HTTPBearer`-based dependency that decodes the JWT, looks up the user by the `sub` claim (the user's email), and raises 401 on any failure (missing/invalid/expired token or unknown user) — this is the only gate protecting `/me`.

**Tests run against an isolated SQLite database, never the real one.** `tests/conftest.py` points `DATABASE_URL` at a dedicated SQLite file in the OS temp dir, builds its own engine/sessionmaker, and overrides FastAPI's `get_db` dependency (`app.dependency_overrides[get_db] = ...`) so the app under test never touches whatever `DATABASE_URL` is configured for real use. An autouse fixture drops and recreates all tables before every test for isolation; a session-scoped fixture deletes the SQLite file afterward. Production is expected to run on Postgres (`psycopg2-binary` is the pinned driver); the SQLite substitution is test-only and works because the schema/queries don't use Postgres-specific features.

**Alembic mirrors the same settings module.** `alembic/env.py` imports `app.config.settings` and `app.database.Base`/`app.models` to get `target_metadata`, so autogenerate diffs against whatever models are defined in `app/models.py` — the same import-order constraint applies here (`DATABASE_URL`/`JWT_SECRET` must be set in the shell before invoking `alembic`).

**Docker and CI both defer to the same settings/migration path.** `backend/docker-entrypoint.sh` runs `alembic upgrade head` before starting uvicorn, so the container always has an up-to-date schema — this is the only place migrations run automatically. `docker-compose.yml` wires the backend's `DATABASE_URL` to the `db` service by container name (not `localhost`) and gates backend startup on `db`'s healthcheck. In CI (`.github/workflows/backend-ci.yml`), the `backend-tests` job spins up a Postgres *service container* (GitHub's native `services:` key, not docker-compose) and runs `alembic upgrade head` against it to prove migrations apply cleanly to real Postgres — but the `pytest` step right after that still uses the SQLite self-isolation described above (`conftest.py` overrides `DATABASE_URL` again inside the Python process), so the Postgres service in CI only exercises the migration path, not the test suite itself.

## Codex config detected

`~/.codex/config.toml` exists on this machine. If you'd like to import any importable items (MCP servers, slash commands, subagents, skills, instructions) from it into Claude Code, reply `/import` to scan it first.
