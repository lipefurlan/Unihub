"""Teto de visitas pagas: só as primeiras N visitas do aluno no mês geram repasse.

Rodar a partir de backend/:  python -m pytest tests
"""

from datetime import date, datetime, timedelta

from app.core.config import settings
from app.core.database import SessionLocal
from app.models import CheckIn, Gym, Student, Subscription
from app.services.checkin_service import create_checkin

from tests.test_auth import fresh_db  # noqa: F401 — mesmo banco e dados dos testes de auth


def _setup_subscriber(db):
    student = db.query(Student).filter_by(email="joao@dac.unicamp.br").one()
    db.add(Subscription(student_id=student.id, plan_id=1, start_date=date.today(),
                        renewal_date=date.today() + timedelta(days=30), amount=120, status="active"))
    db.commit()
    return student, db.query(Gym).one()


def test_visits_above_monthly_cap_have_no_payout():
    with SessionLocal() as db:
        student, gym = _setup_subscriber(db)
        month_start = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        # Visitas pagas já feitas no mês (fora da janela anti-fraude de 3h)
        for _ in range(settings.max_paid_checkins_per_month - 1):
            db.add(CheckIn(student_id=student.id, gym_id=gym.id, timestamp=month_start,
                           plan_tier_at_checkin=1, payout_amount_recorded=8, is_paid=True))
        db.commit()
        db.refresh(student)

        last_paid = create_checkin(db, student, gym.id)
        assert last_paid.is_paid and float(last_paid.payout_amount_recorded) == 8.0

        # Simula outra visita horas depois (fora da janela anti-fraude)
        last_paid.timestamp = datetime.now() - timedelta(hours=4)
        db.commit()

        unpaid = create_checkin(db, student, gym.id)
        assert not unpaid.is_paid
        assert float(unpaid.payout_amount_recorded) == 0.0
