"""universities (IES conveniadas) and paid check-in cap

Revision ID: 9a4f2c7e1d03
Revises: 7c1e5a9d2b40
Create Date: 2026-10-26 22:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9a4f2c7e1d03'
down_revision: Union[str, None] = '7c1e5a9d2b40'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# IES conveniadas iniciais (mesmas do seed), para bancos que já existiam:
# sem elas, nenhum aluno novo conseguiria se cadastrar depois do deploy.
INITIAL_UNIVERSITIES = [
    ("FACAMP", ["facamp.edu.br"]),
    ("Unicamp", ["unicamp.br"]),
    ("PUC-Campinas", ["puccampinas.edu.br"]),
    ("FATEC Americana", ["fatec.sp.gov.br"]),
    ("FAM Americana", ["fam.br"]),
    ("ESAMC Campinas", ["esamc.br"]),
    ("Mackenzie Campinas", ["mackenzie.br"]),
]


def upgrade() -> None:
    universities = op.create_table('universities',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(length=120), nullable=False),
    sa.Column('email_domains', sa.JSON(), nullable=False),
    sa.Column('monthly_fee', sa.Numeric(precision=10, scale=2), nullable=False),
    sa.Column('fee_per_student', sa.Numeric(precision=10, scale=2), nullable=False),
    sa.Column('subsidy_per_student', sa.Numeric(precision=10, scale=2), nullable=False),
    sa.Column('is_active', sa.Boolean(), server_default='1', nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.add_column(sa.Column('university_id', sa.Integer(), nullable=True))
        batch_op.create_index(batch_op.f('ix_students_university_id'), ['university_id'], unique=False)
        batch_op.create_foreign_key('fk_students_university_id', 'universities', ['university_id'], ['id'])

    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_paid', sa.Boolean(), server_default='1', nullable=False))

    op.bulk_insert(universities, [
        {"name": name, "email_domains": domains, "monthly_fee": 3000,
         "fee_per_student": 15, "subsidy_per_student": 10, "is_active": True}
        for name, domains in INITIAL_UNIVERSITIES
    ])

    # Liga os alunos já cadastrados à IES pelo domínio do e-mail
    bind = op.get_bind()
    ids = dict(bind.execute(sa.text("SELECT name, id FROM universities")).all())
    students = bind.execute(sa.text("SELECT id, email FROM students")).all()
    for student_id, email in students:
        domain = email.rsplit("@", 1)[-1].lower()
        for name, domains in INITIAL_UNIVERSITIES:
            if any(domain == d or domain.endswith("." + d) for d in domains):
                bind.execute(
                    sa.text("UPDATE students SET university_id = :u, university = :n WHERE id = :s"),
                    {"u": ids[name], "n": name, "s": student_id},
                )
                break


def downgrade() -> None:
    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.drop_column('is_paid')

    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.drop_constraint('fk_students_university_id', type_='foreignkey')
        batch_op.drop_index(batch_op.f('ix_students_university_id'))
        batch_op.drop_column('university_id')

    op.drop_table('universities')
