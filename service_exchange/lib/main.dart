import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/bookings_screen.dart';
import 'models/user_profile.dart';
import 'screens/env.dart'; // Import environment variables

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // The app will display mock data if the database is not accessible
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseKey,
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
