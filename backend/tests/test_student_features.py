"""Meta semanal, favoritas, cidade, horário vazio, pausa e código de entrada.

Rodar a partir de backend/:  python -m pytest tests
"""

from datetime import date, datetime, timedelta

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models import CheckIn, Gym, Student

from tests.test_auth import client, fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth


def _student_headers():
    token = client.post("/auth/login", json={"email": "joao@dac.unicamp.br", "password": "senha123"}).json()
    return {"Authorization": f"Bearer {token['access_token']}"}


def _gym_headers():
    token = client.post("/auth/login", json={"email": "contato@campusfit.com.br", "password": "academia123"}).json()
    return {"Authorization": f"Bearer {token['access_token']}"}


def _subscribe(headers):
    res = client.post("/subscriptions", json={"plan_id": 1}, headers=headers)
    assert res.status_code == 201, res.text
    return res.json()


def _add_checkins(days_ago_list, hour=10):
    with SessionLocal() as db:
        student = db.query(Student).filter_by(email="joao@dac.unicamp.br").one()
        gym = db.query(Gym).first()
        for days_ago in days_ago_list:
            moment = datetime.combine(date.today() - timedelta(days=days_ago), datetime.min.time())
            db.add(CheckIn(student_id=student.id, gym_id=gym.id, timestamp=moment.replace(hour=hour),
                           plan_tier_at_checkin=1, payout_amount_recorded=8, is_paid=True))
        db.commit()


def test_weekly_goal_and_streak():
    headers = _student_headers()
    res = client.put("/students/me", json={"weekly_goal": 2}, headers=headers)
    assert res.json()["weekly_goal"] == 2

    monday = date.today() - timedelta(days=date.today().weekday())
    days_since_monday = (date.today() - monday).days
    # Duas semanas anteriores com 2 treinos cada; a semana atual sem treino
    _add_checkins([days_since_monday + 1, days_since_monday + 2, days_since_monday + 8, days_since_monday + 9])

    stats = client.get("/students/me/stats", headers=headers).json()
    assert stats["weekly_goal"] == 2
    assert stats["week_checkins"] == 0
    assert stats["streak_weeks"] == 2
    assert len(stats["last_weeks"]) == 8
    assert stats["last_weeks"][-2]["goal_met"] is True


def test_home_city_and_city_filter():
    with SessionLocal() as db:
        db.add(Gym(name="Fit Santos", email="santos@fit.com.br", password_hash=hash_password("x"),
                   address="Av. Ana Costa, 100 - Gonzaga, Santos/SP", latitude=0, longitude=0,
                   checkin_payout_amount=8))
        db.commit()
    headers = _student_headers()
    res = client.put("/students/me", json={"home_city": "Santos"}, headers=headers)
    assert res.json()["home_city"] == "Santos"

    assert "Santos" in client.get("/gyms/cities").json()
    gyms = client.get("/gyms", params={"city": "santos"}).json()
    assert [g["name"] for g in gyms] == ["Fit Santos"]
    assert gyms[0]["city"] == "Santos"


def test_favorites():
    headers = _student_headers()
    gym_id = client.get("/gyms").json()[0]["id"]
    assert client.put(f"/students/me/favorites/{gym_id}", headers=headers).status_code == 204
    # Favoritar de novo não duplica
    client.put(f"/students/me/favorites/{gym_id}", headers=headers)
    assert [g["id"] for g in client.get("/students/me/favorites", headers=headers).json()] == [gym_id]
    client.delete(f"/students/me/favorites/{gym_id}", headers=headers)
    assert client.get("/students/me/favorites", headers=headers).json() == []


def test_busy_hours_finds_quietest_window():
    _add_checkins([1, 2, 3], hour=18)
    _add_checkins([1], hour=7)
    gym_id = client.get("/gyms").json()[0]["id"]
    busy = client.get(f"/gyms/{gym_id}/busy-hours").json()
    assert {h["hour"]: h["checkins"] for h in busy["hours"]}[18] == 3
    # 6h-8h tem 1 visita; 8h-10h tem zero e é a primeira faixa vazia
    assert (busy["quietest_start"], busy["quietest_end"]) == (8, 10)


def test_paused_plan_blocks_checkin_until_resumed():
    headers = _student_headers()
    sub = _subscribe(headers)
    gym_id = client.get("/gyms").json()[0]["id"]

    client.put(f"/subscriptions/{sub['id']}", json={"status": "paused"}, headers=headers)
    res = client.post("/checkins", json={"gym_id": gym_id}, headers=headers)
    assert res.status_code == 403
    assert "pausado" in res.json()["detail"]

    client.put(f"/subscriptions/{sub['id']}", json={"status": "active"}, headers=headers)
    assert client.post("/checkins", json={"gym_id": gym_id}, headers=headers).status_code == 201


def test_reception_validates_entry_code():
    headers = _student_headers()
    _subscribe(headers)
    gym_id = client.get("/gyms").json()[0]["id"]
    checkin = client.post("/checkins", json={"gym_id": gym_id}, headers=headers).json()
    code = checkin["entry_code"]
    assert len(code) == 6

    gym_headers = _gym_headers()
    res = client.post("/gyms/me/checkins/validate", json={"code": code.lower()}, headers=gym_headers)
    assert res.status_code == 200, res.text
    assert res.json()["student_name"] == "João"
    assert res.json()["already_validated"] is False

    again = client.post("/gyms/me/checkins/validate", json={"code": code}, headers=gym_headers).json()
    assert again["already_validated"] is True

    assert client.post("/gyms/me/checkins/validate", json={"code": "ZZZZZZ"},
                       headers=gym_headers).status_code == 404


def test_entry_code_only_valid_at_its_gym():
    headers = _student_headers()
    _subscribe(headers)
    gym_id = client.get("/gyms").json()[0]["id"]
    code = client.post("/checkins", json={"gym_id": gym_id}, headers=headers).json()["entry_code"]
    with SessionLocal() as db:
        db.add(Gym(name="Outra", email="outra@fit.com.br", password_hash=hash_password("outra123"),
                   address="Rua Y", latitude=0, longitude=0, checkin_payout_amount=8))
        db.commit()
    other = client.post("/auth/login", json={"email": "outra@fit.com.br", "password": "outra123"}).json()
    res = client.post("/gyms/me/checkins/validate", json={"code": code},
                      headers={"Authorization": f"Bearer {other['access_token']}"})
    assert res.status_code == 404
