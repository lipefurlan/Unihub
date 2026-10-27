"""Desafios: a operação cria entre faculdades (ou entre cursos de uma), a IES
cria entre os próprios cursos, e qualquer um com o link vê o placar."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_admin, get_current_university
from app.models import Challenge, University
from app.schemas.challenge import (
    ChallengeCreate,
    ChallengeDetailOut,
    ChallengeSummaryOut,
    ScoreboardOut,
)
from app.services import challenge_service

admin_router = APIRouter(
    prefix="/admin/challenges", tags=["Desafios"], dependencies=[Depends(get_current_admin)]
)
ies_router = APIRouter(prefix="/ies/me/challenges", tags=["Desafios"])
public_router = APIRouter(prefix="/public/scoreboard", tags=["Desafios"])


def _create(db: Session, payload: ChallengeCreate, university_id: int | None, created_by: str) -> dict:
    if university_id is not None and db.get(University, university_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Faculdade não encontrada.")
    challenge = challenge_service.create_challenge(
        db,
        title=payload.title,
        description=payload.description,
        scope=payload.scope,
        metric=payload.metric,
        start_date=payload.start_date,
        end_date=payload.end_date,
        university_id=university_id,
        created_by=created_by,
    )
    return challenge_service.summary(db, challenge, with_ranking=True)


@admin_router.get("", response_model=list[ChallengeSummaryOut])
def admin_list(db: Session = Depends(get_db)):
    return [challenge_service.summary(db, c) for c in challenge_service.list_challenges(db)]


@admin_router.post("", response_model=ChallengeDetailOut, status_code=status.HTTP_201_CREATED)
def admin_create(payload: ChallengeCreate, db: Session = Depends(get_db)):
    return _create(db, payload, payload.university_id, "admin")


@admin_router.get("/{challenge_id}", response_model=ChallengeDetailOut)
def admin_detail(challenge_id: int, db: Session = Depends(get_db)):
    return challenge_service.summary(db, challenge_service.get_challenge(db, challenge_id), with_ranking=True)


@admin_router.delete("/{challenge_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete(challenge_id: int, db: Session = Depends(get_db)):
    challenge_service.delete_challenge(db, challenge_service.get_challenge(db, challenge_id))


@ies_router.get("", response_model=list[ChallengeSummaryOut])
def ies_list(university: University = Depends(get_current_university), db: Session = Depends(get_db)):
    return [challenge_service.summary(db, c) for c in challenge_service.list_challenges(db, university)]


@ies_router.post("", response_model=ChallengeDetailOut, status_code=status.HTTP_201_CREATED)
def ies_create(
    payload: ChallengeCreate,
    university: University = Depends(get_current_university),
    db: Session = Depends(get_db),
):
    """A faculdade só cria desafios entre os próprios cursos."""
    payload.scope = "courses"
    return _create(db, payload, university.id, "ies")


@ies_router.get("/{challenge_id}", response_model=ChallengeDetailOut)
def ies_detail(
    challenge_id: int,
    university: University = Depends(get_current_university),
    db: Session = Depends(get_db),
):
    challenge = challenge_service.get_challenge(db, challenge_id, university)
    return challenge_service.summary(db, challenge, with_ranking=True)


@ies_router.delete("/{challenge_id}", status_code=status.HTTP_204_NO_CONTENT)
def ies_delete(
    challenge_id: int,
    university: University = Depends(get_current_university),
    db: Session = Depends(get_db),
):
    challenge = challenge_service.get_challenge(db, challenge_id, university)
    if challenge.university_id != university.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Só a operação apaga este desafio.")
    challenge_service.delete_challenge(db, challenge)


@public_router.get("/{token}", response_model=ScoreboardOut)
def scoreboard(token: str, db: Session = Depends(get_db)):
    challenge = db.scalar(select(Challenge).where(Challenge.public_token == token))
    if challenge is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Placar não encontrado.")
    return challenge_service.summary(db, challenge, with_ranking=True)
