#!/usr/bin/env python3
"""
Script to split the monolithic init.sql into separate database initialization files
for restaurant_db, driver_db, orders_db, and notification_db.
"""

import re

def extract_section(lines, start_pattern, end_pattern=None):
    """Extract lines between start_pattern and end_pattern (or end of file)."""
    start_idx = None
    for i, line in enumerate(lines):
        if re.search(start_pattern, line):
            start_idx = i
            break
    
    if start_idx is None:
        return []
    
    if end_pattern:
        end_idx = None
        for i in range(start_idx + 1, len(lines)):
            if re.search(end_pattern, line):
                end_idx = i
                break
        if end_idx:
            return lines[start_idx:end_idx]
        return lines[start_idx:]
    
    return lines[start_idx:]

def main():
    with open('infra/postgres/init.sql', 'r', encoding='utf-8') as f:
        all_lines = f.readlines()
    
    # Restaurant DB: restaurants, menu_categories, menu_items
    restaurant_db_lines = []
    restaurant_db_lines.append("-- ============================================================\n")
    restaurant_db_lines.append("--  Restaurant Database — PostgreSQL Initialisation Script\n")
    restaurant_db_lines.append("--  Executed automatically on first container start\n")
    restaurant_db_lines.append("-- ============================================================\n\n")
    restaurant_db_lines.append("-- Enable UUID generation\n")
    restaurant_db_lines.append('CREATE EXTENSION IF NOT EXISTS "pgcrypto";\n\n')
    
    # Extract table definitions
    restaurant_db_lines.extend(all_lines[13:40])  # restaurants, menu_categories, menu_items tables
    
    # Extract indexes for restaurant tables
    restaurant_db_lines.append("\n-- ──────────────────────────────────────────────────────────────\n")
    restaurant_db_lines.append("--  INDEXES\n")
    restaurant_db_lines.append("-- ──────────────────────────────────────────────────────────────\n\n")
    restaurant_db_lines.extend(all_lines[91:103])  # menu-related indexes
    
    # Extract seed data
    restaurant_db_lines.append("\n-- ──────────────────────────────────────────────────────────────\n")
    restaurant_db_lines.append("--  SEED DATA\n")
    restaurant_db_lines.append("-- ──────────────────────────────────────────────────────────────\n\n")
    
    # Extract restaurants INSERT (lines 118-1719)
    restaurant_db_lines.extend(all_lines[117:1720])
    
    # Extract menu_categories INSERT (lines 1721-5293)
    restaurant_db_lines.extend(all_lines[1720:5294])
    
    # Extract menu_items INSERT (lines 5294-24349)
    restaurant_db_lines.extend(all_lines[5293:24350])
    
    # Driver DB: drivers, driver_location_history
    driver_db_lines = []
    driver_db_lines.append("-- ============================================================\n")
    driver_db_lines.append("--  Driver Database — PostgreSQL Initialisation Script\n")
    driver_db_lines.append("--  Executed automatically on first container start\n")
    driver_db_lines.append("-- ============================================================\n\n")
    driver_db_lines.append("-- Enable UUID generation\n")
    driver_db_lines.append('CREATE EXTENSION IF NOT EXISTS "pgcrypto";\n\n')
    
    # Extract driver tables
    driver_db_lines.extend(all_lines[41:50])  # drivers table
    driver_db_lines.extend(all_lines[71:81])  # driver_location_history table
    
    # Extract indexes for driver tables
    driver_db_lines.append("\n-- ──────────────────────────────────────────────────────────────\n")
    driver_db_lines.append("--  INDEXES\n")
    driver_db_lines.append("-- ──────────────────────────────────────────────────────────────\n\n")
    driver_db_lines.extend(all_lines[104:113])  # driver location indexes
    
    # Extract seed data
    driver_db_lines.append("\n-- ──────────────────────────────────────────────────────────────\n")
    driver_db_lines.append("--  SEED DATA\n")
    driver_db_lines.append("-- ──────────────────────────────────────────────────────────────\n\n")
    
    # Extract drivers INSERT (lines 24350-24372)
    driver_db_lines.extend(all_lines[24349:24373])
    
    # Order DB: orders, order_items (no foreign keys to other DBs)
    orders_db_lines = []
    orders_db_lines.append("-- ============================================================\n")
    orders_db_lines.append("--  Order Database — PostgreSQL Initialisation Script\n")
    orders_db_lines.append("--  Executed automatically on first container start\n")
    orders_db_lines.append("-- ============================================================\n\n")
    orders_db_lines.append("-- Enable UUID generation\n")
    orders_db_lines.append('CREATE EXTENSION IF NOT EXISTS "pgcrypto";\n\n')
    
    # Extract order tables (remove FK constraints to restaurants and drivers)
    order_table_def = all_lines[50:61].copy()  # orders table
    # Remove FK constraint to restaurants
    order_table_def[2] = "    restaurant_id   UUID           NOT NULL,\n"
    # Remove FK constraint to drivers
    order_table_def[3] = "    driver_id       UUID,\n"
    orders_db_lines.extend(order_table_def)
    
    order_items_def = all_lines[62:71].copy()  # order_items table
    # Keep FK to orders (same DB), but remove FK to menu_items (different DB)
    orders_db_lines.extend(order_items_def)
    
    # Extract indexes for order tables
    orders_db_lines.append("\n-- ──────────────────────────────────────────────────────────────\n")
    orders_db_lines.append("--  INDEXES\n")
    orders_db_lines.append("-- ──────────────────────────────────────────────────────────────\n\n")
    orders_db_lines.extend(all_lines[85:91])  # order indexes
    
    # Notification DB: empty (no tables needed)
    notification_db_lines = []
    notification_db_lines.append("-- ============================================================\n")
    notification_db_lines.append("--  Notification Database — PostgreSQL Initialisation Script\n")
    notification_db_lines.append("--  Executed automatically on first container start\n")
    notification_db_lines.append("--  Note: Notification service uses Redis and RabbitMQ, not PostgreSQL\n")
    notification_db_lines.append("-- ============================================================\n\n")
    notification_db_lines.append("-- Enable UUID generation\n")
    notification_db_lines.append('CREATE EXTENSION IF NOT EXISTS "pgcrypto";\n\n')
    notification_db_lines.append("-- No tables required for notification service\n")
    notification_db_lines.append("-- This service uses Redis for session management and RabbitMQ for events\n")
    
    # Write files
    with open('infra/postgres/init-restaurant.sql', 'w', encoding='utf-8') as f:
        f.writelines(restaurant_db_lines)
    
    with open('infra/postgres/init-driver.sql', 'w', encoding='utf-8') as f:
        f.writelines(driver_db_lines)
    
    with open('infra/postgres/init-order.sql', 'w', encoding='utf-8') as f:
        f.writelines(orders_db_lines)
    
    with open('infra/postgres/init-notification.sql', 'w', encoding='utf-8') as f:
        f.writelines(notification_db_lines)
    
    print("Created separate database initialization files:")
    print("   - infra/postgres/init-restaurant.sql")
    print("   - infra/postgres/init-driver.sql")
    print("   - infra/postgres/init-order.sql")
    print("   - infra/postgres/init-notification.sql")

if __name__ == '__main__':
    main()
