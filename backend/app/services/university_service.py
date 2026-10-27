from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import University


def find_university_for_email(db: Session, email: str) -> University | None:
    for university in db.scalars(select(University).where(University.is_active.is_(True))).all():
        if university.accepts_email(email):
            return university
    return None


def require_university_for_email(db: Session, email: str) -> University:
    """Só assinam alunos de IES com contrato: o e-mail precisa ser de uma conveniada."""
    university = find_university_for_email(db, email)
    if university is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Use o e-mail da sua faculdade. O UniHub é oferecido pelas faculdades "
                "conveniadas, e este e-mail não é de nenhuma delas."
            ),
        )
    return university


def student_price(plan_price: Decimal, university: University | None) -> Decimal:
    """Quanto o aluno paga: preço do plano menos o subsídio da IES."""
    subsidy = university.subsidy_per_student if university else Decimal("0")
    return max(plan_price - subsidy, Decimal("0"))
