"""challenges (desafios entre faculdades e cursos) and student course

Revision ID: f3c8d2a17b64
Revises: e7a3b1c94f20
Create Date: 2026-10-27 12:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f3c8d2a17b64'
down_revision: Union[str, None] = 'e7a3b1c94f20'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.add_column(sa.Column('course', sa.String(length=80), nullable=True))
        batch_op.create_index(batch_op.f('ix_students_course'), ['course'], unique=False)

    op.create_table('challenges',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('title', sa.String(length=120), nullable=False),
    sa.Column('description', sa.String(length=500), nullable=True),
    sa.Column('scope', sa.String(length=20), nullable=False),
    sa.Column('university_id', sa.Integer(), nullable=True),
    sa.Column('metric', sa.String(length=30), nullable=False),
    sa.Column('start_date', sa.Date(), nullable=False),
    sa.Column('end_date', sa.Date(), nullable=False),
    sa.Column('public_token', sa.String(length=24), nullable=False),
    sa.Column('created_by', sa.String(length=10), nullable=False),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['university_id'], ['universities.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('challenges', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_challenges_public_token'), ['public_token'], unique=True)
        batch_op.create_index(batch_op.f('ix_challenges_university_id'), ['university_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('challenges', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_challenges_university_id'))
        batch_op.drop_index(batch_op.f('ix_challenges_public_token'))
    op.drop_table('challenges')

    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_students_course'))
        batch_op.drop_column('course')
