"""Portal da IES e senha temporária gerada pelo admin.

Rodar a partir de backend/:  python -m pytest tests
"""

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models import Admin, University

from tests.test_auth import client, fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth


def _login(email, password):
    res = client.post("/auth/login", json={"email": email, "password": password})
    assert res.status_code == 200, res.text
    return res.json(), {"Authorization": f"Bearer {res.json()['access_token']}"}


def _enable_facamp_portal():
    with SessionLocal() as db:
        facamp = db.query(University).filter_by(name="FACAMP").one()
        facamp.email = "programa@facamp.edu.br"
        facamp.password_hash = hash_password("facamp123")
        db.commit()


def test_university_logs_in_and_sees_invoice():
    _enable_facamp_portal()
    token = client.post("/auth/register/student", json={
        "name": "Aluna", "email": "aluna@facamp.edu.br", "password": "senha123"}).json()["access_token"]
    client.post("/subscriptions", json={"plan_id": 1}, headers={"Authorization": f"Bearer {token}"})

    body, headers = _login("programa@facamp.edu.br", "facamp123")
    assert body["role"] == "ies"

    overview = client.get("/ies/me/overview", headers=headers).json()
    assert overview["registered_students"] == 1
    assert overview["subscribers"] == 1
    # R$ 3.000 fixos + R$ 15 de taxa + R$ 10 de subsídio por assinante
    assert overview["invoice"]["total"] == 3025.0

    students = client.get("/ies/me/students", headers=headers).json()
    assert [s["email"] for s in students] == ["aluna@facamp.edu.br"]


def test_university_cannot_see_other_universities_students():
    _enable_facamp_portal()
    _, headers = _login("programa@facamp.edu.br", "facamp123")
    students = client.get("/ies/me/students", headers=headers).json()
    assert all(s["email"].endswith("@facamp.edu.br") for s in students)


def test_student_token_cannot_open_university_portal():
    _, headers = _login("joao@dac.unicamp.br", "senha123")
    assert client.get("/ies/me/overview", headers=headers).status_code == 403


def test_admin_generates_temporary_password():
    with SessionLocal() as db:
        db.add(Admin(name="Op", email="admin@unihub.com.br", password_hash=hash_password("admin123")))
        db.commit()
    _, headers = _login("admin@unihub.com.br", "admin123")

    res = client.post("/admin/students/1/temporary-password", headers=headers)
    assert res.status_code == 200
    temporary = res.json()["temporary_password"]
    assert len(temporary) == 8

    assert client.post("/auth/login", json={"email": "joao@dac.unicamp.br", "password": "senha123"}).status_code == 401
    _login("joao@dac.unicamp.br", temporary)
