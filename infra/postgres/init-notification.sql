-- ============================================================
--  Notification Database — PostgreSQL Initialisation Script
--  Executed automatically on first container start
--  Note: Notification service uses Redis and RabbitMQ, not PostgreSQL
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- No tables required for notification service
-- This service uses Redis for session management and RabbitMQ for events
