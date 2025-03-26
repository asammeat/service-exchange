# ServiceExchange App

ServiceExchange is a full-stack mobile application that connects users with local services and community quests.

## Project Structure

This repository contains both frontend and backend components:

- **Frontend**: Flutter-based mobile application with Google Maps integration
- **Backend**: Node.js with Express for additional business logic
- **Database**: Supabase for authentication, database, and storage

## Features

- User authentication with Supabase
- Service/Quest marketplace with feed and map views
- User profiles with transaction history
- Different account types (Regular user, Partner)
- Location-based service discovery
- QR code scanning functionality
- In-app notification system
- Service creation and management

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js 
- Supabase account and API keys
- Google Maps API key

### Installation

1. Clone the repository:
```
git clone https://github.com/yourusername/service-exchange.git
```

2. Install frontend dependencies:
```
cd service_exchange
flutter pub get
```

3. Install backend dependencies:
```
cd backend
npm install
```

4. Set up environment variables:
   - Create a `.env` file in the backend directory
   - Set up your Supabase and Google Maps API keys

5. Run the app:
```
cd service_exchange
flutter run
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 