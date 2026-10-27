"""Avaliação da visita, conquistas, academias em alta e desafio entre faculdades.

Rodar a partir de backend/:  python -m pytest tests
"""

from datetime import date, datetime, timedelta

from app.core.database import SessionLocal
from app.models import CheckIn, Gym, Student

from tests.test_auth import client, fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth


def _headers(email="joao@dac.unicamp.br", password="senha123"):
    token = client.post("/auth/login", json={"email": email, "password": password}).json()
    return {"Authorization": f"Bearer {token['access_token']}"}


def _checkin_at(moment, email="joao@dac.unicamp.br"):
    with SessionLocal() as db:
        student = db.query(Student).filter_by(email=email).one()
        gym = db.query(Gym).first()
        checkin = CheckIn(student_id=student.id, gym_id=gym.id, timestamp=moment,
                          plan_tier_at_checkin=1, payout_amount_recorded=8, is_paid=True)
        db.add(checkin)
        db.commit()
        return checkin.id


def test_student_rates_visit_and_gym_shows_average():
    headers = _headers()
    first = _checkin_at(datetime.now() - timedelta(days=2))
    second = _checkin_at(datetime.now() - timedelta(days=1))

    res = client.put(f"/checkins/{first}/rating", json={"stars": 5}, headers=headers)
    assert res.status_code == 200, res.text
    assert res.json()["rating"] == 5
    client.put(f"/checkins/{second}/rating", json={"stars": 4}, headers=headers)

    gym = client.get("/gyms").json()[0]
    assert (gym["rating_avg"], gym["rating_count"]) == (4.5, 2)
    history = client.get("/students/me/checkins", headers=headers).json()
    assert sorted(c["rating"] for c in history) == [4, 5]

    assert client.put(f"/checkins/{first}/rating", json={"stars": 6}, headers=headers).status_code == 422


def test_student_cannot_rate_someone_elses_visit():
    client.post("/auth/register/student", json={
        "name": "Outra", "email": "outra@facamp.edu.br", "password": "senha123"})
    joao_checkin = _checkin_at(datetime.now() - timedelta(days=1))
    res = client.put(f"/checkins/{joao_checkin}/rating", json={"stars": 1},
                     headers=_headers("outra@facamp.edu.br"))
    assert res.status_code == 404


def test_achievements_count_checkins_and_streak():
    headers = _headers()
    client.put("/students/me", json={"weekly_goal": 1}, headers=headers)
    monday = date.today() - timedelta(days=date.today().weekday())
    # Uma visita por semana nas 4 semanas anteriores, às 7h (madrugador)
    for week in range(1, 5):
        _checkin_at(datetime.combine(monday - timedelta(weeks=week), datetime.min.time()).replace(hour=7))

    body = client.get("/students/me/achievements", headers=headers).json()
    assert body["total_checkins"] == 4
    assert body["current_streak"] == 4
    badges = {b["code"]: b for b in body["badges"]}
    assert badges["first"]["achieved"] and badges["streak_4"]["achieved"]
    assert not badges["checkins_10"]["achieved"] and badges["checkins_10"]["progress"] == 4
    assert badges["early"]["progress"] == 4


def test_trending_gyms_rank_recent_visits():
    _checkin_at(datetime.now() - timedelta(days=1))
    _checkin_at(datetime.now() - timedelta(days=20))  # fora da janela de 7 dias
    trending = client.get("/gyms/trending").json()
    assert trending[0]["recent_checkins"] == 1
    assert trending[0]["gym"]["name"] == "Campus Fit"


def test_challenge_ranks_universities_by_visits_per_subscriber():
    joao = _headers()
    client.post("/subscriptions", json={"plan_id": 1}, headers=joao)
    token = client.post("/auth/register/student", json={
        "name": "Aluna", "email": "aluna@facamp.edu.br", "password": "senha123"}).json()["access_token"]
    aluna = {"Authorization": f"Bearer {token}"}
    client.post("/subscriptions", json={"plan_id": 1}, headers=aluna)

    month_day = datetime.now().replace(day=1, hour=10)
    _checkin_at(month_day)
    _checkin_at(month_day + timedelta(hours=5))
    _checkin_at(month_day, email="aluna@facamp.edu.br")

    body = client.get("/students/me/challenge", headers=joao).json()
    assert [r["university"] for r in body["ranking"]] == ["Unicamp", "FACAMP"]
    assert body["ranking"][0]["score"] == 2.0
    assert body["my_checkins"] == 2
    assert body["my_university_id"] == body["ranking"][0]["university_id"]
