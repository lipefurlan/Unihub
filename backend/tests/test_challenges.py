"""Desafios entre faculdades e entre cursos, placar público e visão do aluno.

Rodar a partir de backend/:  python -m pytest tests
"""

from datetime import date, datetime, timedelta

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models import Admin, CheckIn, Gym, Student

from tests.test_auth import client, fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth
from tests.test_ies_portal import _enable_facamp_portal, _login


def _admin():
    with SessionLocal() as db:
        db.add(Admin(name="Op", email="admin@unihub.com.br", password_hash=hash_password("admin123")))
        db.commit()
    return _login("admin@unihub.com.br", "admin123")[1]


def _subscriber(email, course=None):
    payload = {"name": "Aluno", "email": email, "password": "senha123"}
    if course:
        payload["course"] = course
    res = client.post("/auth/register/student", json=payload)
    assert res.status_code == 201, res.text
    headers = {"Authorization": f"Bearer {res.json()['access_token']}"}
    client.post("/subscriptions", json={"plan_id": 1}, headers=headers)
    return headers


def _checkin(email, days_ago=0, hours=0):
    with SessionLocal() as db:
        student = db.query(Student).filter_by(email=email).one()
        gym = db.query(Gym).first()
        moment = datetime.now().replace(hour=10, minute=0) - timedelta(days=days_ago) + timedelta(hours=hours)
        db.add(CheckIn(student_id=student.id, gym_id=gym.id, timestamp=moment,
                       plan_tier_at_checkin=1, payout_amount_recorded=8, is_paid=True))
        db.commit()


def _period(days_back=3, days_ahead=10):
    return {
        "start_date": (date.today() - timedelta(days=days_back)).isoformat(),
        "end_date": (date.today() + timedelta(days=days_ahead)).isoformat(),
    }


def test_admin_creates_universities_challenge_ranked_per_subscriber():
    admin = _admin()
    joao = _login("joao@dac.unicamp.br", "senha123")[1]
    client.post("/subscriptions", json={"plan_id": 1}, headers=joao)
    _subscriber("a@facamp.edu.br")
    _subscriber("b@facamp.edu.br")
    _checkin("joao@dac.unicamp.br")
    _checkin("joao@dac.unicamp.br", hours=5)
    _checkin("a@facamp.edu.br")

    res = client.post("/admin/challenges", json={"title": "Qual faculdade treina mais?", **_period()},
                      headers=admin)
    assert res.status_code == 201, res.text
    body = res.json()
    assert body["status"] == "active"
    # Unicamp: 2 check-ins / 1 assinante; FACAMP: 1 / 2
    assert [(r["name"], r["score"]) for r in body["ranking"]] == [("Unicamp", 2.0), ("FACAMP", 0.5)]
    assert body["leader"] == "Unicamp"
    assert body["evolution"]["series"][0]["name"] == "Unicamp"

    listed = client.get("/admin/challenges", headers=admin).json()
    assert [c["id"] for c in listed] == [body["id"]]


def test_courses_challenge_scores_share_training_every_week():
    _enable_facamp_portal()
    ies = _login("programa@facamp.edu.br", "facamp123")[1]
    _subscriber("adm1@facamp.edu.br", "Administração")
    _subscriber("adm2@facamp.edu.br", "administração")  # mesmo curso, outra grafia
    _subscriber("dir1@facamp.edu.br", "Direito")
    _checkin("adm1@facamp.edu.br")
    _checkin("dir1@facamp.edu.br")

    # A IES tenta criar entre faculdades: vira entre cursos dela
    res = client.post("/ies/me/challenges", json={
        "title": "Copa de cursos", "scope": "universities", "metric": "active_share", **_period(days_back=2)},
        headers=ies)
    assert res.status_code == 201, res.text
    body = res.json()
    assert body["scope"] == "courses" and body["university_name"] == "FACAMP"
    assert [(r["name"], r["score"]) for r in body["ranking"]] == [("Direito", 100.0), ("Administração", 50.0)]


def test_invalid_course_is_rejected_on_signup():
    res = client.post("/auth/register/student", json={
        "name": "Aluno", "email": "x@facamp.edu.br", "password": "senha123", "course": "Astrologia"})
    assert res.status_code == 422


def test_university_only_sees_its_own_course_challenges():
    admin = _admin()
    with SessionLocal() as db:
        from app.models import University
        unicamp_id = db.query(University).filter_by(name="Unicamp").one().id
    other = client.post("/admin/challenges", json={
        "title": "Copa Unicamp", "scope": "courses", "university_id": unicamp_id, **_period()},
        headers=admin).json()
    general = client.post("/admin/challenges", json={"title": "Geral", **_period()}, headers=admin).json()

    _enable_facamp_portal()
    ies = _login("programa@facamp.edu.br", "facamp123")[1]
    assert [c["id"] for c in client.get("/ies/me/challenges", headers=ies).json()] == [general["id"]]
    assert client.get(f"/ies/me/challenges/{other['id']}", headers=ies).status_code == 404
    assert client.delete(f"/ies/me/challenges/{general['id']}", headers=ies).status_code == 403


def test_courses_challenge_needs_university_and_valid_dates():
    admin = _admin()
    assert client.post("/admin/challenges", json={"title": "Sem IES", "scope": "courses", **_period()},
                       headers=admin).status_code == 422
    bad = {"start_date": date.today().isoformat(), "end_date": (date.today() - timedelta(days=1)).isoformat()}
    assert client.post("/admin/challenges", json={"title": "Datas", **bad}, headers=admin).status_code == 422


def test_public_scoreboard_opens_without_login():
    admin = _admin()
    created = client.post("/admin/challenges", json={"title": "Placar", **_period()}, headers=admin).json()
    res = client.get(f"/public/scoreboard/{created['public_token']}")
    assert res.status_code == 200
    assert res.json()["title"] == "Placar"
    assert "public_token" not in res.json()
    assert client.get("/public/scoreboard/nao-existe").status_code == 404


def test_student_sees_active_challenges_with_own_contribution():
    admin = _admin()
    _enable_facamp_portal()
    ies = _login("programa@facamp.edu.br", "facamp123")[1]
    aluna = _subscriber("eco@facamp.edu.br", "Economia")
    _checkin("eco@facamp.edu.br")
    _checkin("eco@facamp.edu.br", days_ago=1)
    client.post("/admin/challenges", json={"title": "Geral", **_period()}, headers=admin)
    client.post("/ies/me/challenges", json={"title": "Copa", **_period()}, headers=ies)
    # Encerrado não aparece para o aluno
    client.post("/admin/challenges", json={"title": "Antigo", **_period(days_back=40, days_ahead=-20)},
                headers=admin)

    mine = client.get("/students/me/challenges", headers=aluna).json()
    assert {c["title"]: (c["my_group"], c["my_checkins"]) for c in mine} == {
        "Geral": ("FACAMP", 2),
        "Copa": ("Economia", 2),
    }

    profile = client.put("/students/me", json={"course": "Direito"}, headers=aluna).json()
    assert profile["course"] == "Direito"
