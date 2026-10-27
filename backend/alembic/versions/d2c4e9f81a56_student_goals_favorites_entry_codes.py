"""student goals, home city, favorites and per-visit entry codes

Revision ID: d2c4e9f81a56
Revises: b5e81d6a3c27
Create Date: 2026-10-27 02:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd2c4e9f81a56'
down_revision: Union[str, None] = 'b5e81d6a3c27'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.add_column(sa.Column('weekly_goal', sa.Integer(), server_default='3', nullable=False))
        batch_op.add_column(sa.Column('home_city', sa.String(length=80), nullable=True))

    op.create_table('favorite_gyms',
    sa.Column('student_id', sa.Integer(), nullable=False),
    sa.Column('gym_id', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['gym_id'], ['gyms.id'], ),
    sa.ForeignKeyConstraint(['student_id'], ['students.id'], ),
    sa.PrimaryKeyConstraint('student_id', 'gym_id')
    )

    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.add_column(sa.Column('entry_code', sa.String(length=12), nullable=True))
        batch_op.add_column(sa.Column('validated_at', sa.DateTime(), nullable=True))
        batch_op.create_index(batch_op.f('ix_checkins_entry_code'), ['entry_code'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_checkins_entry_code'))
        batch_op.drop_column('validated_at')
        batch_op.drop_column('entry_code')

    op.drop_table('favorite_gyms')

    with op.batch_alter_table('students', schema=None) as batch_op:
        batch_op.drop_column('home_city')
        batch_op.drop_column('weekly_goal')
