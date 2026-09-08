from app.security import create_access_token

VALID_PASSWORD = "correct-horse-battery-staple"


def _signup(client, email="user@example.com", password=VALID_PASSWORD):
    return client.post("/signup", json={"email": email, "password": password})


def test_signup_succeeds_with_new_email(client):
    response = _signup(client, email="new-user@example.com")

    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "new-user@example.com"
    assert "id" in body
    assert "password" not in body
    assert "hashed_password" not in body


def test_signup_fails_with_duplicate_email(client):
    email = "duplicate@example.com"
    first = _signup(client, email=email)
    assert first.status_code == 201

    second = _signup(client, email=email)

    assert second.status_code == 400
    assert "already exists" in second.json()["detail"].lower()


def test_login_succeeds_with_correct_credentials_and_returns_valid_jwt(client):
    email = "login-success@example.com"
    _signup(client, email=email)

    response = client.post("/login", json={"email": email, "password": VALID_PASSWORD})

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert isinstance(body["access_token"], str) and body["access_token"]

    # The returned token must actually authenticate against a protected route.
    me_response = client.get(
        "/me", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == email


def test_login_fails_with_wrong_password(client):
    email = "login-fail@example.com"
    _signup(client, email=email)

    response = client.post("/login", json={"email": email, "password": "wrong-password"})

    assert response.status_code == 401


def test_me_fails_with_no_token(client):
    response = client.get("/me")

    assert response.status_code == 401


def test_me_fails_with_invalid_token(client):
    response = client.get(
        "/me", headers={"Authorization": "Bearer not-a-real-token"}
    )

    assert response.status_code == 401


def test_me_fails_with_expired_token(client):
    email = "expired-token@example.com"
    _signup(client, email=email)

    expired_token = create_access_token(subject=email, expires_minutes=-1)

    response = client.get(
        "/me", headers={"Authorization": f"Bearer {expired_token}"}
    )

    assert response.status_code == 401


def test_me_succeeds_with_valid_token_and_returns_correct_user(client):
    email = "me-success@example.com"
    signup_response = _signup(client, email=email)
    user_id = signup_response.json()["id"]

    login_response = client.post(
        "/login", json={"email": email, "password": VALID_PASSWORD}
    )
    token = login_response.json()["access_token"]

    response = client.get("/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == user_id
    assert body["email"] == email
