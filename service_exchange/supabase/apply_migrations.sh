#!/bin/bash

# This script helps in applying the Supabase migrations to your project
# You will need to have the Supabase CLI installed and be logged in
# You can install it via: npm install -g supabase

# Set your Supabase project reference - replace with your project reference
# You can find this in the Supabase dashboard settings
SUPABASE_PROJECT_REF="hkkovrlwlaxgakdnnopc"

echo "=== ServiceExchange Database Migration Script ==="
echo "This script will apply migrations in the correct order to your Supabase project."
echo "Before proceeding, make sure you have:"
echo "1. Created a Supabase project"
echo "2. Installed the Supabase CLI"
echo "3. Logged in to Supabase CLI using 'supabase login'"
echo ""
echo "You can also apply these migrations manually through the Supabase Dashboard SQL Editor."
echo ""

# Function to apply a migration
apply_migration() {
  local file=$1
  local description=$2
  
  echo "Applying migration: $description"
  echo "File: $file"
  
  # If Supabase CLI is available and project ref is set
  if [ "$SUPABASE_PROJECT_REF" != "YOUR_PROJECT_REF" ] && command -v supabase &> /dev/null; then
    supabase db push -p $SUPABASE_PROJECT_REF --db-file $file
    if [ $? -eq 0 ]; then
      echo "✅ Migration applied successfully"
    else
      echo "❌ Migration failed"
      exit 1
    fi
  else
    echo "⚠️ Supabase CLI not configured. Please apply migrations manually:"
    echo "1. Go to your Supabase dashboard: https://app.supabase.io"
    echo "2. Navigate to the SQL Editor"
    echo "3. Copy and paste the contents of $file"
    echo "4. Execute the SQL"
    echo ""
    cat $file
    echo ""
    read -p "Press Enter to continue to the next migration..."
  fi
  
  echo ""
}

# Apply migrations in correct order
echo "Step 1: Enable PostGIS extension"
echo "Make sure to enable the PostGIS extension in your Supabase project before proceeding."
read -p "Press Enter when ready to continue..."

apply_migration "migrations/20240326_profiles.sql" "Creating profiles table and related functions"
apply_migration "migrations/20240326_service_locations.sql" "Creating service_locations table and geospatial functions"
apply_migration "migrations/20240326_service_bookings.sql" "Creating service_bookings table and trigger functions"

echo "=== Migration Complete ==="
echo "If there were no errors, your database should now be set up correctly."
echo "You can verify the tables in the Supabase Dashboard Table Editor."
echo ""
echo "If you encounter any issues in your application, check the database schema and make sure it matches the expected structure." 