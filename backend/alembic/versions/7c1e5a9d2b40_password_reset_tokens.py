"""password reset tokens

Revision ID: 7c1e5a9d2b40
Revises: 3bd88a2624e2
Create Date: 2026-10-26 21:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7c1e5a9d2b40'
down_revision: Union[str, None] = '3bd88a2624e2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('password_reset_tokens',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('role', sa.String(length=20), nullable=False),
    sa.Column('account_id', sa.Integer(), nullable=False),
    sa.Column('token_hash', sa.String(length=64), nullable=False),
    sa.Column('expires_at', sa.DateTime(), nullable=False),
    sa.Column('used_at', sa.DateTime(), nullable=True),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('password_reset_tokens', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_password_reset_tokens_account_id'), ['account_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_password_reset_tokens_token_hash'), ['token_hash'], unique=True)


def downgrade() -> None:
    with op.batch_alter_table('password_reset_tokens', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_password_reset_tokens_token_hash'))
        batch_op.drop_index(batch_op.f('ix_password_reset_tokens_account_id'))
    op.drop_table('password_reset_tokens')
