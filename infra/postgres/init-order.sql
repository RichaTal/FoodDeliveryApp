-- ============================================================
--  Order Database — PostgreSQL Initialisation Script
--  Executed automatically on first container start
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS orders (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id   UUID           NOT NULL,
    driver_id       UUID,
    status          VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    payment_status  VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    payment_txn_id  VARCHAR(255),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS order_items (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id    UUID           NOT NULL,
    name            VARCHAR(255)   NOT NULL,  -- snapshot of item name at time of order
    price_at_time   DECIMAL(10, 2) NOT NULL CHECK (price_at_time >= 0),  -- snapshot price
    quantity        INT            NOT NULL CHECK (quantity > 0)
);


-- ──────────────────────────────────────────────────────────────
--  INDEXES
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders (status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);

