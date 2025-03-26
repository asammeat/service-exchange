# ServiceExchange Supabase Database Structure

This directory contains SQL migrations for the ServiceExchange app. The database is structured around Supabase, with the following key tables:

## Tables

### `profiles` Table
Stores user profile information and is linked to Supabase Auth.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Primary key, linked to `auth.users` |
| email | TEXT | User's email address |
| username | TEXT | Unique username |
| full_name | TEXT | User's full name |
| bio | TEXT | User's bio or description |
| avatar_url | TEXT | URL to user's profile image |
| phone_number | TEXT | User's phone number |
| location | TEXT | User's location |
| coins | INTEGER | User's coin balance |
| is_partner_account | BOOLEAN | Whether user is a service provider |
| created_at | TIMESTAMP | When the profile was created |
| updated_at | TIMESTAMP | When the profile was last updated |

### `service_locations` Table
Stores information about services and quests available on the platform.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Primary key |
| title | TEXT | Service or quest title |
| description | TEXT | Detailed description |
| provider_id | UUID (FK) | Reference to the provider's profile |
| provider_name | TEXT | Name of the provider |
| address | TEXT | Human-readable address |
| image_url | TEXT | URL to service image |
| location | GEOGRAPHY(POINT) | Geospatial point (lat/lng) |
| rating | DECIMAL(3,1) | Average rating (0.0-5.0) |
| rating_count | INTEGER | Number of ratings |
| coin_price | INTEGER | Cost in coins |
| is_quest | BOOLEAN | Whether it's a quest (true) or service (false) |
| service_date | TIMESTAMP | When the service/quest is scheduled |
| created_at | TIMESTAMP | When the record was created |
| updated_at | TIMESTAMP | When the record was last updated |

### `service_bookings` Table
Tracks bookings made by users for services or quests.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Primary key |
| service_id | TEXT | ID of the service being booked |
| service_name | TEXT | Name of the service |
| provider_id | UUID (FK) | Reference to the provider's profile |
| provider_name | TEXT | Name of the provider |
| user_id | UUID (FK) | Reference to the user's profile |
| user_email | TEXT | User's email |
| booking_date | TIMESTAMP | When the booking was made |
| service_date | TIMESTAMP | When the service is scheduled |
| coin_price | INTEGER | Cost in coins |
| status | booking_status | Status enum: pending, confirmed, in_progress, completed, cancelled, rejected |
| notes | TEXT | Additional notes for the booking |
| is_quest | BOOLEAN | Whether it's a quest booking |
| created_at | TIMESTAMP | When the record was created |
| updated_at | TIMESTAMP | When the record was last updated |

## Security

The database uses Supabase's Row Level Security (RLS) to ensure data access is properly controlled:

1. **Profile Data**: Users can only view and modify their own profile data.
2. **Service Locations**: Anyone can view services, but only providers can create/edit their own services.
3. **Bookings**: Users can view and manage their own bookings, while providers can view and manage bookings for their services.

## Storage

A storage bucket named `avatars` is configured for storing user profile images with appropriate security policies.

## Custom Functions

Several helper functions are available:

- `create_point_from_lat_lng`: Creates a PostGIS geography point from latitude/longitude
- `distance_between_points`: Calculates distance between two lat/lng points in meters
- `find_services_within_radius`: Finds services within a specified radius of a location

## Triggers

Automated triggers handle these scenarios:

1. **New User Registration**: Automatically creates a profile record for new Supabase Auth users
2. **Booking Status Changes**: Updates coin balances when bookings are created, completed, or cancelled

## How to Apply Migrations

To apply these migrations to your Supabase project:

1. Log in to your Supabase dashboard
2. Navigate to the SQL editor
3. Copy and paste each migration file in order (profiles → service_locations → service_bookings)
4. Run the SQL and check for any errors

Note: Make sure to enable the PostGIS extension in your Supabase project before running migrations. 