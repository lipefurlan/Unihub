"""e-mail institucional, celular, confirmação por código e lista de alunos da IES

Revision ID: c4e7a2d9f1b3
Revises: a6d3f0b8c912
Create Date: 2026-11-10 15:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c4e7a2d9f1b3'
down_revision: Union[str, None] = 'a6d3f0b8c912'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.add_column(sa.Column('institutional_email', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('email_verified_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('institutional_email_verified_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('phone', sa.String(length=20), nullable=True))
        batch_op.add_column(sa.Column('phone_verified_at', sa.DateTime(), nullable=True))
        batch_op.create_index(batch_op.f('ix_students_institutional_email'), ['institutional_email'], unique=True)

    # Alunos que já existiam se cadastraram com o e-mail da faculdade (o domínio
    # era conferido no cadastro): esse e-mail vira o institucional e ninguém
    # precisa confirmar de novo.
    op.execute(
        "UPDATE students SET institutional_email = email, "
        "email_verified_at = CURRENT_TIMESTAMP, institutional_email_verified_at = CURRENT_TIMESTAMP"
    )

    op.create_table('email_verification_codes',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('student_id', sa.Integer(), nullable=False),
    sa.Column('kind', sa.String(length=20), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.Column('code_hash', sa.String(length=64), nullable=False),
    sa.Column('attempts', sa.Integer(), server_default='0', nullable=False),
    sa.Column('expires_at', sa.DateTime(), nullable=False),
    sa.Column('used_at', sa.DateTime(), nullable=True),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['student_id'], ['students.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('email_verification_codes', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_email_verification_codes_student_id'), ['student_id'], unique=False)

    op.create_table('university_roster',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('university_id', sa.Integer(), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.Column('name', sa.String(length=120), nullable=True),
    sa.Column('ra', sa.String(length=40), nullable=True),
    sa.Column('imported_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['university_id'], ['universities.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('university_id', 'email', name='uq_roster_university_email')
    )
    with op.batch_alter_table('university_roster', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_university_roster_email'), ['email'], unique=False)
        batch_op.create_index(batch_op.f('ix_university_roster_university_id'), ['university_id'], unique=False)


def downgrade() -> None:
    op.drop_table('university_roster')
    op.drop_table('email_verification_codes')
    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_students_institutional_email'))
        batch_op.drop_column('phone_verified_at')
        batch_op.drop_column('phone')
        batch_op.drop_column('institutional_email_verified_at')
        batch_op.drop_column('email_verified_at')
        batch_op.drop_column('institutional_email')
