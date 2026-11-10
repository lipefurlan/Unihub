"""plan is_active (operação pode tirar um plano da vitrine)

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


def downgrade() -> None:
    with op.batch_alter_table('plans', schema=None) as batch_op:
        batch_op.drop_column('is_active')
