-- Enable PostGIS extension for geospatial functionality
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create service_locations table
CREATE TABLE IF NOT EXISTS service_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  provider_id UUID NOT NULL REFERENCES profiles(id),
  provider_name TEXT NOT NULL,
  address TEXT NOT NULL,
  image_url TEXT,
  location GEOGRAPHY(POINT) NOT NULL,
  rating DECIMAL(3, 1) DEFAULT 0.0,
  rating_count INTEGER DEFAULT 0,
  coin_price INTEGER NOT NULL,
  is_quest BOOLEAN DEFAULT FALSE,
  service_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on location for spatial queries
CREATE INDEX service_locations_location_idx ON service_locations USING GIST (location);

-- Set up access policies for service locations
ALTER TABLE service_locations ENABLE ROW LEVEL SECURITY;

-- Policy for any user to view service locations (they're public)
CREATE POLICY "Service locations are viewable by all users"
  ON service_locations
  FOR SELECT
  USING (true);

-- Policy for providers to create service locations
CREATE POLICY "Providers can create service locations"
  ON service_locations
  FOR INSERT
  WITH CHECK (auth.uid() = provider_id);

-- Policy for providers to update their own service locations
CREATE POLICY "Providers can update their own service locations"
  ON service_locations
  FOR UPDATE
  USING (auth.uid() = provider_id);

-- Policy for providers to delete their own service locations
CREATE POLICY "Providers can delete their own service locations"
  ON service_locations
  FOR DELETE
  USING (auth.uid() = provider_id);

-- Create function to convert lat/lng to geography point
CREATE OR REPLACE FUNCTION public.create_point_from_lat_lng(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
RETURNS GEOGRAPHY AS $$
BEGIN
  RETURN ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to calculate distance between points in meters
CREATE OR REPLACE FUNCTION public.distance_between_points(
  lat1 DOUBLE PRECISION, 
  lng1 DOUBLE PRECISION, 
  lat2 DOUBLE PRECISION, 
  lng2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  point1 GEOGRAPHY;
  point2 GEOGRAPHY;
BEGIN
  point1 := ST_SetSRID(ST_MakePoint(lng1, lat1), 4326)::GEOGRAPHY;
  point2 := ST_SetSRID(ST_MakePoint(lng2, lat2), 4326)::GEOGRAPHY;
  
  RETURN ST_Distance(point1, point2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to find services within a certain radius
CREATE OR REPLACE FUNCTION public.find_services_within_radius(
  lat DOUBLE PRECISION, 
  lng DOUBLE PRECISION, 
  radius_meters DOUBLE PRECISION,
  filter_quest BOOLEAN DEFAULT NULL
)
RETURNS SETOF service_locations AS $$
DECLARE
  user_location GEOGRAPHY;
BEGIN
  user_location := ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY;
  
  RETURN QUERY
  SELECT *
  FROM service_locations
  WHERE ST_DWithin(location, user_location, radius_meters)
    AND (filter_quest IS NULL OR is_quest = filter_quest)
  ORDER BY ST_Distance(location, user_location);
END;
$$ LANGUAGE plpgsql STABLE; 