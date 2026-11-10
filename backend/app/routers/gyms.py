from collections import Counter
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_gym
from app.models import CheckIn, Gym
from app.schemas.gym import GymBusyHoursOut, GymOwnerOut, GymPublicOut, GymUpdate, TrendingGymOut
from app.services import engagement_service

router = APIRouter(prefix="/gyms", tags=["Academias"])

# Faixa do dia considerada no "horário mais vazio"
BUSY_FIRST_HOUR = 6
BUSY_LAST_HOUR = 22
BUSY_WINDOW_DAYS = 30


def _same_city(a: str, b: str) -> bool:
    return a.strip().lower() == b.strip().lower()


@router.get("", response_model=list[GymPublicOut])
def list_gyms(
    modality: str | None = Query(default=None, description="Filtra por modalidade (ex.: musculação)"),
    max_tier: int | None = Query(default=None, ge=1, le=7, description="Tier mínimo de acesso até este valor"),
    search: str | None = Query(default=None, description="Busca por nome"),
    city: str | None = Query(default=None, description="Filtra pela cidade (ex.: Campinas)"),
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
    if city:
        gyms = [g for g in gyms if _same_city(g.city, city)]
    return engagement_service.attach_ratings(db, gyms)


@router.get("/trending", response_model=list[TrendingGymOut])
def list_trending(db: Session = Depends(get_db)):
    """Academias com mais check-ins UniHub nos últimos 7 dias."""
    rows = engagement_service.trending_gyms(db)
    engagement_service.attach_ratings(db, [gym for gym, _ in rows])
    return [{"gym": gym, "recent_checkins": count} for gym, count in rows]


@router.get("/cities", response_model=list[str])
def list_cities(db: Session = Depends(get_db)):
    """Cidades com academia parceira ativa (para o aluno escolher a cidade natal)."""
    gyms = db.scalars(select(Gym).where(Gym.is_active.is_(True))).all()
    return sorted({g.city for g in gyms})


@router.get("/{gym_id}/busy-hours", response_model=GymBusyHoursOut)
def get_busy_hours(gym_id: int, db: Session = Depends(get_db)):
    """Movimento por hora e a faixa de 2h mais vazia (só check-ins UniHub)."""
    if db.get(Gym, gym_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")
    since = datetime.now() - timedelta(days=BUSY_WINDOW_DAYS)
    stamps = db.scalars(
        select(CheckIn.timestamp).where(CheckIn.gym_id == gym_id, CheckIn.timestamp >= since)
    ).all()
    per_hour = Counter(t.hour for t in stamps)
    hours = [{"hour": h, "checkins": per_hour[h]} for h in range(BUSY_FIRST_HOUR, BUSY_LAST_HOUR)]

    if not stamps:
        return {"hours": hours, "quietest_start": None, "quietest_end": None}
    # Menor soma em janelas de 2h; empate fica com a mais cedo
    start = min(
        range(BUSY_FIRST_HOUR, BUSY_LAST_HOUR - 1),
        key=lambda h: (per_hour[h] + per_hour[h + 1], h),
    )
    return {"hours": hours, "quietest_start": start, "quietest_end": start + 2}


@router.get("/{gym_id}", response_model=GymPublicOut)
def get_gym(gym_id: int, db: Session = Depends(get_db)):
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")
    return engagement_service.attach_ratings(db, [gym])[0]


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
