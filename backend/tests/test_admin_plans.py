"""Gestão de planos pela operação UniHub.

Rodar a partir de backend/:  python -m pytest tests
"""

from tests.test_auth import client, fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth
from tests.test_challenges import _admin, _subscriber


def test_admin_creates_edits_and_deactivates_plan():
    headers = _admin()
    _subscriber("aluno1@facamp.edu.br")

    plans = client.get("/admin/plans", headers=headers).json()
    assert plans[0]["active_subscribers"] == 1

    res = client.post("/admin/plans", headers=headers, json={
        "name": "Plano Atleta", "monthly_price": 160, "benefits_description": "Inclui assessoria",
        "included_categories": [" Corrida ", "crossfit"], "has_running_coach": True,
    })
    assert res.status_code == 201, res.text
    novo = res.json()
    assert novo["tier"] == max(p["tier"] for p in plans) + 1
    assert novo["included_categories"] == ["corrida", "crossfit"]
    assert any(p["id"] == novo["id"] for p in client.get("/plans").json())

    res = client.put(f"/admin/plans/{novo['id']}", headers=headers,
                     json={"monthly_price": 150, "is_active": False})
    assert res.status_code == 200
    assert res.json()["monthly_price"] == 150 and res.json()["is_active"] is False

    # Desativado some da vitrine e não aceita assinatura nova
    assert all(p["id"] != novo["id"] for p in client.get("/plans").json())
    token = client.post("/auth/register/student", json={
        "name": "Aluno 2", "email": "aluno2@facamp.edu.br", "password": "senha123"}).json()["access_token"]
    res = client.post("/subscriptions", json={"plan_id": novo["id"]},
                      headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 404


def test_plans_admin_requires_admin():
    token = client.post("/auth/register/student", json={
        "name": "Aluno", "email": "aluno@facamp.edu.br", "password": "senha123"}).json()["access_token"]
    res = client.get("/admin/plans", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code in (401, 403)
