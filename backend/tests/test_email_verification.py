"""Cadastro com e-mail pessoal + institucional, códigos por e-mail e lista
de alunos da IES importada por CSV.

Rodar a partir de backend/:  python -m pytest tests
"""

import re

import pytest

from app.core.config import settings
from app.models import EmailVerificationCode, Student
from app.services import verification_service
from tests.test_auth import SessionLocal, client, fresh_db  # noqa: F401
from tests.test_challenges import _admin


@pytest.fixture(autouse=True)
def require_verification(monkeypatch):
    monkeypatch.setattr(settings, "email_verification_required", True)


@pytest.fixture
def outbox(monkeypatch):
    sent = []
    monkeypatch.setattr(verification_service, "send_email", lambda **kw: sent.append(kw))
    return sent


def _code_for(outbox, email):
    msg = [m for m in outbox if m["to"] == email][-1]
    return re.search(r">(\d{6})<", msg["html"]).group(1)


def _register(**extra):
    payload = {"name": "Bia", "email": "bia@gmail.com", "institutional_email": "bia@facamp.edu.br",
               "password": "senha123"}
    payload.update(extra)
    return client.post("/auth/register/student", json=payload)


def _auth(res):
    return {"Authorization": f"Bearer {res.json()['access_token']}"}


def test_register_sends_code_to_both_emails_and_blocks_subscription(outbox):
    res = _register()
    assert res.status_code == 201
    h = _auth(res)
    assert sorted(m["to"] for m in outbox) == ["bia@facamp.edu.br", "bia@gmail.com"]

    profile = client.get("/students/me", headers=h).json()
    assert profile["email"] == "bia@gmail.com"
    assert profile["institutional_email"] == "bia@facamp.edu.br"
    assert profile["university"] == "FACAMP"
    assert not profile["email_verified"] and not profile["institutional_email_verified"]

    assert client.post("/subscriptions", json={"plan_id": 1}, headers=h).status_code == 403

    res = client.post("/students/me/verification/confirm", headers=h,
                      json={"kind": "personal", "code": _code_for(outbox, "bia@gmail.com")})
    assert res.status_code == 200 and res.json()["email_verified"]
    assert client.post("/subscriptions", json={"plan_id": 1}, headers=h).status_code == 403

    res = client.post("/students/me/verification/confirm", headers=h,
                      json={"kind": "institutional", "code": _code_for(outbox, "bia@facamp.edu.br")})
    assert res.json()["institutional_email_verified"]
    assert client.post("/subscriptions", json={"plan_id": 1}, headers=h).status_code == 201


def test_login_with_either_email():
    _register()
    for email in ("bia@gmail.com", "bia@facamp.edu.br"):
        assert client.post("/auth/login", json={"email": email, "password": "senha123"}).status_code == 200


def test_institutional_email_must_be_partner_domain():
    res = _register(institutional_email="bia@outrafacul.br")
    assert res.status_code == 403


def test_duplicate_emails_are_rejected():
    _register()
    assert _register(email="outra@gmail.com").status_code == 409  # mesmo institucional
    assert _register(institutional_email="outra@facamp.edu.br").status_code == 409  # mesmo pessoal


def test_wrong_code_counts_attempts_and_locks(outbox):
    h = _auth(_register())
    right = _code_for(outbox, "bia@gmail.com")
    wrong = "000000" if right != "000000" else "111111"
    for _ in range(settings.verification_code_max_attempts):
        res = client.post("/students/me/verification/confirm", headers=h, json={"kind": "personal", "code": wrong})
        assert res.status_code == 400
    res = client.post("/students/me/verification/confirm", headers=h, json={"kind": "personal", "code": right})
    assert res.status_code == 400
    assert "novo código" in res.json()["detail"]


def test_resend_has_cooldown_and_replaces_code(outbox):
    h = _auth(_register())
    old = _code_for(outbox, "bia@gmail.com")
    assert client.post("/students/me/verification/send", headers=h, json={"kind": "personal"}).status_code == 429

    with SessionLocal() as db:  # simula que já passou 1 minuto
        for c in db.query(EmailVerificationCode).all():
            c.created_at = c.created_at.replace(year=2020)
        db.commit()
    assert client.post("/students/me/verification/send", headers=h, json={"kind": "personal"}).status_code == 200
    new = _code_for(outbox, "bia@gmail.com")
    if new != old:
        res = client.post("/students/me/verification/confirm", headers=h, json={"kind": "personal", "code": old})
        assert res.status_code == 400
    res = client.post("/students/me/verification/confirm", headers=h, json={"kind": "personal", "code": new})
    assert res.status_code == 200


def test_old_clients_single_email_needs_one_code(outbox):
    res = client.post("/auth/register/student", json={
        "name": "Caio", "email": "caio@facamp.edu.br", "password": "senha123"})
    h = _auth(res)
    assert [m["to"] for m in outbox] == ["caio@facamp.edu.br"]
    res = client.post("/students/me/verification/confirm", headers=h,
                      json={"kind": "personal", "code": _code_for(outbox, "caio@facamp.edu.br")})
    assert res.json()["email_verified"] and res.json()["institutional_email_verified"]


