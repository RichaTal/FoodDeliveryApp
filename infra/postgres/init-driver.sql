-- ============================================================
--  Driver Database — PostgreSQL Initialisation Script
--  Executed automatically on first container start
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS drivers (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(255) NOT NULL,
    phone      VARCHAR(20)  NOT NULL UNIQUE,
    vehicle    VARCHAR(100) NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_location_history (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id   UUID         NOT NULL REFERENCES drivers(id),
    order_id    UUID,  -- References orders in orders_db (no FK constraint across databases)
    lat         DECIMAL(10, 8) NOT NULL,
    lng         DECIMAL(11, 8) NOT NULL,
    timestamp   BIGINT       NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);


-- ──────────────────────────────────────────────────────────────
--  INDEXES
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_driver_location_history_order_timestamp
    ON driver_location_history (order_id, timestamp);

CREATE INDEX IF NOT EXISTS idx_driver_location_history_driver_timestamp
    ON driver_location_history (driver_id, timestamp);

CREATE INDEX IF NOT EXISTS idx_driver_location_history_timestamp
    ON driver_location_history (timestamp);


-- ──────────────────────────────────────────────────────────────
--  SEED DATA
-- ──────────────────────────────────────────────────────────────

-- Drivers (3 drivers)
INSERT INTO drivers (id, name, phone, vehicle, is_active) VALUES
(
    'e1111111-1111-4111-8111-111111111111',
    'Alex Rivera',
    '+1-555-0101',
    'Honda PCX 150 Scooter',
    TRUE
),
(
    'e2222222-2222-4222-8222-222222222222',
    'Sam Chen',
    '+1-555-0102',
    'Yamaha NMAX 155 Scooter',
    TRUE
),
(
    'e3333333-3333-4333-8333-333333333333',
    'Jordan Lee',
    '+1-555-0103',
    'Trek FX3 Disc Bicycle',
    TRUE
);
