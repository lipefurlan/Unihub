"""university portal login (IES no painel)

Revision ID: b5e81d6a3c27
Revises: 9a4f2c7e1d03
Create Date: 2026-10-27 01:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b5e81d6a3c27'
down_revision: Union[str, None] = '9a4f2c7e1d03'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('universities', schema=None) as batch_op:
        batch_op.add_column(sa.Column('email', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('password_hash', sa.String(length=255), nullable=True))
        batch_op.create_index(batch_op.f('ix_universities_email'), ['email'], unique=True)


def downgrade() -> None:
    with op.batch_alter_table('universities', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_universities_email'))
        batch_op.drop_column('password_hash')
        batch_op.drop_column('email')
