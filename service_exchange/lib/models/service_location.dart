import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceLocation {
  final String id;
  final String title;
  final String description;
  final String providerId;
  final String providerName;
  final String address;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final int ratingCount;
  final int coinPrice;
  final bool isQuest;
  final DateTime? serviceDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.providerId,
    required this.providerName,
    required this.address,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.ratingCount,
    required this.coinPrice,
    required this.isQuest,
    this.serviceDate,
    this.createdAt,
    this.updatedAt,
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
      serviceDate: DateTime.now().subtract(Duration(days: idNum % 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      serviceDate: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Factory constructor to create a service location from JSON data
  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double latitude = 0.0;
    double longitude = 0.0;

    // Extract lat/lng from the PostGIS geography point
    if (location != null) {
      // The format from PostGIS is typically 'POINT(lng lat)'
      final String pointStr = location.toString();
      if (pointStr.startsWith('POINT')) {
        final coords =
            pointStr.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
        if (coords.length == 2) {
          try {
            longitude = double.parse(coords[0]);
            latitude = double.parse(coords[1]);
          } catch (e) {
            print('Error parsing coordinates: $e');
          }
        }
      }
    }

    return ServiceLocation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      address: json['address'],
      imageUrl: json['image_url'],
      latitude: latitude,
      longitude: longitude,
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      coinPrice: json['coin_price'] ?? 0,
      isQuest: json['is_quest'] ?? false,
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert service location to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'provider_id': providerId,
      'provider_name': providerName,
      'address': address,
      'image_url': imageUrl,
      // We'll use a DB function to create the point
      'location': null, // This will be handled with the function call
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'rating_count': ratingCount,
      'coin_price': coinPrice,
      'is_quest': isQuest,
      'service_date': serviceDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Fetch all services
  static Future<List<ServiceLocation>> getAllServices({bool? isQuest}) async {
    try {
      final query = Supabase.instance.client.from('service_locations').select();

      if (isQuest != null) {
        query.eq('is_quest', isQuest);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map<ServiceLocation>((json) => ServiceLocation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching services: $e');
      throw Exception('Failed to load services');
    }
  }

  // Fetch services by provider ID
  static Future<List<ServiceLocation>> getServicesByProvider(
      String providerId) async {
    try {
      final response = await Supabase.instance.client
          .from('service_locations')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map<ServiceLocation>((json) => ServiceLocation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching provider services: $e');
      throw Exception('Failed to load provider services');
    }
  }

  // Fetch services within a radius of a location
  static Future<List<ServiceLocation>> getServicesNearLocation(
      double latitude, double longitude, double radiusInMeters,
      {bool? isQuest}) async {
    try {
      // Use the custom SQL function we defined in migrations
      final response = await Supabase.instance.client
          .rpc('find_services_within_radius', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_meters': radiusInMeters,
        'filter_quest': isQuest,
      });

      return (response as List)
          .map<ServiceLocation>((json) => ServiceLocation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching nearby services: $e');
      throw Exception('Failed to load nearby services');
    }
  }

  // Create a new service location
  static Future<ServiceLocation> createService({
    required String title,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required int coinPrice,
    required bool isQuest,
    String? imageUrl,
    DateTime? serviceDate,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // First get the user's profile to get their name
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();

      final String providerName =
          profileResponse['username'] ?? 'Unknown Provider';

      // Create service data with the PostGIS point data
      final serviceData = {
        'title': title,
        'description': description,
        'provider_id': user.id,
        'provider_name': providerName,
        'address': address,
        'image_url': imageUrl,
        // Use SQL function to create the point
        'location':
            Supabase.instance.client.rpc('create_point_from_lat_lng', params: {
          'lat': latitude,
          'lng': longitude,
        }),
        'rating': 0.0,
        'rating_count': 0,
        'coin_price': coinPrice,
        'is_quest': isQuest,
        'service_date': serviceDate?.toIso8601String(),
      };

      final response = await Supabase.instance.client
          .from('service_locations')
          .insert(serviceData)
          .select()
          .single();

      return ServiceLocation.fromJson(response);
    } catch (e) {
      print('Error creating service: $e');
      throw Exception('Failed to create service: ${e.toString()}');
    }
  }

  // Update service location
  Future<ServiceLocation> update() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (user.id != providerId) {
      throw Exception('Only the provider can update this service');
    }

    try {
      final updateData = toJson();

      final response = await Supabase.instance.client
          .from('service_locations')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return ServiceLocation.fromJson(response);
    } catch (e) {
      print('Error updating service: $e');
      throw Exception('Failed to update service');
    }
  }

  // Delete service location
  Future<void> delete() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (user.id != providerId) {
      throw Exception('Only the provider can delete this service');
    }

    try {
      await Supabase.instance.client
          .from('service_locations')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting service: $e');
      throw Exception('Failed to delete service');
    }
  }
}
