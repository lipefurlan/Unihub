from pydantic import BaseModel, ConfigDict, EmailStr

from app.schemas.subscription import SubscriptionOut


class StudentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr
    university: str
    photo_url: str | None
    status: str


class StudentProfileOut(StudentOut):
    """Perfil completo: dados do aluno + assinatura vigente."""

    subscription: SubscriptionOut | None = None
