import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/bookings_screen.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // The app will display mock data if the database is not accessible
  await Supabase.initialize(
    url: 'https://svfwlvytgaodynvvkngt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2Zndsdnl0Z2FvZHludnZrbmd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE1NzUwNTQsImV4cCI6MjAyNzE1MTA1NH0.K3fOVnqm_kn5k8mWZ9s_5pzYAyUe5YU6Ro2ZXV0JwT0',
  );

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
