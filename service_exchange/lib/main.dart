import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/env.dart';
import 'screens/auth_gate.dart';
import 'screens/booking_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hkkovrlwlaxgakdnnopc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhra292cmx3bGF4Z2FrZG5ub3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTYyMDYzNzcsImV4cCI6MjAzMTc4MjM3N30.FJyn4Tp52Jk3sC6OR81K2iwU6bBFoOML6P55UmbX6e4',
  );

  // Ensure the database is properly initialized before proceeding
  try {
    // Check if the tables exist by querying the information schema
    final result =
        await Supabase.instance.client.rpc('check_tables_exist').select();

    print('Database initialization check: $result');
  } catch (e) {
    print('Error checking database initialization: $e');
    // Create the RPC function if it doesn't exist
    try {
      await Supabase.instance.client.rpc('create_check_tables_function');
    } catch (e) {
      print('Could not create the check function: $e');
    }

    // Create basic tables if they don't exist
    try {
      // Add a simple profiles table if it doesn't exist
      await Supabase.instance.client.rpc('create_minimal_tables');
    } catch (e) {
      print('Could not create minimal tables: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),
        '/bookings': (context) => const BookingHistoryScreen(),
        '/profile/edit': (context) => ProfileEditScreen(
              userProfile:
                  ModalRoute.of(context)!.settings.arguments as UserProfile,
            ),
      },
    );
  }
}
