from fastapi import FastAPI

from app.routers import auth, users

app = FastAPI(title="CyberSaathi B2C API")

app.include_router(auth.router, tags=["auth"])
app.include_router(users.router, tags=["users"])


@app.get("/health")
def health_check():
    return {"status": "ok"}
