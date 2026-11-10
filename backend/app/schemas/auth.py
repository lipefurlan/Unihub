from pydantic import BaseModel, EmailStr, Field


class StudentRegister(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6)
    # A universidade vem do domínio do e-mail (IES conveniada); o campo
    # continua aceito para não quebrar clientes antigos, mas é ignorado.
    university: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str  # student | gym | admin | ies


class GoogleLoginRequest(BaseModel):
    # ID token (JWT) devolvido pelo botão "Fazer login com o Google"
    credential: str = Field(min_length=10)
    # O painel (academia/admin) manda False: lá o Google só entra em conta existente
    allow_signup: bool = True


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=10)
    new_password: str = Field(min_length=6)


class MessageResponse(BaseModel):
    detail: str
