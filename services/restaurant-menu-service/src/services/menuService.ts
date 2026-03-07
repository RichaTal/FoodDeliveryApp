import { query } from '../config/db.js';
import redisClient from '../config/redis.js';
import type {
  Restaurant,
  MenuCategory,
  MenuItem,
  FullMenu,
  CreateRestaurantPayload,
  UpdateMenuItemPayload,
} from '../types/index.js';

const MENU_TTL = 60;         // seconds
const RESTAURANTS_TTL = 30;  // seconds

// ── Cache helpers ────────────────────────────────────────────────────────────

async function redisGet(key: string): Promise<string | null> {
  try {
    return await redisClient.get(key);
  } catch (err) {
    // Silently fail - cache is optional, no logging to avoid performance overhead
    return null;
  }
}

async function redisSet(key: string, value: string, ttl: number): Promise<void> {
  try {
    await redisClient.set(key, value, 'EX', ttl);
  } catch (err) {
    // Silently fail - cache is optional, no logging to avoid performance overhead
  }
}

async function redisDel(key: string): Promise<void> {
  try {
    await redisClient.del(key);
  } catch (err) {
    // Silently fail - cache is optional, no logging to avoid performance overhead
  }
}

// ── getFullMenu ──────────────────────────────────────────────────────────────

export async function getFullMenu(
  restaurantId: string,
): Promise<{ menu: FullMenu | null; cacheHit: boolean }> {
  const cacheKey = `menu:${restaurantId}`;

  // 1. Try cache
  const cached = await redisGet(cacheKey);
  if (cached !== null) {
    // Use fast JSON parsing - V8's JSON.parse is already optimized, but we ensure it's synchronous
    try {
      const menu = JSON.parse(cached) as FullMenu;
      return { menu, cacheHit: true };
    } catch (parseErr) {
      // If cache is corrupted, invalidate it and fall through to DB query
      await redisDel(cacheKey).catch(() => {});
      // Fall through to DB query
    }
  }

  // 2. Cache MISS — query DB using optimized single query with JOINs
  // This is faster than 3 separate queries, especially with proper indexes
  type QueryRow = {
    id: string;
    name: string;
    address: string;
    lat: number;
    lng: number;
    is_open: boolean;
    created_at: Date;
    updated_at: Date;
    category_id: string | null;
    category_name: string | null;
    display_order: number | null;
    item_id: string | null;
    item_name: string | null;
    description: string | null;
    price: number | null;
    is_available: boolean | null;
  };

  const result = await query<QueryRow>(
    `SELECT 
      r.id, r.name, r.address, r.lat, r.lng, r.is_open, r.created_at, r.updated_at,
      c.id AS category_id, c.name AS category_name, c.display_order,
      m.id AS item_id, m.name AS item_name, m.description, m.price, m.is_available
    FROM restaurants r
    LEFT JOIN menu_categories c ON c.restaurant_id = r.id
    LEFT JOIN menu_items m ON m.restaurant_id = r.id AND m.category_id = c.id
    WHERE r.id = $1
    ORDER BY c.display_order NULLS LAST, c.id, m.id`,
    [restaurantId],
  );

  if (result.rowCount === 0) {
    return { menu: null, cacheHit: false };
  }

  // Extract restaurant data (same for all rows)
  const firstRow = result.rows[0]!;
  const restaurant: Restaurant = {
    id: firstRow.id,
    name: firstRow.name,
    address: firstRow.address,
    lat: firstRow.lat,
    lng: firstRow.lng,
    is_open: firstRow.is_open,
    created_at: firstRow.created_at,
    updated_at: firstRow.updated_at,
  };

  // Group categories and items
  const categoriesMap = new Map<string, MenuCategory & { items: MenuItem[] }>();
  
  for (const row of result.rows) {
    // Skip if no category (restaurant exists but has no categories)
    if (!row.category_id) continue;
    
    if (!categoriesMap.has(row.category_id)) {
      categoriesMap.set(row.category_id, {
        id: row.category_id,
        restaurant_id: restaurantId,
        name: row.category_name!,
        display_order: row.display_order!,
        items: [],
      });
    }
    
    // Add menu item if present
    if (row.item_id) {
      const category = categoriesMap.get(row.category_id)!;
      category.items.push({
        id: row.item_id,
        category_id: row.category_id,
        restaurant_id: restaurantId,
        name: row.item_name!,
        description: row.description,
        price: row.price!,
        is_available: row.is_available!,
      });
    }
  }

  // Categories are already ordered by SQL ORDER BY clause, Map preserves insertion order
  const menu: FullMenu = {
    restaurant,
    categories: Array.from(categoriesMap.values()),
  };

  // 3. Populate cache (don't await - fire and forget for better performance)
  redisSet(cacheKey, JSON.stringify(menu), MENU_TTL).catch(() => {
    // Silently fail - cache is optional
  });

  return { menu, cacheHit: false };
}

