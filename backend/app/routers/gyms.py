from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_gym
from app.models import Gym
from app.schemas.gym import GymOwnerOut, GymPublicOut, GymUpdate

router = APIRouter(prefix="/gyms", tags=["Academias"])


@router.get("", response_model=list[GymPublicOut])
def list_gyms(
    modality: str | None = Query(default=None, description="Filtra por modalidade (ex.: musculação)"),
    max_tier: int | None = Query(default=None, ge=1, le=7, description="Tier mínimo de acesso até este valor"),
    search: str | None = Query(default=None, description="Busca por nome"),
    db: Session = Depends(get_db),
):
    # Academias desativadas pelo admin não aparecem para os estudantes
    gyms = db.scalars(select(Gym).where(Gym.is_active.is_(True)).order_by(Gym.name)).all()
    # Filtro de modalidade em Python: a coluna JSON fica portável entre SQLite e PostgreSQL
    if modality:
        gyms = [g for g in gyms if modality.lower() in [m.lower() for m in g.modalities]]
    if max_tier is not None:
        gyms = [g for g in gyms if g.min_plan_tier <= max_tier]
    if search:
        gyms = [g for g in gyms if search.lower() in g.name.lower()]
    return gyms


@router.get("/{gym_id}", response_model=GymPublicOut)
def get_gym(gym_id: int, db: Session = Depends(get_db)):
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")
    return gym


@router.put("/{gym_id}", response_model=GymOwnerOut)
def update_gym(
    gym_id: int,
    payload: GymUpdate,
    current_gym: Gym = Depends(get_current_gym),
    db: Session = Depends(get_db),
):
    """A academia só pode editar os próprios dados."""
    if gym_id != current_gym.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você só pode editar os dados da própria academia.",
        )

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(current_gym, field, value)

    db.commit()
    db.refresh(current_gym)
    return current_gym
