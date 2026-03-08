export interface OrderEvent {
  orderId: string;
  status: string;
  restaurantId?: string;
  items?: any[];
}

export interface LocationEvent {
  driverId: string;
  orderId: string;
  lat: number;
  lng: number;
  timestamp: number;
}

export type WebSocketMessageType = 'ORDER_UPDATE' | 'DRIVER_LOCATION' | 'CONNECTED';

export interface WebSocketMessage {
  type: WebSocketMessageType;
  payload: OrderEvent | LocationEvent | { orderId: string };
}

export interface SessionEntry {
  instanceId: string;
  connectedAt: number;
}
