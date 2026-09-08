import os


class Settings:
    """Application settings, read exclusively from environment variables."""

    def __init__(self) -> None:
        database_url = os.environ.get("DATABASE_URL")
        jwt_secret = os.environ.get("JWT_SECRET")

        if not database_url:
            raise RuntimeError("DATABASE_URL environment variable is not set")
        if not jwt_secret:
            raise RuntimeError("JWT_SECRET environment variable is not set")

        self.database_url: str = database_url
        self.jwt_secret: str = jwt_secret
        self.jwt_algorithm: str = os.environ.get("JWT_ALGORITHM", "HS256")
        self.access_token_expire_minutes: int = int(
            os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
        )


settings = Settings()
