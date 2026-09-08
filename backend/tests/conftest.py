import os
import tempfile
from pathlib import Path

import pytest

# Test environment variables must be set before any `app.*` module is
# imported, since app.config.Settings() reads them at import time.
TEST_DB_FILE = Path(tempfile.gettempdir()) / "cybersaathi_test.db"

os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_FILE.as_posix()}"
os.environ["JWT_SECRET"] = "test-secret-key-used-for-pytest-only"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "30"

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402

from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402

engine = create_engine(
    os.environ["DATABASE_URL"], connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def _override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(autouse=True)
def _fresh_database():
    """Give every test a clean, isolated schema in the dedicated test database."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="session", autouse=True)
def _cleanup_test_db_file():
    yield
    engine.dispose()
    if TEST_DB_FILE.exists():
        TEST_DB_FILE.unlink()


@pytest.fixture
def client():
    return TestClient(app)
