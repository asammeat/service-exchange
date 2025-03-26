import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  factory ServiceLocation.mock(String id) {
    return ServiceLocation(
      id: id,
      title: _mockTitles[int.parse(id) % _mockTitles.length],
      description: _mockDescriptions[int.parse(id) % _mockDescriptions.length],
      latitude: 37.4219983 + (double.parse(id) * 0.01), // Around Google HQ
      longitude: -122.0839 + (double.parse(id) * 0.01),
      serviceType: int.parse(id) % 2 == 0 ? 'quest' : 'service',
      coinPrice: int.parse(id) % 2 == 0 ? 0 : (int.parse(id) % 5) * 50 + 100,
      providerName: _mockProviders[int.parse(id) % _mockProviders.length],
      imageUrl: 'https://picsum.photos/500/300?random=$id',
      createdAt: DateTime.now().subtract(Duration(days: int.parse(id) % 30)),
    );
  }

  // Generate a list of mock service locations
  static List<ServiceLocation> generateMockLocations(int count) {
    return List.generate(
      count,
      (index) => ServiceLocation.mock(index.toString()),
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
  ];
}
