from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_student
from app.models import Plan, Student, Subscription
from app.schemas.subscription import SubscriptionCreate, SubscriptionOut, SubscriptionUpdate

router = APIRouter(prefix="/subscriptions", tags=["Assinaturas"])

# POC: ciclo de renovação fixo de 30 dias (sem pagamento real)
RENEWAL_CYCLE_DAYS = 30


@router.post("", response_model=SubscriptionOut, status_code=status.HTTP_201_CREATED)
def create_subscription(
    payload: SubscriptionCreate,
    student: Student = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    plan = db.get(Plan, payload.plan_id)
    if plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plano não encontrado.")

    if student.active_subscription is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Você já possui uma assinatura. Use a troca de plano no seu perfil.",
        )

    today = date.today()
    subscription = Subscription(
        student_id=student.id,
        plan_id=plan.id,
        start_date=today,
        renewal_date=today + timedelta(days=RENEWAL_CYCLE_DAYS),
        amount=plan.monthly_price,  # snapshot do preço contratado
        status="active",
    )
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


@router.put("/{subscription_id}", response_model=SubscriptionOut)
def update_subscription(
    subscription_id: int,
    payload: SubscriptionUpdate,
    student: Student = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Troca de plano (atualiza o valor contratado) e/ou mudança de status."""
    subscription = db.get(Subscription, subscription_id)
    if subscription is None or subscription.student_id != student.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assinatura não encontrada.")

    if payload.plan_id is not None:
        plan = db.get(Plan, payload.plan_id)
        if plan is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plano não encontrado.")
        subscription.plan_id = plan.id
        subscription.amount = plan.monthly_price

    if payload.status is not None:
        if payload.status not in ("active", "paused", "canceled"):
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Status inválido.")
        subscription.status = payload.status

    db.commit()
    db.refresh(subscription)
    return subscription
