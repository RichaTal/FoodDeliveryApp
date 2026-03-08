export interface Driver {
  id: string;
  name: string;
  phone: string;
  vehicle: string;
  is_active: boolean;
  created_at: Date;
}

export interface GpsPing {
  driverId: string;
  lat: number;
  lng: number;
  timestamp: number;
}

export interface DriverLocation {
  driverId: string;
  lat: number;
  lng: number;
}

export interface NearbyDriversQuery {
  lat: number;
  lng: number;
  radius: number; // km
}
