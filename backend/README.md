# CyberSaathi B2C — Backend

FastAPI service providing signup, login, and authenticated user data, backed by
PostgreSQL via SQLAlchemy, with Alembic migrations and JWT authentication.

## Requirements

- Python 3.11+
- A running PostgreSQL instance

## 1. Install dependencies

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
```

## 2. Configure environment variables

Copy the example file and fill in real values:

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string, e.g. `postgresql+psycopg2://user:password@localhost:5432/cybersaathi` |
| `JWT_SECRET` | Secret key used to sign JWTs. Generate one with `python -c "import secrets; print(secrets.token_urlsafe(64))"` |
| `JWT_ALGORITHM` | Optional, defaults to `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Optional, defaults to `30` |

These are read exclusively from the environment — nothing is hardcoded.
`python-dotenv` is installed so a local `.env` file is picked up automatically
if you load it (e.g. `export $(cat .env | xargs)` on macOS/Linux, or use a tool
like `direnv`). On Windows PowerShell:

```powershell
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
    [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
  }
}
```

## 3. Run database migrations

Make sure `DATABASE_URL` is set (and the target Postgres database exists), then:

```bash
alembic upgrade head
```

## 4. Run the server

```bash
uvicorn app.main:app --reload
```

The API is now available at `http://127.0.0.1:8000`.

- `POST /signup` — create a user (`email`, `password`)
- `POST /login` — returns a JWT `access_token` on valid credentials
- `GET /me` — returns the current user; requires `Authorization: Bearer <token>`
- `GET /health` — basic health check

## Running the test suite

Tests do **not** touch your real database. They spin up a dedicated,
disposable SQLite database file for the duration of the run and tear it down
afterwards, regardless of `DATABASE_URL`.

```bash
pytest tests/ -v
```

## Continuous deployment (image publishing)

`.github/workflows/backend-cd.yml` runs on every push to `main` (i.e. after a
PR is merged). It builds the image from `backend/Dockerfile` and pushes it to
GitHub Container Registry (ghcr.io) under this repo's namespace, tagged with
both `latest` and the short commit SHA — no extra secrets required, it
authenticates with the built-in `GITHUB_TOKEN`.

This stops at "image is published." There is no deploy-to-a-live-server step
yet — no hosting provider has been chosen, so that's a separate, future
decision.

To manually pull and run the latest published image:

```bash
docker pull ghcr.io/ashritharooman/b2c_cybersathi-backend:latest
docker run --env-file .env -p 8000:8000 ghcr.io/ashritharooman/b2c_cybersathi-backend:latest
```

(`.env` here needs the same `DATABASE_URL` and `JWT_SECRET` as any other run
of the backend — see the environment variables table above. The image runs
`alembic upgrade head` automatically on startup, same as in `docker-compose.yml`.)

## Project layout

```
backend/
├── app/
│   ├── main.py         # FastAPI app + router registration
│   ├── config.py        # env-var driven settings
│   ├── database.py      # SQLAlchemy engine/session
│   ├── models.py         # ORM models
│   ├── schemas.py        # Pydantic request/response models
│   ├── security.py       # password hashing + JWT helpers
│   ├── auth.py           # get_current_user dependency
│   └── routers/
│       ├── auth.py       # /signup, /login
│       └── users.py      # /me
├── alembic/               # migrations
├── tests/                 # pytest suite
├── requirements.txt
└── .env.example
```
