"""Lista oficial de alunos da IES: importação do CSV e conferência no cadastro."""

import csv
import io
import re
from dataclasses import dataclass, field

from fastapi import HTTPException, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.models import University, UniversityRosterEntry

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
MAX_ROWS = 50_000

# Nomes de coluna aceitos (comparados sem acento, em minúsculas)
EMAIL_HEADERS = ("email", "e-mail", "email institucional", "e-mail institucional", "mail")
NAME_HEADERS = ("nome", "name", "nome completo", "aluno")
RA_HEADERS = ("ra", "matricula", "matrícula", "registro academico", "registro acadêmico", "r.a.")


def roster_size(db: Session, university_id: int) -> int:
    return db.scalar(
        select(func.count(UniversityRosterEntry.id)).where(UniversityRosterEntry.university_id == university_id)
    ) or 0


def in_roster(db: Session, university_id: int, email: str) -> bool:
    return db.scalar(
        select(UniversityRosterEntry.id).where(
            UniversityRosterEntry.university_id == university_id,
            UniversityRosterEntry.email == email.lower(),
        )
    ) is not None


def require_in_roster(db: Session, university: University, email: str) -> None:
    """Se a IES enviou a lista de alunos, o e-mail institucional precisa estar nela."""
    if roster_size(db, university.id) == 0:
        return  # sem lista: vale o domínio + código de confirmação
    if not in_roster(db, university.id, email):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"Este e-mail não está na lista de alunos que a {university.name} enviou ao UniHub. "
                "Confira se digitou certo ou procure a secretaria da faculdade."
            ),
        )


@dataclass
class ImportResult:
    total_rows: int = 0
    imported: int = 0
    duplicates: int = 0
    invalid: int = 0
    wrong_domain: int = 0
    roster_size: int = 0
    errors: list[str] = field(default_factory=list)


def _decode(content: bytes) -> str:
    for encoding in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            return content.decode(encoding)
        except UnicodeDecodeError:
            continue
    raise HTTPException(status_code=422, detail="Não consegui ler o arquivo. Salve o CSV em UTF-8.")


def _norm(value: str) -> str:
    return value.strip().lower().replace("_", " ")


def _find_col(header: list[str], options: tuple[str, ...]) -> int | None:
    normalized = [_norm(h) for h in header]
    for i, h in enumerate(normalized):
        if h in options:
            return i
    return None


def parse_csv(content: bytes) -> list[dict]:
    """Lê o CSV (vírgula ou ponto e vírgula, com ou sem cabeçalho).

    Retorna as linhas como {email, name, ra, line}.
    """
    text = _decode(content)
    if not text.strip():
        raise HTTPException(status_code=422, detail="O arquivo está vazio.")
    first_line = text.splitlines()[0]
    delimiter = ";" if first_line.count(";") > first_line.count(",") else ","
    rows = [r for r in csv.reader(io.StringIO(text), delimiter=delimiter) if any(c.strip() for c in r)]
    if len(rows) > MAX_ROWS + 1:
        raise HTTPException(status_code=422, detail=f"Arquivo grande demais (máximo {MAX_ROWS} alunos).")

    header = rows[0]
    email_col = _find_col(header, EMAIL_HEADERS)
    if email_col is not None:
        name_col, ra_col, data, first_line_no = _find_col(header, NAME_HEADERS), _find_col(header, RA_HEADERS), rows[1:], 2
    else:
        # Sem cabeçalho: a coluna de e-mail é a primeira que tem "@"
        email_col = next((i for i, c in enumerate(header) if "@" in c), None)
        if email_col is None:
            raise HTTPException(
                status_code=422,
                detail="Não achei a coluna de e-mail. Use um cabeçalho com \"email\" (e, se quiser, \"nome\" e \"ra\").",
            )
        name_col, ra_col, data, first_line_no = None, None, rows, 1

    def cell(row: list[str], col: int | None) -> str | None:
        if col is None or col >= len(row):
            return None
        return row[col].strip() or None

    return [
        {"email": (cell(r, email_col) or "").lower(), "name": cell(r, name_col), "ra": cell(r, ra_col), "line": i}
        for i, r in enumerate(data, start=first_line_no)
    ]


def import_roster(db: Session, university: University, content: bytes, replace: bool) -> ImportResult:
    rows = parse_csv(content)
    result = ImportResult(total_rows=len(rows))

    if replace:
        db.execute(delete(UniversityRosterEntry).where(UniversityRosterEntry.university_id == university.id))
        existing: set[str] = set()
    else:
        existing = set(
            db.scalars(
                select(UniversityRosterEntry.email).where(UniversityRosterEntry.university_id == university.id)
            ).all()
        )

    seen: set[str] = set()
    for row in rows:
        email = row["email"]
        if not EMAIL_RE.match(email):
            result.invalid += 1
            if len(result.errors) < 10:
                result.errors.append(f"Linha {row['line']}: e-mail inválido ({email or 'vazio'}).")
            continue
        if not university.accepts_email(email):
            result.wrong_domain += 1
            if len(result.errors) < 10:
                result.errors.append(f"Linha {row['line']}: {email} não é de um domínio da {university.name}.")
            continue
        if email in seen or email in existing:
            result.duplicates += 1
            continue
        seen.add(email)
        db.add(
            UniversityRosterEntry(
                university_id=university.id,
                email=email,
                name=(row["name"] or None) and row["name"][:120],
                ra=(row["ra"] or None) and row["ra"][:40],
            )
        )
        result.imported += 1

    db.commit()
    result.roster_size = roster_size(db, university.id)
    return result
