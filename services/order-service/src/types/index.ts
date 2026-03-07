export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  PREPARING = 'PREPARING',
  PICKED_UP = 'PICKED_UP',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
}

export interface CreateOrderBody {
  restaurantId: string;
  items: Array<{
    menuItemId: string;
    quantity: number;
  }>;
}

export interface OrderItem {
  id: string;
  order_id: string;
  menu_item_id: string;
  name: string;
  price_at_time: number;
  quantity: number;
}

export interface Order {
  id: string;
  restaurant_id: string;
  driver_id: string | null;
  status: OrderStatus;
  total_amount: number;
  payment_status: PaymentStatus;
  payment_txn_id: string | null;
  created_at: Date;
  updated_at: Date;
  items?: OrderItem[];
}

export interface PaymentResult {
  success: boolean;
  transactionId: string;
}

export class RestaurantNotAvailableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RestaurantNotAvailableError';
  }
}

export class MenuItemNotAvailableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MenuItemNotAvailableError';
  }
}

export class PaymentFailedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PaymentFailedError';
  }
}

export class InvalidStatusTransitionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'InvalidStatusTransitionError';
  }
}

// Restaurant service types
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