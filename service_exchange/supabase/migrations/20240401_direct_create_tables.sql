-- Function to check if tables exist
CREATE OR REPLACE FUNCTION check_tables_exist()
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'profiles_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles'),
    'service_locations_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_locations'),
    'service_bookings_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_bookings')
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create the check tables function if it doesn't exist
CREATE OR REPLACE FUNCTION create_check_tables_function()
RETURNS text AS $$
BEGIN
  -- This creates the check_tables_exist function (useful when it doesn't exist yet)
  EXECUTE $EXEC$
  CREATE OR REPLACE FUNCTION check_tables_exist()
  RETURNS jsonb AS $INNER$
  DECLARE
    result jsonb;
  BEGIN
    SELECT jsonb_build_object(
      'profiles_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles'),
      'service_locations_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_locations'),
      'service_bookings_exists', EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_bookings')
    ) INTO result;
    
    RETURN result;
  END;
  $INNER$ LANGUAGE plpgsql SECURITY DEFINER;
  $EXEC$;
  
  RETURN 'check_tables_exist function created';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create minimal tables required for the app to function
CREATE OR REPLACE FUNCTION create_minimal_tables()
RETURNS text AS $$
DECLARE
  profiles_exists boolean;
  service_locations_exists boolean;
  service_bookings_exists boolean;
BEGIN
  -- Check if tables exist first
  SELECT 
    EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles'),
    EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_locations'),
    EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_bookings')
  INTO profiles_exists, service_locations_exists, service_bookings_exists;

  -- Create extension if not exists
  CREATE EXTENSION IF NOT EXISTS postgis;
  
  -- Create profiles table if it doesn't exist
  IF NOT profiles_exists THEN
    CREATE TABLE public.profiles (
      id UUID REFERENCES auth.users PRIMARY KEY,
      email TEXT,
      username TEXT UNIQUE,
      full_name TEXT,
      bio TEXT,
      avatar_url TEXT,
      phone_number TEXT,
      location TEXT,
      coins INTEGER DEFAULT 0,
      is_partner_account BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Set up RLS
    ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
    
    -- Policy for users to view their own profile
    CREATE POLICY "Users can view their own profile"
      ON public.profiles
      FOR SELECT
      USING (auth.uid() = id);
    
    -- Policy for users to update their own profile
    CREATE POLICY "Users can update their own profile"
      ON public.profiles
      FOR UPDATE
      USING (auth.uid() = id);
    
    -- Policy for profiles to be created for new users
    CREATE POLICY "Profiles can be created by authenticated users"
      ON public.profiles
      FOR INSERT
      WITH CHECK (auth.uid() = id);

    -- Function to handle new user creation
    CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS TRIGGER AS $$
    BEGIN
      INSERT INTO public.profiles (id, email, username)
      VALUES (
        NEW.id,
        NEW.email,
        'user_' || substr(NEW.id::text, 1, 8)
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Trigger to create profile on user creation
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
  
  -- Create booking status enum if it doesn't exist
  DROP TYPE IF EXISTS booking_status CASCADE;
  CREATE TYPE booking_status AS ENUM (
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'rejected'
  );

  -- Create service_locations table if it doesn't exist
  IF NOT service_locations_exists THEN
    CREATE TABLE public.service_locations (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      provider_id UUID NOT NULL REFERENCES profiles(id),
      provider_name TEXT NOT NULL,
      address TEXT NOT NULL,
      image_url TEXT,
      location GEOGRAPHY(POINT),
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      rating DECIMAL(3, 1) DEFAULT 0.0,
      rating_count INTEGER DEFAULT 0,
      coin_price INTEGER NOT NULL,
      is_quest BOOLEAN DEFAULT FALSE,
      service_date TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Set up RLS for service locations
    ALTER TABLE public.service_locations ENABLE ROW LEVEL SECURITY;
    
    -- Policy for any user to view service locations (they're public)
    CREATE POLICY "Service locations are viewable by all users"
      ON public.service_locations
      FOR SELECT
      USING (true);
    
    -- Policy for providers to create service locations
    CREATE POLICY "Providers can create service locations"
      ON public.service_locations
      FOR INSERT
      WITH CHECK (auth.uid() = provider_id);
    
    -- Policy for providers to update their own service locations
    CREATE POLICY "Providers can update their own service locations"
      ON public.service_locations
      FOR UPDATE
      USING (auth.uid() = provider_id);
    
    -- Policy for providers to delete their own service locations
    CREATE POLICY "Providers can delete their own service locations"
      ON public.service_locations
      FOR DELETE
      USING (auth.uid() = provider_id);
  END IF;
  
  -- Create service_bookings table if it doesn't exist
  IF NOT service_bookings_exists THEN
    CREATE TABLE public.service_bookings (
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
    
    -- Set up RLS for bookings
    ALTER TABLE public.service_bookings ENABLE ROW LEVEL SECURITY;
    
    -- Policy for users to view their own bookings
    CREATE POLICY "Users can view their own bookings"
      ON public.service_bookings
      FOR SELECT
      USING (auth.uid() = user_id);
    
    -- Policy for service providers to view bookings for their services
    CREATE POLICY "Providers can view bookings for their services"
      ON public.service_bookings
      FOR SELECT
      USING (auth.uid() = provider_id);
    
    -- Policy for users to create bookings
    CREATE POLICY "Users can create bookings"
      ON public.service_bookings
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);
    
    -- Policy for users to update their own bookings
    CREATE POLICY "Users can update their own bookings"
      ON public.service_bookings
      FOR UPDATE
      USING (auth.uid() = user_id);
    
    -- Policy for service providers to update bookings for their services
    CREATE POLICY "Providers can update bookings for their services"
      ON public.service_bookings
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
    DROP TRIGGER IF EXISTS on_booking_status_change ON public.service_bookings;
    CREATE TRIGGER on_booking_status_change
      AFTER INSERT OR UPDATE OF status ON public.service_bookings
      FOR EACH ROW EXECUTE FUNCTION update_user_coins_on_booking();
  END IF;
  
  -- Create point conversion function
  CREATE OR REPLACE FUNCTION create_point_from_lat_lng(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
  RETURNS GEOGRAPHY AS $$
  BEGIN
    RETURN ST_SetSRID(ST_MakePoint(lng, lat), 4326)::GEOGRAPHY;
  END;
  $$ LANGUAGE plpgsql IMMUTABLE;

  RETURN 'Tables created successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 