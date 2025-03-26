import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_booking.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ServiceBooking> _bookings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Placeholder implementation since we don't have a real database yet
      // In a real app, this would call ServiceBooking.getBookingsForUser
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      // Create some mock bookings
      _bookings = _createMockBookings();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load bookings: ${e.toString()}';
      });
    }
  }

  List<ServiceBooking> _createMockBookings() {
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

  List<ServiceBooking> get _activeBookings => _bookings
      .where((booking) =>
          booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.confirmed ||
          booking.status == BookingStatus.inProgress)
      .toList();

  List<ServiceBooking> get _pastBookings => _bookings
      .where((booking) =>
          booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.rejected)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? const Center(
                      child: Text(
                        'No bookings found.\nStart by booking a service or joining a quest!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingList(_activeBookings),
                        _buildBookingList(_pastBookings),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.add),
        tooltip: 'Book a new service',
      ),
    );
  }

  Widget _buildBookingList(List<ServiceBooking> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('No bookings in this category'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(ServiceBooking booking) {
    final Color statusColor = booking.status.color;
    final bool isUpcoming = booking.serviceDate.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(booking.status.icon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  booking.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.isQuest ? Colors.blue : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.isQuest ? 'QUEST' : 'SERVICE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title and price
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (!booking.isQuest) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.coinPrice}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Provider
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      booking.providerName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date information
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isUpcoming
                          ? 'Scheduled for ${DateFormat('MMM d, yyyy').format(booking.serviceDate)}'
                          : booking.status == BookingStatus.completed
                              ? 'Completed on ${DateFormat('MMM d, yyyy').format(booking.serviceDate)}'
                              : 'Was scheduled for ${DateFormat('MMM d, yyyy').format(booking.serviceDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                // Notes if any
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed)
            Padding(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Implement cancel booking
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  if (booking.status == BookingStatus.confirmed) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Implement reschedule
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reschedule feature coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Reschedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // For completed services, add review option
          if (booking.status == BookingStatus.completed)
            Padding(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Implement review functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review feature coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Leave Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
