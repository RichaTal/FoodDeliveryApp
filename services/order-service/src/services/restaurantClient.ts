/**
 * Restaurant Service API Client
 * Handles communication with restaurant-menu-service
 */

import type { Restaurant, FullMenu, MenuItem } from '../types/index.js';

const RESTAURANT_SERVICE_URL =
  process.env['RESTAURANT_SERVICE_URL'] || 'http://restaurant-menu-service:3001';

interface RestaurantServiceResponse<T> {
  data: T;
}

interface RestaurantServiceError {
  error: string;
}

/**
 * Get restaurant by ID
 */
export async function getRestaurant(restaurantId: string): Promise<Restaurant | null> {
  try {
    const response = await fetch(`${RESTAURANT_SERVICE_URL}/restaurants/${restaurantId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      const error: RestaurantServiceError = await response.json();
      throw new Error(`Restaurant service error: ${error.error || response.statusText}`);
    }

    const result: RestaurantServiceResponse<Restaurant> = await response.json();
    return result.data;
  } catch (error) {
    const err = error as Error;
    // If it's a network error, wrap it
    if (err.message.includes('fetch')) {
      throw new Error(`Failed to connect to restaurant service: ${err.message}`);
    }
    throw err;
  }
}

/**
 * Get full menu for a restaurant (includes restaurant info and all menu items)
 */
export async function getRestaurantMenu(restaurantId: string): Promise<FullMenu | null> {
  try {
    const response = await fetch(`${RESTAURANT_SERVICE_URL}/restaurants/${restaurantId}/menu`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      const error: RestaurantServiceError = await response.json();
      throw new Error(`Restaurant service error: ${error.error || response.statusText}`);
    }

    const result: RestaurantServiceResponse<FullMenu> = await response.json();
    return result.data;
  } catch (error) {
    const err = error as Error;
    // If it's a network error, wrap it
    if (err.message.includes('fetch')) {
      throw new Error(`Failed to connect to restaurant service`);
    }
    throw err;
  }
}

/**
 * Extract all menu items from a FullMenu response
 */
export function extractMenuItems(menu: FullMenu): MenuItem[] {
  const items: MenuItem[] = [];
  for (const category of menu.categories) {
    items.push(...category.items);
  }
  return items;
}
