import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ServiceLocation {
  final String id;
  final String title;
  final String description;
  final String providerId;
  final String providerName;
  final String address;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final int ratingCount;
  final int coinPrice;
  final bool isQuest;
  final DateTime? date;

  ServiceLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.providerId,
    required this.providerName,
    required this.address,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.ratingCount,
    required this.coinPrice,
    required this.isQuest,
    this.date,
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
      providerId: DateTime.now().millisecondsSinceEpoch.toString(),
      providerName: _mockProviders[idNum % _mockProviders.length],
      address: _mockAddresses[idNum % _mockAddresses.length],
      imageUrl: 'https://picsum.photos/500/300?random=$id',
      latitude: lat,
      longitude: lng,
      rating: 4.5 + (idNum % 1.0),
      ratingCount: 10 + DateTime.now().second,
      coinPrice: idNum % 2 == 0 ? 0 : (idNum % 5) * 50 + 100,
      isQuest: idNum % 2 == 0,
      date: DateTime.now().subtract(Duration(days: idNum % 30)),
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

  static final List<String> _mockAddresses = [
    '123 Main St, New York, NY 10001',
    '456 Elm St, Brooklyn, NY 11201',
    '789 Oak St, Queens, NY 11354',
    '101 Pine St, Bronx, NY 10451',
    '222 Cedar St, Staten Island, NY 10301',
  ];

  // Create a mock service location from card data
  factory ServiceLocation.fromCardData({
    required String title,
    required String organization,
    required String location,
    required double rating,
    required String imageUrl,
    required DateTime? date,
    required String description,
    required bool isQuest,
    required int coinPrice,
  }) {
    return ServiceLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      providerId: DateTime.now().millisecondsSinceEpoch.toString(),
      providerName: organization,
      address: location,
      imageUrl: imageUrl,
      latitude: 37.7749, // Mock coordinates (San Francisco)
      longitude: -122.4194,
      rating: rating,
      ratingCount: 10 + DateTime.now().second, // Random rating count
      coinPrice: coinPrice,
      isQuest: isQuest,
      date: date,
    );
  }

  // Factory constructor to create a service location from JSON data
  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      address: json['address'],
      imageUrl: json['image_url'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      rating: json['rating'].toDouble(),
      ratingCount: json['rating_count'],
      coinPrice: json['coin_price'],
      isQuest: json['is_quest'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  // Convert service location to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider_id': providerId,
      'provider_name': providerName,
      'address': address,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'rating_count': ratingCount,
      'coin_price': coinPrice,
      'is_quest': isQuest,
      'date': date?.toIso8601String(),
    };
  }
}
