\ir ../lib/session.sql
-- Longer than automatic labs so a learner can coordinate independent terminals.
-- These are teaching-session limits, not production recommendations.
SET statement_timeout='5min';
SET lock_timeout='30s';
SET idle_in_transaction_session_timeout='15min';
