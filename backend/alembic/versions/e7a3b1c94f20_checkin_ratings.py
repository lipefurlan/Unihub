"""checkin ratings (aluno avalia a visita)

Revision ID: e7a3b1c94f20
Revises: d2c4e9f81a56
Create Date: 2026-10-27 11:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e7a3b1c94f20'
down_revision: Union[str, None] = 'd2c4e9f81a56'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.add_column(sa.Column('rating', sa.SmallInteger(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('checkins', schema=None) as batch_op:
        batch_op.drop_column('rating')
