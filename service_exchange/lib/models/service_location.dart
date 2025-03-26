import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class ServiceLocation {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String serviceType; // "quest" or "service"
  final int coinPrice;
  final String providerName;
  final String imageUrl;
  final DateTime createdAt;

  ServiceLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.serviceType,
    required this.coinPrice,
    required this.providerName,
    required this.imageUrl,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  // Factory constructor to create mock data
  factory ServiceLocation.mock(String id, {LatLng? centerLocation}) {
    // Use either provided center location or a default location (NYC)
    final center = centerLocation ?? const LatLng(40.7128, -74.0060);

    // Create a more distributed pattern of locations around the center
    // Use the id to create a deterministic but varied pattern
    final idNum = int.parse(id);
    final angle = (idNum * 30) % 360 * (math.pi / 180); // Convert to radians
    final radius =
        0.01 + (idNum % 5) * 0.005; // Varies the distance from center

    // Calculate coordinates in a circular pattern around the center
    final lat = center.latitude + radius * math.cos(angle);
    final lng = center.longitude + radius * math.sin(angle);

    return ServiceLocation(
      id: id,
      title: _mockTitles[idNum % _mockTitles.length],
      description: _mockDescriptions[idNum % _mockDescriptions.length],
      latitude: lat,
      longitude: lng,
      serviceType: idNum % 2 == 0 ? 'quest' : 'service',
      coinPrice: idNum % 2 == 0 ? 0 : (idNum % 5) * 50 + 100,
      providerName: _mockProviders[idNum % _mockProviders.length],
      imageUrl: 'https://picsum.photos/500/300?random=$id',
      createdAt: DateTime.now().subtract(Duration(days: idNum % 30)),
    );
  }

  // Generate a list of mock service locations
  static List<ServiceLocation> generateMockLocations(int count,
      {LatLng? centerLocation}) {
    return List.generate(
      count,
      (index) => ServiceLocation.mock(index.toString(),
          centerLocation: centerLocation),
    );
  }

  // Mock data for generating random services
  static final List<String> _mockTitles = [
    'Home Cleaning Service',
    'Dog Walking Quest',
    'Furniture Assembly',
    'Community Gardening Quest',
    'Mobile Phone Repair',
    'Computer Tutoring',
    'Local Food Delivery',
    'Senior Support Quest',
    'Plumbing Services',
    'Pet Sitting',
    'Math Tutoring Service',
    'Beach Cleanup Quest',
    'Lawn Mowing Service',
    'Car Wash & Detailing',
    'Language Exchange Quest',
  ];

  static final List<String> _mockDescriptions = [
    'Professional home cleaning services with eco-friendly products.',
    'Help walk dogs from the local shelter for exercise and socialization.',
    'Expert assembly of all types of furniture, including IKEA.',
    'Join us in cleaning and maintaining the neighborhood community garden.',
    'Screen, battery, and component replacement for all phone brands.',
    'One-on-one computer and software tutoring for all skill levels.',
    'Delivery of meals and groceries from local businesses to your door.',
    'Help seniors with technology, errands, and companionship.',
    'Fixing leaks, installations, and plumbing emergencies.',
    'In-home pet care while you\'re away, including feeding and walks.',
    'Private tutoring for algebra, calculus, and statistics.',
    'Help clean up our local beaches and protect marine life.',
    'Professional lawn care, mowing, and garden maintenance.',
    'Full car cleaning service with interior and exterior detailing.',
    'Practice conversational skills in different languages.',
  ];

  static final List<String> _mockProviders = [
    'CleanHome Co.',
    'PetLovers Community',
    'HandyFix Services',
    'Green Thumb Collective',
    'TechRepair Pros',
    'Digital Tutors Inc.',
    'QuickBite Delivery',
    'Helping Hands Network',
    'PlumbRight Solutions',
    'PetPals Services',
    'BrainBoost Education',
    'EcoWarriors Group',
    'GreenLawn Experts',
    'SparkleWash Auto',
    'GlobalTalk Community',
  ];
}
