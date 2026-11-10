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


def _plan(headers, **extra):
    res = client.post("/admin/plans", headers=headers, json={"name": "Plano Teste", "monthly_price": 90, **extra})
    assert res.status_code == 201, res.text
    return res.json()


def _gym_ids(headers):
    """Garante duas academias ativas e devolve os ids."""
    client.post("/admin/gyms", headers=headers, json={
        "name": "Iron Teste", "email": "iron@teste.com.br", "password": "academia123",
        "address": "Rua Teste, 1 - Campinas/SP", "latitude": -22.9, "longitude": -47.06,
        "modalities": ["musculação"], "min_plan_tier": 1, "checkin_payout_amount": 8,
        "capacity": 100, "opening_hours": "06:00–22:00",
    })
    return [g["id"] for g in client.get("/admin/gyms", headers=headers).json()]


def _student_on(plan_id, email):
    token = client.post("/auth/register/student", json={
        "name": "Aluno", "email": email, "password": "senha123"}).json()["access_token"]
    h = {"Authorization": f"Bearer {token}"}
    assert client.post("/subscriptions", json={"plan_id": plan_id}, headers=h).status_code == 201
    return h


def test_plan_with_chosen_gyms_only_covers_those_gyms():
    headers = _admin()
    gym_ids = _gym_ids(headers)
    assert len(gym_ids) == 2
    other = gym_ids[1]
    plan = _plan(headers, all_gyms=False, gym_ids=[gym_ids[0], 99999])
    assert plan["gym_ids"] == [gym_ids[0]]  # id inexistente é descartado

    h = _student_on(plan["id"], "lista@facamp.edu.br")
    assert client.post("/checkins", json={"gym_id": gym_ids[0]}, headers=h).status_code == 201
    res = client.post("/checkins", json={"gym_id": other}, headers=h)
    assert res.status_code == 403 and "não está incluída" in res.json()["detail"]


def test_plan_daily_and_monthly_limits_and_hours():
    headers = _admin()
    gym_ids = _gym_ids(headers)
    plan = _plan(headers, max_checkins_per_day=1, restrictions_note="Só um treino por dia")
    assert plan["restrictions_note"] == "Só um treino por dia"
    h = _student_on(plan["id"], "limite@facamp.edu.br")
    assert client.post("/checkins", json={"gym_id": gym_ids[0]}, headers=h).status_code == 201
    res = client.post("/checkins", json={"gym_id": gym_ids[1]}, headers=h)
    assert res.status_code == 403 and "por dia" in res.json()["detail"]

    # Janela de horário que nunca inclui agora: fecha o check-in
    from datetime import datetime, timedelta
    now = datetime.now()
    start = (now + timedelta(hours=1)).strftime("%H:%M")
    end = (now + timedelta(hours=2)).strftime("%H:%M")
    res = client.put(f"/admin/plans/{plan['id']}", headers=headers,
                     json={"max_checkins_per_day": None, "allowed_from": start, "allowed_until": end})
    assert res.status_code == 200 and res.json()["max_checkins_per_day"] is None
    h2 = _student_on(plan["id"], "horario@facamp.edu.br")
    res = client.post("/checkins", json={"gym_id": gym_ids[0]}, headers=h2)
    assert res.status_code == 403 and "vale das" in res.json()["detail"]
