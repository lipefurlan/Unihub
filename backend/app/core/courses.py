"""Cursos que o aluno escolhe no cadastro.

Lista fechada para os desafios entre cursos agruparem certo ("Adm" e
"Administração" seriam dois times diferentes com texto livre).
"""

from fastapi import HTTPException, status

COURSES = [
    "Administração",
    "Arquitetura e Urbanismo",
    "Ciência da Computação",
    "Comunicação Social",
    "Design",
    "Direito",
    "Economia",
    "Engenharia",
    "Medicina",
    "Psicologia",
    "Relações Internacionais",
    "Outro",
]


def normalize_course(value: str | None) -> str | None:
    """Aceita só cursos da lista (ignorando maiúsculas); vazio limpa o campo."""
    value = (value or "").strip()
    if not value:
        return None
    for course in COURSES:
        if course.lower() == value.lower():
            return course
    raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Curso inválido.")
