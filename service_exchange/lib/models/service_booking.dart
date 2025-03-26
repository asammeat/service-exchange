import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_location.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.pending_actions;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.hourglass_top;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rejected:
        return Icons.block;
    }
  }
}

class ServiceBooking {
  final String id;
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String providerName;
  final String userId;
  final String userEmail;
  final DateTime bookingDate;
  final DateTime serviceDate;
  final int coinPrice;
  final BookingStatus status;
  final String? notes;
  final bool isQuest;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Track if we're in mock mode
  static bool _useMockData = false;
  static String? _apiErrorMessage;

  ServiceBooking({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.providerName,
    required this.userId,
    required this.userEmail,
    required this.bookingDate,
    required this.serviceDate,
    required this.coinPrice,
    required this.status,
    this.notes,
    required this.isQuest,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    try {
      // Debug information
      print('Processing booking JSON: ${json['id']}');

      return ServiceBooking(
        id: json['id'] ?? '',
        serviceId: json['service_id'] ?? '',
        serviceName: json['service_name'] ?? 'Unknown Service',
        providerId: json['provider_id'] ?? '',
        providerName: json['provider_name'] ?? 'Unknown Provider',
        userId: json['user_id'] ?? '',
        userEmail: json['user_email'] ?? 'unknown@example.com',
        bookingDate: json['booking_date'] != null
            ? DateTime.parse(json['booking_date'])
            : DateTime.now(),
        serviceDate: json['service_date'] != null
            ? DateTime.parse(json['service_date'])
            : DateTime.now(),
        coinPrice: json['coin_price'] != null ? json['coin_price'] : 0,
        status: _parseStatus(json['status'] ?? 'pending'),
        notes: json['notes'],
        isQuest: json['is_quest'] ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
    } catch (e) {
      print('Error parsing booking JSON: $e');
      print('Problematic JSON: $json');

      // Return a placeholder booking instead of crashing
      return ServiceBooking(
        id: json['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
        serviceId: json['service_id'] ?? '',
        serviceName: 'Error: ${e.toString().substring(0, 20)}...',
        providerId: json['provider_id'] ?? '',
        providerName: 'Error Parsing Data',
        userId: json['user_id'] ?? '',
        userEmail: 'error@example.com',
        bookingDate: DateTime.now(),
        serviceDate: DateTime.now(),
        coinPrice: 0,
        status: BookingStatus.pending,
        isQuest: false,
      );
    }
  }

  static BookingStatus _parseStatus(String statusStr) {
    try {
      // Convert from database format (pending) to enum format (BookingStatus.pending)
      if (statusStr == 'in_progress') {
        return BookingStatus.inProgress;
      }

      return BookingStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            statusStr.toLowerCase(),
      );
    } catch (e) {
      print('Error parsing status: $statusStr, Error: $e');
      return BookingStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    final String statusStr = status == BookingStatus.inProgress
        ? 'in_progress'
        : status.toString().split('.').last.toLowerCase();

    return {
      'id': id,
      'service_id': serviceId,
      'service_name': serviceName,
      'provider_id': providerId,
      'provider_name': providerName,
      'user_id': userId,
      'user_email': userEmail,
      'booking_date': bookingDate.toIso8601String(),
      'service_date': serviceDate.toIso8601String(),
      'coin_price': coinPrice,
      'status': statusStr,
      'notes': notes,
      'is_quest': isQuest,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Get information about mock data usage
  static bool get useMockData => _useMockData;
  static String? get apiErrorMessage => _apiErrorMessage;

  static Future<List<ServiceBooking>> getBookingsForUser() async {
    // If we already know real data doesn't work, don't try again
    if (_useMockData) {
      return _createMockBookings();
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      print('Fetching bookings for user: ${user.id}');

      final response = await Supabase.instance.client
          .from('service_bookings')
          .select()
          .eq('user_id', user.id)
          .order('service_date', ascending: false);

      print('Bookings response: $response');

      if (response == null) {
        print('Received null response from Supabase');
        _useMockData = true;
        _apiErrorMessage = 'Null response from server';
        return _createMockBookings();
      }

      if (response is! List) {
        print('Expected List but got: ${response.runtimeType}');
        // Check if response is a Map with an error
        if (response is Map) {
          final map = response as Map;
          if (map.containsKey('error')) {
            _useMockData = true;
            _apiErrorMessage = 'Database error: ${map['error']}';
            return _createMockBookings();
          }
        }
        _useMockData = true;
        _apiErrorMessage = 'Invalid response format';
        return _createMockBookings();
      }

      final bookings = response
          .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
          .toList();

      print('Found ${bookings.length} bookings');
      _useMockData = false;
      _apiErrorMessage = null;
      return bookings;
    } catch (e) {
      print('Error fetching bookings: $e');
      _useMockData = true;
      _apiErrorMessage = e.toString();
      return _createMockBookings();
    }
  }

  // Create mock bookings for when the API is unavailable
  static List<ServiceBooking> _createMockBookings() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final now = DateTime.now();

    return [
      ServiceBooking(
        id: '1',
        serviceId: '101',
        serviceName: 'Weekend Beach Cleanup',
        providerId: '201',
        providerName: 'EcoGuardians',
        userId: currentUser?.id ?? 'unknown',
        userEmail: currentUser?.email ?? 'unknown',
        bookingDate: now.subtract(const Duration(days: 3)),
        serviceDate: now.add(const Duration(days: 2)),
        coinPrice: 0,
        status: BookingStatus.confirmed,
        isQuest: true,
      ),
      ServiceBooking(
        id: '2',
        serviceId: '102',
        serviceName: 'Modern Interior Design',
        providerId: '202',
        providerName: 'Emily Parker',
        userId: currentUser?.id ?? 'unknown',
        userEmail: currentUser?.email ?? 'unknown',
        bookingDate: now.subtract(const Duration(days: 5)),
        serviceDate: now.add(const Duration(days: 7)),
        coinPrice: 350,
        status: BookingStatus.pending,
        isQuest: false,
      ),
      ServiceBooking(
        id: '3',
        serviceId: '103',
        serviceName: 'Website Development',
        providerId: '203',
        providerName: 'Tech Solutions',
        userId: currentUser?.id ?? 'unknown',
        userEmail: currentUser?.email ?? 'unknown',
        bookingDate: now.subtract(const Duration(days: 10)),
        serviceDate: now.subtract(const Duration(days: 2)),
        coinPrice: 500,
        status: BookingStatus.completed,
        isQuest: false,
      ),
      ServiceBooking(
        id: '4',
        serviceId: '104',
        serviceName: 'Plant Trees Day',
        providerId: '204',
        providerName: 'Community Garden',
        userId: currentUser?.id ?? 'unknown',
        userEmail: currentUser?.email ?? 'unknown',
        bookingDate: now.subtract(const Duration(days: 15)),
        serviceDate: now.subtract(const Duration(days: 5)),
        coinPrice: 0,
        status: BookingStatus.completed,
        isQuest: true,
      ),
      ServiceBooking(
        id: '5',
        serviceId: '105',
        serviceName: 'Lawn Mowing',
        providerId: '205',
        providerName: 'Green Thumb',
        userId: currentUser?.id ?? 'unknown',
        userEmail: currentUser?.email ?? 'unknown',
        bookingDate: now.subtract(const Duration(days: 7)),
        serviceDate: now.subtract(const Duration(days: 1)),
        coinPrice: 120,
        status: BookingStatus.cancelled,
        isQuest: false,
        notes: 'Cancelled due to rain',
      ),
    ];
  }

  static Future<List<ServiceBooking>> getBookingsForProvider() async {
    // If we already know real data doesn't work, don't try again
    if (_useMockData) {
      return _createMockBookings();
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      print('Fetching bookings for provider: ${user.id}');

      final response = await Supabase.instance.client
          .from('service_bookings')
          .select()
          .eq('provider_id', user.id)
          .order('service_date', ascending: false);

      print('Provider bookings response: $response');

      if (response == null) {
        print('Received null response from Supabase');
        _useMockData = true;
        _apiErrorMessage = 'Null response from server';
        return _createMockBookings();
      }

      if (response is! List) {
        print('Expected List but got: ${response.runtimeType}');
        // Check if response is a Map with an error
        if (response is Map) {
          final map = response as Map;
          if (map.containsKey('error')) {
            _useMockData = true;
            _apiErrorMessage = 'Database error: ${map['error']}';
            return _createMockBookings();
          }
        }
        _useMockData = true;
        _apiErrorMessage = 'Invalid response format';
        return _createMockBookings();
      }

      final bookings = response
          .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
          .toList();

      print('Found ${bookings.length} provider bookings');
      _useMockData = false;
      _apiErrorMessage = null;
      return bookings;
    } catch (e) {
      print('Error fetching provider bookings: $e');
      _useMockData = true;
      _apiErrorMessage = e.toString();
      return _createMockBookings();
    }
  }

  static Future<ServiceBooking> createBooking({
    required ServiceLocation service,
    required DateTime serviceDate,
    String? notes,
  }) async {
    // If we're in mock mode, create a mock booking
    if (_useMockData) {
      return ServiceBooking(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        serviceId: service.id,
        serviceName: service.title,
        providerId: service.providerId,
        providerName: service.providerName,
        userId: Supabase.instance.client.auth.currentUser?.id ?? 'unknown',
        userEmail:
            Supabase.instance.client.auth.currentUser?.email ?? 'unknown',
        bookingDate: DateTime.now(),
        serviceDate: serviceDate,
        coinPrice: service.coinPrice,
        status: BookingStatus.pending,
        notes: notes,
        isQuest: service.isQuest,
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      print('Creating booking for service: ${service.id}');

      // Convert inProgress to in_progress for the database
      final bookingData = {
        'service_id': service.id,
        'service_name': service.title,
        'provider_id': service.providerId,
        'provider_name': service.providerName,
        'user_id': user.id,
        'user_email': user.email ?? 'unknown',
        'booking_date': DateTime.now().toIso8601String(),
        'service_date': serviceDate.toIso8601String(),
        'coin_price': service.coinPrice,
        'status': 'pending',
        'notes': notes,
        'is_quest': service.isQuest,
      };

      print('Booking data: $bookingData');

      final response = await Supabase.instance.client
          .from('service_bookings')
          .insert(bookingData)
          .select()
          .single();

      print('Booking created response: $response');
      _useMockData = false;

      // The trigger in Supabase will automatically update user coins
      return ServiceBooking.fromJson(response);
    } catch (e) {
      print('Error creating booking: $e');
      _useMockData = true;
      _apiErrorMessage = e.toString();

      // Return a mock booking
      return ServiceBooking(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        serviceId: service.id,
        serviceName: service.title,
        providerId: service.providerId,
        providerName: service.providerName,
        userId: user.id,
        userEmail: user.email ?? 'unknown',
        bookingDate: DateTime.now(),
        serviceDate: serviceDate,
        coinPrice: service.coinPrice,
        status: BookingStatus.pending,
        notes: notes,
        isQuest: service.isQuest,
      );
    }
  }

  Future<void> updateStatus(BookingStatus newStatus) async {
    // If we're in mock mode, don't try to update the database
    if (_useMockData) {
      print(
          'Mock mode: Pretending to update booking status to ${newStatus.displayName}');
      return;
    }

    try {
      // Convert inProgress to in_progress for the database
      final String statusStr = newStatus == BookingStatus.inProgress
          ? 'in_progress'
          : newStatus.toString().split('.').last.toLowerCase();

      print('Updating booking ${id} status to: $statusStr');

      await Supabase.instance.client.from('service_bookings').update({
        'status': statusStr,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', id);

      print('Booking status updated successfully');
      // The trigger in Supabase will automatically handle coin transfers
    } catch (e) {
      print('Error updating booking status: $e');
      _useMockData = true;
      _apiErrorMessage = e.toString();
    }
  }
}
