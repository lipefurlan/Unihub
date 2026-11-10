"""plan is_active, academias e restrições do plano

Revision ID: a6d3f0b8c912
Revises: f3c8d2a17b64
Create Date: 2026-11-10 11:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a6d3f0b8c912'
down_revision: Union[str, None] = 'f3c8d2a17b64'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('plans', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_active', sa.Boolean(), server_default='1', nullable=False))
        batch_op.add_column(sa.Column('all_gyms', sa.Boolean(), server_default='1', nullable=False))
        batch_op.add_column(sa.Column('gym_ids', sa.JSON(), nullable=True))
        batch_op.add_column(sa.Column('max_checkins_per_month', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('max_checkins_per_day', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('allowed_from', sa.String(length=5), nullable=True))
        batch_op.add_column(sa.Column('allowed_until', sa.String(length=5), nullable=True))
        batch_op.add_column(sa.Column('restrictions_note', sa.Text(), server_default='', nullable=False))


def downgrade() -> None:
    with op.batch_alter_table('plans', schema=None) as batch_op:
        for col in ('restrictions_note', 'allowed_until', 'allowed_from', 'max_checkins_per_day',
                    'max_checkins_per_month', 'gym_ids', 'all_gyms', 'is_active'):
            batch_op.drop_column(col)
