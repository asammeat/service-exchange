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
  bool _usingMockData = false;

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
      _usingMockData = false;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Load real bookings from Supabase
      _bookings = await ServiceBooking.getBookingsForUser();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in booking history: ${e.toString()}');

      // If we can't load real data, fall back to mock data
      setState(() {
        _bookings = _createMockBookings();
        _isLoading = false;
        _usingMockData = true;
        _errorMessage =
            'Using demo data: ${e.toString()}\n\nTo use real data, make sure your Supabase database is set up correctly.';
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

  Future<void> _cancelBooking(ServiceBooking booking) async {
    if (_usingMockData) {
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == booking.id) {
            // Create a copy with cancelled status (since our mock objects are immutable)
            return ServiceBooking(
              id: b.id,
              serviceId: b.serviceId,
              serviceName: b.serviceName,
              providerId: b.providerId,
              providerName: b.providerName,
              userId: b.userId,
              userEmail: b.userEmail,
              bookingDate: b.bookingDate,
              serviceDate: b.serviceDate,
              coinPrice: b.coinPrice,
              status: BookingStatus.cancelled,
              notes: b.notes,
              isQuest: b.isQuest,
            );
          }
          return b;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully (mock mode)'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: Text(
                'Are you sure you want to cancel your booking for "${booking.serviceName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() {
        _isLoading = true;
      });

      try {
        await booking.updateStatus(BookingStatus.cancelled);
        await _loadBookings(); // Reload to get updated list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _markAsInProgress(ServiceBooking booking) async {
    if (_usingMockData) {
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == booking.id) {
            // Create a copy with in progress status
            return ServiceBooking(
              id: b.id,
              serviceId: b.serviceId,
              serviceName: b.serviceName,
              providerId: b.providerId,
              providerName: b.providerName,
              userId: b.userId,
              userEmail: b.userEmail,
              bookingDate: b.bookingDate,
              serviceDate: b.serviceDate,
              coinPrice: b.coinPrice,
              status: BookingStatus.inProgress,
              notes: b.notes,
              isQuest: b.isQuest,
            );
          }
          return b;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking marked as in progress (mock mode)'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await booking.updateStatus(BookingStatus.inProgress);
      await _loadBookings(); // Reload to get updated list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as in progress'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsCompleted(ServiceBooking booking) async {
    if (_usingMockData) {
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == booking.id) {
            // Create a copy with completed status
            return ServiceBooking(
              id: b.id,
              serviceId: b.serviceId,
              serviceName: b.serviceName,
              providerId: b.providerId,
              providerName: b.providerName,
              userId: b.userId,
              userEmail: b.userEmail,
              bookingDate: b.bookingDate,
              serviceDate: b.serviceDate,
              coinPrice: b.coinPrice,
              status: BookingStatus.completed,
              notes: b.notes,
              isQuest: b.isQuest,
            );
          }
          return b;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking marked as completed (mock mode)'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await booking.updateStatus(BookingStatus.completed);
      await _loadBookings(); // Reload to get updated list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          : Column(
              children: [
                if (_usingMockData)
                  Container(
                    color: Colors.amber[100],
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage ??
                                'Using demo data. Database connection not available.',
                            style: TextStyle(color: Colors.amber[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _errorMessage != null && !_usingMockData
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
                ),
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
                Icon(booking.status.icon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  booking.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.isQuest ? 'Quest' : 'Service',
                  style: TextStyle(
                    color: booking.isQuest ? Colors.blue : Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      booking.providerName,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy • h:mm a')
                          .format(booking.serviceDate),
                      style: TextStyle(
                        color: isUpcoming ? Colors.black : Colors.grey[600],
                        fontWeight: isUpcoming ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      booking.isQuest
                          ? 'Earn ${booking.coinPrice} coins'
                          : '${booking.coinPrice} coins',
                      style: TextStyle(
                        color:
                            booking.isQuest ? Colors.green : Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 12,
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
          // Actions
          if (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16, top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _cancelBooking(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (booking.status == BookingStatus.confirmed &&
                      isUpcoming &&
                      booking.serviceDate.isBefore(
                          DateTime.now().add(const Duration(days: 1))))
                    ElevatedButton(
                      onPressed: () => _markAsInProgress(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start'),
                    ),
                ],
              ),
            ),
          if (booking.status == BookingStatus.inProgress)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16, top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _markAsCompleted(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
