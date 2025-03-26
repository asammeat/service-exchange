import 'package:flutter/material.dart';
import 'package:service_exchange/models/service_booking.dart';
import 'package:service_exchange/screens/booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  final bool isProvider;

  const BookingsScreen({
    Key? key,
    this.isProvider = false,
  }) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ServiceBooking> _bookings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      if (widget.isProvider) {
        _bookings = await ServiceBooking.getBookingsForProvider();
      } else {
        _bookings = await ServiceBooking.getBookingsForUser();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isProvider ? 'My Clients' : 'My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: Column(
                children: [
                  if (ServiceBooking.useMockData)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              const Text(
                                'Using Mock Data',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Database connection error: ${ServiceBooking.apiErrorMessage ?? "Unknown error"}',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Upcoming bookings
                        _buildBookingsList(_getUpcomingBookings()),

                        // Past bookings
                        _buildBookingsList(_getPastBookings()),

                        // All bookings
                        _buildBookingsList(_bookings),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<ServiceBooking> _getUpcomingBookings() {
    final now = DateTime.now();
    return _bookings
        .where((booking) =>
            booking.serviceDate.isAfter(now) &&
            booking.status != BookingStatus.cancelled &&
            booking.status != BookingStatus.rejected)
        .toList();
  }

  List<ServiceBooking> _getPastBookings() {
    final now = DateTime.now();
    return _bookings
        .where((booking) =>
            booking.serviceDate.isBefore(now) ||
            booking.status == BookingStatus.cancelled ||
            booking.status == BookingStatus.rejected)
        .toList();
  }

  Widget _buildBookingsList(List<ServiceBooking> bookings) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading bookings',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _loadBookings,
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isProvider
                  ? 'You don\'t have any client bookings yet'
                  : 'You haven\'t booked any services yet',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(ServiceBooking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(
                booking: booking,
                isProvider: widget.isProvider,
                onStatusChanged: _loadBookings,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              color: booking.status.color,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Row(
                children: [
                  Icon(booking.status.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    booking.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (booking.isQuest)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Quest',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Booking details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        widget.isProvider
                            ? 'Client: ${booking.userEmail}'
                            : 'Provider: ${booking.providerName}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${_formatDate(booking.serviceDate)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${_formatTime(booking.serviceDate)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        booking.isQuest
                            ? 'Free (Community Quest)'
                            : '${booking.coinPrice} Coins',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}
