import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:service_exchange/models/service_booking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingDetailsScreen extends StatefulWidget {
  final ServiceBooking booking;
  final bool isProvider;
  final VoidCallback onStatusChanged;

  const BookingDetailsScreen({
    Key? key,
    required this.booking,
    this.isProvider = false,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  _BookingDetailsScreenState createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late ServiceBooking _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _updateBookingStatus(BookingStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _booking.updateStatus(newStatus);

      // Update the local booking status
      setState(() {
        _booking = ServiceBooking(
          id: _booking.id,
          serviceId: _booking.serviceId,
          serviceName: _booking.serviceName,
          providerId: _booking.providerId,
          providerName: _booking.providerName,
          userId: _booking.userId,
          userEmail: _booking.userEmail,
          bookingDate: _booking.bookingDate,
          serviceDate: _booking.serviceDate,
          coinPrice: _booking.coinPrice,
          status: newStatus,
          notes: _booking.notes,
          isQuest: _booking.isQuest,
          createdAt: _booking.createdAt,
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
      });

      widget.onStatusChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Booking status updated to ${newStatus.displayName}')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final isUpcoming = _booking.serviceDate.isAfter(DateTime.now());
    final useMockData = ServiceBooking.useMockData;
    final apiErrorMessage = ServiceBooking.apiErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_booking.serviceName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (useMockData)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
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
                            'Database connection error: ${apiErrorMessage ?? "Unknown error"}',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  if (useMockData) const SizedBox(height: 16),
                  // Status indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _booking.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _booking.status.color),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_booking.status.icon,
                                color: _booking.status.color),
                            const SizedBox(width: 8),
                            Text(
                              _booking.status.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _booking.status.color,
                              ),
                            ),
                          ],
                        ),
                        if (_booking.isQuest)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'Community Quest',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Service Information
                  const Text(
                    'Service Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.event,
                    title: 'Service Date',
                    subtitle: dateFormat.format(_booking.serviceDate),
                  ),
                  _infoTile(
                    icon: Icons.access_time,
                    title: 'Service Time',
                    subtitle: timeFormat.format(_booking.serviceDate),
                  ),
                  _infoTile(
                    icon: Icons.calendar_today,
                    title: 'Booked On',
                    subtitle: dateFormat.format(_booking.bookingDate),
                  ),
                  _infoTile(
                    icon: Icons.attach_money,
                    title: 'Cost',
                    subtitle: _booking.isQuest
                        ? 'Free (Community Quest)'
                        : '${_booking.coinPrice} Coins',
                  ),

                  const SizedBox(height: 24),

                  // Provider/User Information
                  Text(
                    widget.isProvider
                        ? 'Client Information'
                        : 'Provider Information',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.person,
                    title: widget.isProvider ? 'Client' : 'Provider',
                    subtitle: widget.isProvider
                        ? _booking.userEmail
                        : _booking.providerName,
                  ),

                  // Notes section if available
                  if (_booking.notes != null && _booking.notes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(_booking.notes!),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Action buttons based on user role and status
                  if (_shouldShowActionButtons())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _infoTile(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowActionButtons() {
    final currentUserIsProvider = widget.isProvider;
    final currentUserIsClient = !widget.isProvider;

    switch (_booking.status) {
      case BookingStatus.pending:
        return true; // Both provider and client can take actions
      case BookingStatus.confirmed:
        return currentUserIsProvider; // Only provider can mark as in progress
      case BookingStatus.inProgress:
        return currentUserIsProvider; // Only provider can mark as completed
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return false; // No actions for completed/cancelled/rejected bookings
    }
  }

  Widget _buildActionButtons() {
    final currentUserIsProvider = widget.isProvider;
    final currentUserIsClient = !widget.isProvider;

    switch (_booking.status) {
      case BookingStatus.pending:
        if (currentUserIsProvider) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () =>
                      _updateBookingStatus(BookingStatus.confirmed),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => _updateBookingStatus(BookingStatus.rejected),
                ),
              ),
            ],
          );
        } else {
          return ElevatedButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Booking'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () => _updateBookingStatus(BookingStatus.cancelled),
          );
        }

      case BookingStatus.confirmed:
        if (currentUserIsProvider) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Service'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
            ),
            onPressed: () => _updateBookingStatus(BookingStatus.inProgress),
          );
        }
        return const SizedBox.shrink();

      case BookingStatus.inProgress:
        if (currentUserIsProvider) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
            ),
            onPressed: () => _updateBookingStatus(BookingStatus.completed),
          );
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
