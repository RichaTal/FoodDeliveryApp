export const SERVICE_URLS = {
  restaurantMenu: process.env.RESTAURANT_MENU_URL || 'http://restaurant-menu-service:3001',
  order: process.env.ORDER_SERVICE_URL || 'http://order-service:3002',
  driverLocation: process.env.DRIVER_LOCATION_URL || 'http://driver-location-service:3003',
  notification: process.env.NOTIFICATION_URL || 'http://notification-service:3004',
} as const;

export interface RouteConfig {
  gatewayPath: string;
  downstreamService: keyof typeof SERVICE_URLS;
  isWebSocket: boolean;
}

export const ROUTE_TABLE: RouteConfig[] = [
  { gatewayPath: '/api/restaurants', downstreamService: 'restaurantMenu', isWebSocket: false },
  { gatewayPath: '/api/orders', downstreamService: 'order', isWebSocket: false },
  { gatewayPath: '/api/drivers', downstreamService: 'driverLocation', isWebSocket: false },
  { gatewayPath: '/ws/drivers/connect', downstreamService: 'driverLocation', isWebSocket: true },
  { gatewayPath: '/ws/track', downstreamService: 'notification', isWebSocket: true },
];
