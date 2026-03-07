-- Script to remove indexes that degraded performance
-- Run this if P99 response time increased after adding indexes

-- Drop the problematic composite indexes
DROP INDEX IF EXISTS idx_menu_items_restaurant_category;
DROP INDEX IF EXISTS idx_menu_categories_restaurant_order_id;

-- Verify indexes are removed
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('menu_items', 'menu_categories')
ORDER BY tablename, indexname;
