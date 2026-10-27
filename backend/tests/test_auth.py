"""Testes de autenticação: login com Google, "esqueci minha senha" e cadastro
restrito às IES conveniadas.

Rodar a partir de backend/:  python -m pytest tests
"""

import os
import re
import tempfile

# Banco SQLite descartável, definido antes de importar o app
_db_file = os.path.join(tempfile.mkdtemp(), "test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{_db_file}"
os.environ["RESEND_API_KEY"] = ""
os.environ["GOOGLE_CLIENT_ID"] = "test-client-id"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.core.database import Base, SessionLocal, engine  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.core.rate_limit import limiter  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Gym, Plan, Student, University  # noqa: E402
from app.routers import auth as auth_router  # noqa: E402
from app.services import password_reset_service  # noqa: E402

limiter.enabled = False
client = TestClient(app)


@pytest.fixture(autouse=True)
def fresh_db():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        db.add(University(name="FACAMP", email_domains=["facamp.edu.br"], monthly_fee=3000,
                          fee_per_student=15, subsidy_per_student=10))
        db.add(University(name="Unicamp", email_domains=["unicamp.br"], monthly_fee=3000,
                          fee_per_student=15, subsidy_per_student=10))
        db.add(Plan(name="Plano UniHub", monthly_price=130, tier=1, color="#FF5A1F",
                    included_categories=["musculação"], benefits_description=""))
        db.add(Student(name="João", email="joao@dac.unicamp.br", password_hash=hash_password("senha123"),
                       university="Unicamp", university_id=2))
        db.add(Gym(name="Campus Fit", email="contato@campusfit.com.br", password_hash=hash_password("academia123"),
                   address="Rua X", latitude=0, longitude=0, checkin_payout_amount=8))
        db.commit()
    yield


@pytest.fixture
def sent_emails(monkeypatch):
    sent = []
    monkeypatch.setattr(password_reset_service, "send_email", lambda **kw: sent.append(kw))
    return sent


def _token_from(email: dict) -> str:
    return re.search(r"token=([\w-]+)", email["html"]).group(1)


def _fake_google(monkeypatch, email, name="Fulano"):
    monkeypatch.setattr(
        auth_router, "verify_google_credential",
        lambda credential: {"email": email, "email_verified": True, "name": name},
    )


def test_forgot_and_reset_password(sent_emails):
    res = client.post("/auth/forgot-password", json={"email": "joao@dac.unicamp.br"})
    assert res.status_code == 200
    assert len(sent_emails) == 1
    assert "/redefinir-senha?token=" in sent_emails[0]["html"]

    token = _token_from(sent_emails[0])
    res = client.post("/auth/reset-password", json={"token": token, "new_password": "novasenha"})
    assert res.status_code == 200

    assert client.post("/auth/login", json={"email": "joao@dac.unicamp.br", "password": "senha123"}).status_code == 401
    assert client.post("/auth/login", json={"email": "joao@dac.unicamp.br", "password": "novasenha"}).status_code == 200

    # O link só vale uma vez
    res = client.post("/auth/reset-password", json={"token": token, "new_password": "outrasenha"})
    assert res.status_code == 400


def test_forgot_password_unknown_email_same_answer(sent_emails):
    res = client.post("/auth/forgot-password", json={"email": "ninguem@exemplo.com"})
    assert res.status_code == 200
    assert sent_emails == []


def test_gym_reset_link_points_to_panel(sent_emails):
    client.post("/auth/forgot-password", json={"email": "contato@campusfit.com.br"})
    assert "localhost:5001/#/redefinir-senha" in sent_emails[0]["html"]


def test_google_login_existing_account(monkeypatch):
    _fake_google(monkeypatch, "joao@dac.unicamp.br")
    res = client.post("/auth/google", json={"credential": "fake-credential"})
    assert res.status_code == 200
    assert res.json()["role"] == "student"


def test_google_new_student_from_partner_university(monkeypatch):
    _fake_google(monkeypatch, "nova@facamp.edu.br", name="Nova Aluna")
    res = client.post("/auth/google", json={"credential": "fake-credential"})
    assert res.status_code == 200
    with SessionLocal() as db:
        student = db.query(Student).filter_by(email="nova@facamp.edu.br").one()
        assert student.name == "Nova Aluna"
        assert student.university == "FACAMP"


def test_google_panel_does_not_create_accounts(monkeypatch):
    _fake_google(monkeypatch, "nova@facamp.edu.br")
    res = client.post("/auth/google", json={"credential": "fake-credential", "allow_signup": False})
    assert res.status_code == 404


def test_google_rejects_non_partner_email(monkeypatch):
    _fake_google(monkeypatch, "alguem@gmail.com")
    res = client.post("/auth/google", json={"credential": "fake-credential"})
    assert res.status_code == 403


def test_google_invalid_credential():
    res = client.post("/auth/google", json={"credential": "nao-e-um-token-valido"})
    assert res.status_code == 401


def test_register_requires_partner_university_email():
    res = client.post("/auth/register/student", json={
        "name": "Alguém", "email": "alguem@gmail.com", "password": "senha123"})
    assert res.status_code == 403

    res = client.post("/auth/register/student", json={
        "name": "Aluna FACAMP", "email": "aluna@facamp.edu.br", "password": "senha123"})
    assert res.status_code == 201
    with SessionLocal() as db:
        assert db.query(Student).filter_by(email="aluna@facamp.edu.br").one().university == "FACAMP"


def test_subscription_price_includes_university_subsidy():
    token = client.post("/auth/register/student", json={
        "name": "Aluna", "email": "aluna@facamp.edu.br", "password": "senha123"}).json()["access_token"]
    res = client.post("/subscriptions", json={"plan_id": 1}, headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 201
    assert res.json()["amount"] == 120.0  # R$ 130 do plano - R$ 10 de subsídio
