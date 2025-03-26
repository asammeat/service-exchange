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

  static Future<List<ServiceBooking>> getBookingsForUser() async {
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
        return [];
      }

      if (response is! List) {
        print('Expected List but got: ${response.runtimeType}');
        // Check if response is a Map with an error
        if (response is Map) {
          final map = response as Map;
          if (map.containsKey('error')) {
            throw Exception('Database error: ${map['error']}');
          }
        }
        return [];
      }

      final bookings = response
          .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
          .toList();

      print('Found ${bookings.length} bookings');
      return bookings;
    } catch (e) {
      print('Error fetching bookings: $e');
      throw Exception('Failed to load bookings: ${e.toString()}');
    }
  }

  static Future<List<ServiceBooking>> getBookingsForProvider() async {
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
        return [];
      }

      if (response is! List) {
        print('Expected List but got: ${response.runtimeType}');
        // Check if response is a Map with an error
        if (response is Map) {
          final map = response as Map;
          if (map.containsKey('error')) {
            throw Exception('Database error: ${map['error']}');
          }
        }
        return [];
      }

      final bookings = response
          .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
          .toList();

      print('Found ${bookings.length} provider bookings');
      return bookings;
    } catch (e) {
      print('Error fetching provider bookings: $e');
      throw Exception('Failed to load provider bookings: ${e.toString()}');
    }
  }

  static Future<ServiceBooking> createBooking({
    required ServiceLocation service,
    required DateTime serviceDate,
    String? notes,
  }) async {
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

      // The trigger in Supabase will automatically update user coins
      return ServiceBooking.fromJson(response);
    } catch (e) {
      print('Error creating booking: $e');
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  Future<void> updateStatus(BookingStatus newStatus) async {
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
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }
}
