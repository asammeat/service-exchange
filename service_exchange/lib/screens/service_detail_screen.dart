import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_location.dart';
import '../models/service_booking.dart';
import '../models/user_profile.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceLocation serviceLocation;

  const ServiceDetailScreen({
    Key? key,
    required this.serviceLocation,
  }) : super(key: key);

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isLoading = false;
  bool _isLoadingUserData = true;
  UserProfile? _userProfile;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // If the service has a specific date, preselect it
    if (widget.serviceLocation.serviceDate != null) {
      _selectedDate = widget.serviceLocation.serviceDate!;
      _selectedTime =
          TimeOfDay.fromDateTime(widget.serviceLocation.serviceDate!);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserProfile.fetchProfile();
      setState(() {
        _userProfile = profile;
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user profile: ${e.toString()}';
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookService() async {
    // Check if user has enough coins for the service
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load user profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For services (not quests), check if user has enough coins
    if (!widget.serviceLocation.isQuest &&
        _userProfile!.coins < widget.serviceLocation.coinPrice) {
      _showInsufficientCoinsDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Combine date and time
      final DateTime serviceDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ServiceBooking.createBooking(
        service: widget.serviceLocation,
        serviceDate: serviceDateTime,
        notes: _notesController.text,
      );

      if (mounted) {
        // Refresh the user profile to get updated coin balance
        await _loadUserProfile();

        Navigator.pop(
            context, true); // Return true to indicate successful booking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serviceLocation.isQuest
                  ? 'Successfully joined quest!'
                  : 'Service booked successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to book service: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking service: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Coins'),
        content: Text(
          'You need ${widget.serviceLocation.coinPrice} coins to book this service, but you only have ${_userProfile?.coins ?? 0} coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToProfileEdit();
            },
            child: const Text('Get More Coins'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfileEdit() {
    if (_userProfile == null) return;

    Navigator.pushNamed(
      context,
      '/profile/edit',
      arguments: _userProfile,
    ).then((_) => _loadUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    final isQuest = widget.serviceLocation.isQuest;
    final primaryColor = isQuest ? Colors.blue : Colors.deepPurple;

    return Scaffold(
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _userProfile == null
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
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // App bar with image
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Service image
                            widget.serviceLocation.imageUrl != null
                                ? Image.network(
                                    widget.serviceLocation.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported,
                                              size: 50),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      isQuest
                                          ? Icons.volunteer_activism
                                          : Icons.home_repair_service,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                            // Gradient overlay for better text visibility
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            widget.serviceLocation.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        titlePadding:
                            const EdgeInsets.only(left: 16, bottom: 16),
                      ),
                      actions: [
                        // Bookmark button
                        IconButton(
                          icon: const Icon(Icons.bookmark_border,
                              color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to bookmarks'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        // Share button
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic info section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Provider avatar
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://i.pravatar.cc/150?img=${widget.serviceLocation.providerName.hashCode}',
                                  ),
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                // Provider info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.serviceLocation.providerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber[700],
                                              size: 16),
                                          Text(
                                              ' ${widget.serviceLocation.rating} · '),
                                          Text(
                                              '${widget.serviceLocation.ratingCount} reviews'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Service type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isQuest ? 'Quest' : 'Service',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Location info
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.serviceLocation.address,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Price info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isQuest
                                        ? Colors.green
                                        : Colors.amber[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monetization_on,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isQuest
                                            ? '+${widget.serviceLocation.coinPrice} coins'
                                            : '${widget.serviceLocation.coinPrice} coins',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_userProfile != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Your balance: ${_userProfile!.coins} coins',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Description
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.serviceLocation.description,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          Divider(color: Colors.grey[300]),

                          // Booking section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isQuest
                                      ? 'Join this Quest'
                                      : 'Book this Service',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Date picker
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: primaryColor),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Date: ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down,
                                            color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Time picker
                                InkWell(
                                  onTap: () => _selectTime(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            color: primaryColor),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Time: ${_selectedTime.format(context)}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down,
                                            color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Notes input
                                TextField(
                                  controller: _notesController,
                                  decoration: InputDecoration(
                                    labelText: 'Notes',
                                    hintText:
                                        'Any special instructions or requests',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        Icon(Icons.note, color: primaryColor),
                                  ),
                                  maxLines: 3,
                                ),

                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.red[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomSheet: _isLoadingUserData
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _bookService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isQuest ? 'Join Quest' : 'Book Service',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
