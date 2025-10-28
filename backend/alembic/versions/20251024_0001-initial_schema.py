"""Initial schema with users, recordings, and analysis_results tables

Revision ID: 0001_initial
Revises:
Create Date: 2025-10-24 00:01:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON


# revision identifiers, used by Alembic.
revision = '0001_initial'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=100), nullable=False),
        sa.Column('auth_token', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    # Create recordings table
    op.create_table(
        'recordings',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('file_path', sa.String(length=500), nullable=False),
        sa.Column('file_size', sa.Integer(), nullable=False),
        sa.Column('duration', sa.Float(), nullable=False),
        sa.Column('format', sa.String(length=10), nullable=True),
        sa.Column('sample_rate', sa.Integer(), nullable=True),
        sa.Column('title', sa.String(length=200), nullable=True),
        sa.Column('notes', sa.String(length=1000), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_recordings_user_id'), 'recordings', ['user_id'], unique=False)

    # Create analysis_results table
    op.create_table(
        'analysis_results',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('recording_id', sa.String(length=36), nullable=False),
        sa.Column('transcript', sa.Text(), nullable=True),

        # Overall scores
        sa.Column('overall_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('power_dynamics_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('linguistic_authority_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('vocal_command_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('persuasion_influence_score', sa.Float(), nullable=False, server_default='0.0'),

        # Power Dynamics details
        sa.Column('filler_words_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('filler_words_per_minute', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('hedging_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('upspeak_indicators', sa.Integer(), nullable=False, server_default='0'),

        # Linguistic Authority details
        sa.Column('passive_voice_ratio', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('average_sentence_length', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('word_diversity_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('jargon_overuse_score', sa.Float(), nullable=False, server_default='0.0'),

        # Vocal Command details
        sa.Column('words_per_minute', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('average_pause_duration', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('pace_variance', sa.Float(), nullable=False, server_default='0.0'),

        # Persuasion Influence details
        sa.Column('story_coherence_score', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('call_to_action_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('power_words_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('evidence_indicators_count', sa.Integer(), nullable=False, server_default='0'),

        # JSON columns for detailed data
        sa.Column('patterns', JSON, nullable=True),
        sa.Column('critical_moments', JSON, nullable=True),

        # Timestamps
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),

        sa.ForeignKeyConstraint(['recording_id'], ['recordings.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('recording_id')
    )


def downgrade() -> None:
    op.drop_table('analysis_results')
    op.drop_table('recordings')
    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_table('users')
