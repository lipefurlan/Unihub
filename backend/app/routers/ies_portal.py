from collections import Counter
from datetime import date, datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.security import get_current_university
from app.models import CheckIn, Student, University
from app.services import payout_service

router = APIRouter(prefix="/ies/me", tags=["Portal da IES"])


class UniversityMeOut(BaseModel):
    id: int
    name: str
    email: str
    email_domains: list[str]
    monthly_fee: float
    fee_per_student: float
    subsidy_per_student: float


class InvoiceOut(BaseModel):
    """O que a IES paga ao UniHub no mês."""

    monthly_fee: float  # taxa fixa do contrato
    per_student_fees: float  # taxa por aluno que assina × assinantes
    subsidies: float  # subsídio × assinantes
    total: float


class TopGymOut(BaseModel):
    gym_name: str
    checkins: int


class UniversityOverviewOut(BaseModel):
    reference_month: str
    registered_students: int  # cadastrados com o e-mail da IES
    subscribers: int  # com assinatura ativa (é sobre eles que a IES paga)
    active_users: int  # assinantes que treinaram ao menos uma vez no mês
    month_checkins: int
    visits_per_active_user: float
    invoice: InvoiceOut
    top_gyms: list[TopGymOut]


class UniversityStudentRow(BaseModel):
    id: int
    name: str
    email: str
    subscription_status: str | None
    month_checkins: int
    last_checkin: datetime | None


@router.get("", response_model=UniversityMeOut)
def get_me(university: University = Depends(get_current_university)):
    return UniversityMeOut(
        id=university.id,
        name=university.name,
        email=university.email,
        email_domains=university.email_domains,
        monthly_fee=float(university.monthly_fee),
        fee_per_student=float(university.fee_per_student),
        subsidy_per_student=float(university.subsidy_per_student),
    )


def _students(db: Session, university: University) -> list[Student]:
    return db.scalars(
        select(Student)
        .options(joinedload(Student.subscriptions))
        .where(Student.university_id == university.id)
        .order_by(Student.name)
    ).unique().all()


def _month_checkins(db: Session, student_ids: list[int], reference_month: str) -> list[CheckIn]:
    if not student_ids:
        return []
    start, end = payout_service.month_bounds(reference_month)
    return db.scalars(
        select(CheckIn)
        .options(joinedload(CheckIn.gym))
        .where(CheckIn.student_id.in_(student_ids), CheckIn.timestamp >= start, CheckIn.timestamp < end)
    ).all()


@router.get("/overview", response_model=UniversityOverviewOut)
def get_overview(university: University = Depends(get_current_university), db: Session = Depends(get_db)):
    """Visão do mês para a faculdade: adesão, uso e quanto ela paga."""
    reference_month = date.today().strftime("%Y-%m")
    students = _students(db, university)
    subscribers = [s for s in students if s.active_subscription and s.active_subscription.status == "active"]

    checkins = _month_checkins(db, [s.id for s in students], reference_month)
    subscriber_ids = {s.id for s in subscribers}
    active_users = len({c.student_id for c in checkins if c.student_id in subscriber_ids})

    n = len(subscribers)
    per_student_fees = float(university.fee_per_student) * n
    subsidies = float(university.subsidy_per_student) * n
    monthly_fee = float(university.monthly_fee)

    by_gym = Counter(c.gym.name for c in checkins)
    return UniversityOverviewOut(
        reference_month=reference_month,
        registered_students=len(students),
        subscribers=n,
        active_users=active_users,
        month_checkins=len(checkins),
        visits_per_active_user=round(len(checkins) / active_users, 1) if active_users else 0,
        invoice=InvoiceOut(
            monthly_fee=monthly_fee,
            per_student_fees=per_student_fees,
            subsidies=subsidies,
            total=monthly_fee + per_student_fees + subsidies,
        ),
        top_gyms=[TopGymOut(gym_name=name, checkins=count) for name, count in by_gym.most_common(5)],
    )


@router.get("/students", response_model=list[UniversityStudentRow])
def list_students(university: University = Depends(get_current_university), db: Session = Depends(get_db)):
    """Alunos da IES no programa, com o uso no mês corrente."""
    students = _students(db, university)
    checkins = _month_checkins(db, [s.id for s in students], date.today().strftime("%Y-%m"))
    counts = Counter(c.student_id for c in checkins)

    last_by_student = dict(
        db.execute(
            select(CheckIn.student_id, CheckIn.timestamp)
            .where(CheckIn.student_id.in_([s.id for s in students]))
            .order_by(CheckIn.timestamp)
        ).all()
    ) if students else {}

    rows = []
    for s in students:
        sub = s.active_subscription
        rows.append(
            UniversityStudentRow(
                id=s.id,
                name=s.name,
                email=s.email,
                subscription_status=sub.status if sub else None,
                month_checkins=counts.get(s.id, 0),
                last_checkin=last_by_student.get(s.id),
            )
        )
    return rows
