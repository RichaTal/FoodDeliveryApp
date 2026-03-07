# Performance Optimizations for Restaurant Menu Service

## Problem
P99 response time was 270ms, exceeding the 200ms requirement under high load (100 concurrent requests, 2000 total requests).

## Optimizations Applied

### 1. **Single JOIN Query Instead of 3 Sequential Queries**

**Before:**
- 3 separate database queries executed sequentially
- Total time = Query1 + Query2 + Query3 + network overhead × 3

**After:**
- Single optimized JOIN query
- Reduced database round trips from 3 to 1
- Faster execution with proper indexes

**Impact:** ~40-60% reduction in database query time

### 2. **Database Indexes Added**

Added missing indexes for faster lookups:

```sql
CREATE INDEX IF NOT EXISTS idx_menu_categories_restaurant_id
    ON menu_categories (restaurant_id);

CREATE INDEX IF NOT EXISTS idx_menu_items_category_id
    ON menu_items (category_id);

CREATE INDEX IF NOT EXISTS idx_menu_categories_display_order
    ON menu_categories (restaurant_id, display_order);
```

**Impact:** Faster JOIN operations and ORDER BY queries

### 3. **Increased Database Connection Pool**

**Before:** `max: 20` connections
**After:** `max: 50` connections (configurable via `DB_POOL_MAX` env var)

**Impact:** Better handling of high concurrent requests (100+ concurrent)

### 4. **Non-Blocking Cache Write**

**Before:** `await redisSet(...)` - blocks response until cache write completes
**After:** Fire-and-forget cache write - response returns immediately

**Impact:** ~5-10ms improvement per cache miss

### 5. **Query Timeout Protection**

Added `statement_timeout: 5_000` to prevent slow queries from blocking the pool.

## Expected Performance Improvements

| Metric | Before | After (Expected) | Improvement |
|--------|--------|------------------|-------------|
| Cache Hit (P99) | ~50ms | ~45ms | 10% |
| Cache Miss (P99) | ~270ms | ~120-150ms | 44-56% |
| Database Queries | 3 sequential | 1 JOIN | 66% reduction |

## How to Apply

1. **Rebuild and restart services:**
   ```bash
   docker-compose build restaurant-menu-service
   docker-compose restart restaurant-menu-service
   ```

2. **Apply database indexes** (if not already applied):
   ```bash
   # Connect to PostgreSQL
   docker-compose exec postgres psql -U postgres -d food_delivery
   
   # Run the index creation statements from infra/postgres/init.sql
   ```

3. **Optional: Adjust connection pool size** in `.env`:
   ```env
   DB_POOL_MAX=50
   ```

4. **Re-run performance test:**
   ```bash
   node scripts/performance-test-menu.js --direct --concurrent 100 --requests 2000
   ```

## Monitoring

Check service logs to verify:
- Database query times (should see `duration=Xms` in logs)
- Cache hit rates (should be high after warmup)
- Connection pool usage

## Additional Recommendations

If P99 is still above 200ms after these optimizations:

1. **Increase Redis connection pool** if Redis is a bottleneck
2. **Consider connection pooling at Redis level** (ioredis supports this)
3. **Add query result caching** for frequently accessed restaurants
4. **Consider read replicas** for database if write load is high
5. **Profile with APM tools** (e.g., New Relic, Datadog) to identify remaining bottlenecks
