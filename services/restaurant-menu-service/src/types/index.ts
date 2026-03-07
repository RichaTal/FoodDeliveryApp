export interface Restaurant {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  is_open: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface MenuCategory {
  id: string;
  restaurant_id: string;
  name: string;
  display_order: number;
}

export interface MenuItem {
  id: string;
  category_id: string;
  restaurant_id: string;
  name: string;
  description: string;
  price: number;
  is_available: boolean;
}

export interface FullMenu {
  restaurant: Restaurant;
  categories: Array<MenuCategory & { items: MenuItem[] }>;
}

// Payload types for mutations
export interface CreateRestaurantPayload {
  name: string;
  address: string;
  lat: number;
  lng: number;
  is_open?: boolean;
}

export interface UpdateMenuItemPayload {
  name?: string;
  description?: string;
  price?: number;
  is_available?: boolean;
}