def test_google_signup_is_verified_and_can_add_personal_email(monkeypatch, outbox):
    from tests.test_auth import _fake_google
    _fake_google(monkeypatch, "gui@facamp.edu.br", name="Gui")
    h = _auth(client.post("/auth/google", json={"credential": "fake-credential"}))
    profile = client.get("/students/me", headers=h).json()
    assert profile["email_verified"] and profile["institutional_email_verified"]

    res = client.put("/students/me/personal-email", headers=h, json={"email": "gui@gmail.com"})
    assert res.status_code == 200 and not res.json()["email_verified"]
    client.post("/students/me/verification/confirm", headers=h,
                json={"kind": "personal", "code": _code_for(outbox, "gui@gmail.com")})
    assert client.get("/students/me", headers=h).json()["email"] == "gui@gmail.com"


# --- Lista de alunos da IES (CSV) ---

CSV = (
    "nome;email;ra\n"
    "Bia Souza;BIA@facamp.edu.br;2024001\n"
    "Caio Lima;caio@facamp.edu.br;2024002\n"
    "Repetido;bia@facamp.edu.br;2024001\n"
    "Fora;fora@gmail.com;9\n"
    "Sem email;;10\n"
).encode("utf-8")


def _import(headers, content=CSV, mode="replace", university_id=1):
    return client.post(f"/admin/universities/{university_id}/roster?mode={mode}", headers=headers,
                       files={"file": ("alunos.csv", content, "text/csv")})


def test_roster_import_summary_and_listing():
    admin = _admin()
    res = _import(admin)
    assert res.status_code == 200
    body = res.json()
    assert (body["total_rows"], body["imported"], body["duplicates"], body["wrong_domain"], body["invalid"]) == (5, 2, 1, 1, 1)
    assert body["roster_size"] == 2

    rows = client.get("/admin/universities", headers=admin).json()
    facamp = next(r for r in rows if r["name"] == "FACAMP")
    assert facamp["roster_size"] == 2

    entries = client.get("/admin/universities/1/roster?q=2024002", headers=admin).json()
    assert entries == [{"email": "caio@facamp.edu.br", "name": "Caio Lima", "ra": "2024002", "registered": False}]


def test_roster_without_header_and_append():
    admin = _admin()
    _import(admin, b"bia@facamp.edu.br\n")
    res = _import(admin, b"caio@facamp.edu.br,Caio\n", mode="append")
    assert res.json()["roster_size"] == 2
    res = _import(admin, b"email\nnovo@facamp.edu.br\n")
    assert res.json()["roster_size"] == 1  # replace troca a lista inteira


def test_registration_requires_roster_when_list_exists(outbox):
    admin = _admin()
    _import(admin)
    assert _register(institutional_email="ze@facamp.edu.br").status_code == 403
    assert _register().status_code == 201  # bia está na lista

    # Faculdade sem lista (Unicamp): continua valendo só o domínio
    res = _register(email="ana@gmail.com", institutional_email="ana@dac.unicamp.br")
    assert res.status_code == 201

    rows = client.get("/admin/universities", headers=admin).json()
    facamp = next(r for r in rows if r["name"] == "FACAMP")
    assert (facamp["students"], facamp["students_in_roster"]) == (1, 1)


def test_clear_roster_goes_back_to_domain_only():
    admin = _admin()
    _import(admin)
    res = client.delete("/admin/universities/1/roster", headers=admin)
    assert res.json()["roster_size"] == 0
    assert _register(institutional_email="ze@facamp.edu.br").status_code == 201


def test_roster_requires_admin():
    h = _auth(_register())
    assert _import(h).status_code == 403


def test_default_flow_single_institutional_email_and_phone(outbox):
    res = client.post("/auth/register/student", json={
        "name": "Duda", "email": "duda@facamp.edu.br", "phone": "(19) 99999-0000", "password": "senha123"})
    assert res.status_code == 201
    h = _auth(res)
    assert [m["to"] for m in outbox] == ["duda@facamp.edu.br"]
    profile = client.get("/students/me", headers=h).json()
    assert profile["phone"] == "5519999990000"
    assert client.post("/subscriptions", json={"plan_id": 1}, headers=h).status_code == 403
    client.post("/students/me/verification/confirm", headers=h,
                json={"kind": "institutional", "code": _code_for(outbox, "duda@facamp.edu.br")})
    assert client.post("/subscriptions", json={"plan_id": 1}, headers=h).status_code == 201


def test_invalid_phone_is_rejected():
    res = client.post("/auth/register/student", json={
        "name": "Duda", "email": "duda@facamp.edu.br", "phone": "123", "password": "senha123"})
    assert res.status_code == 422