// ── invalidateMenuCache ──────────────────────────────────────────────────────

export async function invalidateMenuCache(restaurantId: string): Promise<void> {
  await redisDel(`menu:${restaurantId}`);
}

// ── getAllRestaurants ────────────────────────────────────────────────────────

export async function getAllRestaurants(): Promise<Restaurant[]> {
  try{
    const cacheKey = 'restaurants:list';

    const cached = await redisGet(cacheKey);
    if (cached !== null) {
      return JSON.parse(cached) as Restaurant[];
    }
  
    const result = await query<Restaurant>(
      'SELECT id, name, address, lat, lng, is_open, created_at, updated_at FROM restaurants ORDER BY name',
    );
  
    await redisSet(cacheKey, JSON.stringify(result.rows), RESTAURANTS_TTL);
    console.log('result.rows', result.rows);
    return result.rows;
  } catch (error) {
    console.log('Error getAllRestaurants', error);
    throw error;
  }
 
}

// ── getRestaurantById ────────────────────────────────────────────────────────

export async function getRestaurantById(restaurantId: string): Promise<Restaurant | null> {
  const result = await query<Restaurant>(
    'SELECT id, name, address, lat, lng, is_open, created_at, updated_at FROM restaurants WHERE id = $1',
    [restaurantId],
  );

  if (result.rows.length === 0) {
    return null;
  }

  return result.rows[0]!;
}

// ── getRestaurantCount ───────────────────────────────────────────────────────

export async function getRestaurantCount(): Promise<number> {
  const result = await query<{ count: string }>(
    'SELECT COUNT(*) as count FROM restaurants',
  );

  const count = parseInt(result.rows[0]!.count, 10);
  return count;
}

// ── createRestaurant ─────────────────────────────────────────────────────────

export async function createRestaurant(data: CreateRestaurantPayload): Promise<Restaurant> {
  const { name, address, lat, lng, is_open = true } = data;

  const result = await query<Restaurant>(
    `INSERT INTO restaurants (name, address, lat, lng, is_open)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, name, address, lat, lng, is_open, created_at, updated_at`,
    [name, address, lat, lng, is_open],
  );

  await redisDel('restaurants:list');

  return result.rows[0]!;
}

// ── updateMenuItem ───────────────────────────────────────────────────────────

export async function updateMenuItem(
  restaurantId: string,
  itemId: string,
  data: UpdateMenuItemPayload,
): Promise<MenuItem | null> {
  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (data.name !== undefined) { fields.push(`name = $${idx++}`); values.push(data.name); }
  if (data.description !== undefined) { fields.push(`description = $${idx++}`); values.push(data.description); }
  if (data.price !== undefined) { fields.push(`price = $${idx++}`); values.push(data.price); }
  if (data.is_available !== undefined) { fields.push(`is_available = $${idx++}`); values.push(data.is_available); }

  if (fields.length === 0) return null;

  values.push(itemId, restaurantId);

  const result = await query<MenuItem>(
    `UPDATE menu_items
     SET ${fields.join(', ')}, updated_at = NOW()
     WHERE id = $${idx++} AND restaurant_id = $${idx++}
     RETURNING id, category_id, restaurant_id, name, description, price, is_available`,
    values,
  );

  if (result.rowCount === 0) return null;

  await invalidateMenuCache(restaurantId);
  return result.rows[0]!;
}
