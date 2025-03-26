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
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      id: json['id'],
      serviceId: json['service_id'],
      serviceName: json['service_name'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      bookingDate: DateTime.parse(json['booking_date']),
      serviceDate: DateTime.parse(json['service_date']),
      coinPrice: json['coin_price'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      notes: json['notes'],
      isQuest: json['is_quest'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
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
      'status': status.toString().split('.').last,
      'notes': notes,
      'is_quest': isQuest,
    };
  }

  static Future<List<ServiceBooking>> getBookingsForUser(String userId) async {
    final response = await Supabase.instance.client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('service_date', ascending: false);

    return response
        .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
        .toList();
  }

  static Future<List<ServiceBooking>> getBookingsForProvider(
      String providerId) async {
    final response = await Supabase.instance.client
        .from('bookings')
        .select()
        .eq('provider_id', providerId)
        .order('service_date', ascending: false);

    return response
        .map<ServiceBooking>((json) => ServiceBooking.fromJson(json))
        .toList();
  }

  static Future<ServiceBooking> createBooking({
    required ServiceLocation service,
    required DateTime serviceDate,
    String? notes,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // In a real implementation, this would be stored in Supabase
    final newBooking = ServiceBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceId: service.id,
      serviceName: service.title,
      providerId: service.providerId,
      providerName: service.providerName,
      userId: currentUser.id,
      userEmail: currentUser.email ?? 'unknown',
      bookingDate: DateTime.now(),
      serviceDate: serviceDate,
      coinPrice: service.coinPrice,
      status: BookingStatus.pending,
      notes: notes,
      isQuest: service.isQuest,
    );

    // Here would be code to store the booking in Supabase
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 1));

    return newBooking;
  }

  Future<void> updateStatus(BookingStatus newStatus) async {
    await Supabase.instance.client
        .from('bookings')
        .update({'status': newStatus.toString().split('.').last}).eq('id', id);
  }
}
