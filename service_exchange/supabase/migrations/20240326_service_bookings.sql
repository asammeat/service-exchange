-- Create enum for booking status
CREATE TYPE booking_status AS ENUM (
  'pending',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'rejected'
);

-- Create service_bookings table
CREATE TABLE IF NOT EXISTS service_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_id TEXT NOT NULL,
  service_name TEXT NOT NULL,
  provider_id UUID NOT NULL REFERENCES profiles(id),
  provider_name TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  user_email TEXT NOT NULL,
  booking_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  service_date TIMESTAMP WITH TIME ZONE NOT NULL,
  coin_price INTEGER NOT NULL,
  status booking_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  is_quest BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set up access policies for bookings
ALTER TABLE service_bookings ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own bookings
CREATE POLICY "Users can view their own bookings"
  ON service_bookings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy for service providers to view bookings for their services
CREATE POLICY "Providers can view bookings for their services"
  ON service_bookings
  FOR SELECT
  USING (auth.uid() = provider_id);

-- Policy for users to create bookings
CREATE POLICY "Users can create bookings"
  ON service_bookings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy for users to update their own bookings
CREATE POLICY "Users can update their own bookings"
  ON service_bookings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy for service providers to update bookings for their services
CREATE POLICY "Providers can update bookings for their services"
  ON service_bookings
  FOR UPDATE
  USING (auth.uid() = provider_id);

-- Create function to update user coins on booking
CREATE OR REPLACE FUNCTION update_user_coins_on_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- For new bookings, deduct coins from user if it's a paid service
  IF TG_OP = 'INSERT' AND NEW.coin_price > 0 AND NEW.is_quest = FALSE THEN
    -- Deduct coins from user
    UPDATE profiles
    SET coins = coins - NEW.coin_price
    WHERE id = NEW.user_id;
  END IF;

  -- For status updates to completed
  IF TG_OP = 'UPDATE' AND OLD.status != 'completed' AND NEW.status = 'completed' THEN
    IF NEW.is_quest = TRUE THEN
      -- Add coins to user for completing a quest
      UPDATE profiles
      SET coins = coins + (CASE WHEN NEW.coin_price = 0 THEN 50 ELSE NEW.coin_price END)
      WHERE id = NEW.user_id;
    ELSE
      -- Add coins to provider for completing a service
      UPDATE profiles
      SET coins = coins + NEW.coin_price
      WHERE id = NEW.provider_id;
    END IF;
  END IF;

  -- For cancelled bookings, refund coins to user if it was a paid service
  IF TG_OP = 'UPDATE' AND OLD.status != 'cancelled' AND NEW.status = 'cancelled' THEN
    IF NEW.coin_price > 0 AND NEW.is_quest = FALSE THEN
      -- Refund coins to user
      UPDATE profiles
      SET coins = coins + NEW.coin_price
      WHERE id = NEW.user_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for booking status changes affecting coins
DROP TRIGGER IF EXISTS on_booking_status_change ON service_bookings;
CREATE TRIGGER on_booking_status_change
  AFTER INSERT OR UPDATE OF status ON service_bookings
  FOR EACH ROW EXECUTE FUNCTION update_user_coins_on_booking(); 