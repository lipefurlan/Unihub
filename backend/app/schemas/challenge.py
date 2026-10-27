from datetime import date

from pydantic import BaseModel, Field


class ChallengeCreate(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    description: str | None = Field(default=None, max_length=500)
    scope: str = "universities"  # universities | courses
    metric: str = "checkins_per_student"  # checkins_per_student | active_share
    start_date: date
    end_date: date
    # Obrigatório para desafio entre cursos criado pela operação; a IES usa a dela
    university_id: int | None = None


class ChallengeRowOut(BaseModel):
    position: int
    name: str  # faculdade ou curso
    participants: int  # assinantes ativos do grupo
    checkins: int
    active_students: int  # com ao menos um treino por semana do desafio
    score: float


class EvolutionSeries(BaseModel):
    name: str
    points: list[float]


class EvolutionOut(BaseModel):
    labels: list[str]  # último dia de cada semana, YYYY-MM-DD
    series: list[EvolutionSeries]


class ChallengeSummaryOut(BaseModel):
    id: int
    title: str
    description: str | None
    scope: str
    metric: str
    metric_label: str
    university_id: int | None
    university_name: str | None
    start_date: date
    end_date: date
    status: str  # upcoming | active | ended
    public_token: str
    created_by: str
    groups: int
    participants: int
    total_checkins: int
    leader: str | None
    champion: str | None  # só quando encerrado


class ChallengeDetailOut(ChallengeSummaryOut):
    ranking: list[ChallengeRowOut]
    evolution: EvolutionOut


class StudentChallengeOut(ChallengeDetailOut):
    my_group: str | None
    my_checkins: int


class ScoreboardOut(BaseModel):
    """Placar público (TV, grupo da turma): sem token e sem dados de aluno."""

    title: str
    description: str | None
    scope: str
    metric: str
    metric_label: str
    university_name: str | None
    start_date: date
    end_date: date
    status: str
    total_checkins: int
    participants: int
    ranking: list[ChallengeRowOut]
