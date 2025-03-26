import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:async';
import 'dart:math';
import '../models/service_location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'service_detail_screen.dart';
import 'booking_history_screen.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import '../components/home/post_card.dart';
import '../components/home/map_view.dart';
import '../components/home/filter_bar.dart';
import '../components/shared/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedFilterIndex = 0;
  final user = Supabase.instance.client.auth.currentUser;
  int _userCoins = 500; // Mock initial coins
  bool _isPartnerAccount = false; // Default to normal user
  bool _mapFirstVisit = true;

  final List<String> _filterOptions = [
    'All',
    'Quests',
    'Services',
    'Nearby',
    'Popular',
  ];

  final Location _locationService = Location();
  final Completer<GoogleMapController> _mapController = Completer();
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7128, -74.0060), // Default to NYC
    zoom: 12,
  );
  LocationData? _currentLocation;
  bool _serviceSelected = false;
  ServiceLocation? _selectedService;
  String _mapFilterType = 'All';
  MapType _currentMapType = MapType.normal;
  bool _locationsGenerated = false;
  List<ServiceLocation> _serviceLocations = [];
  final Map<String, Marker> _markers = {};

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    _currentLocation = await _locationService.getLocation();

    // Generate service locations around the user's current location if not already done
    if (!_locationsGenerated && _currentLocation != null) {
      setState(() {
        final userLatLng =
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
        _serviceLocations = ServiceLocation.generateMockLocations(20,
            centerLocation: userLatLng);
        _locationsGenerated = true;
        _initMarkers(); // Regenerate markers based on the new locations
      });
    }

    // Move camera to current location
    if (_currentLocation != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          14, // Zoom level
        ),
      );
    }
  }

  Future<void> _focusOnMarker(LatLng position) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    }
  }

  void _initMarkers() {
    _markers.clear();

    // Filter locations based on current filter type
    final filteredLocations = _serviceLocations.where((location) {
      if (_mapFilterType == 'All') return true;
      if (_mapFilterType == 'Quests') return location.isQuest;
      if (_mapFilterType == 'Services') return !location.isQuest;
      if (_mapFilterType == 'Nearby' && _currentLocation != null) {
        // Calculate distance using Haversine formula (more accurate)
        final lat1 = location.latitude;
        final lon1 = location.longitude;
        final lat2 = _currentLocation!.latitude!;
        final lon2 = _currentLocation!.longitude!;

        const r = 6371e3; // Earth's radius in meters
        final phi1 = lat1 * math.pi / 180;
        final phi2 = lat2 * math.pi / 180;
        final deltaPhi = (lat2 - lat1) * math.pi / 180;
        final deltaLambda = (lon2 - lon1) * math.pi / 180;

        final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
            math.cos(phi1) *
                math.cos(phi2) *
                math.sin(deltaLambda / 2) *
                math.sin(deltaLambda / 2);
        final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        final distance = r * c; // Distance in meters

        return distance < 2000; // Show locations within 2km
      }
      return true;
    }).toList();

    for (final location in filteredLocations) {
      // Determine if this location is currently selected
      final bool isSelected =
          _selectedService != null && _selectedService!.id == location.id;

      final marker = Marker(
        markerId: MarkerId(location.id),
        position: location.latLng,
        infoWindow: InfoWindow(
          title: location.title,
          snippet: location.isQuest
              ? 'Quest'
              : 'Service: ${location.coinPrice} coins',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          location.isQuest
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueViolet,
        ),
        // Use a larger zIndex for selected markers so they appear on top
        zIndex: isSelected ? 2 : 1,
        // Selected markers can be made slightly larger with a custom icon (would require asset)
        onTap: () {
          setState(() {
            _serviceSelected = true;
            _selectedService = location;
            // Rebuild markers to update the selected one
            _initMarkers();
            // Focus map on the selected marker
            _focusOnMarker(location.latLng);
          });
        },
      );
      _markers[location.id] = marker;
    }
  }

  void _onServiceSelected(ServiceLocation location) {
    setState(() {
      _serviceSelected = true;
      _selectedService = location;
    });
  }

  @override
  void initState() {
    super.initState();
    // Default locations (will be replaced when user location is available)
    _serviceLocations = ServiceLocation.generateMockLocations(20);
    _initMarkers();
    // Get location when the app starts
    Future.delayed(Duration.zero, () {
      _getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is the first visit to the map screen and show dialog
    if (_selectedIndex == 1 && _mapFirstVisit) {
      _mapFirstVisit = false;
      // Delayed to avoid build during build issues
      Future.delayed(Duration.zero, () => _showLocationDialog(context));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ServiceExchange',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.blue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Bookings history button
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen()),
              );
            },
            tooltip: 'My Bookings',
          ),
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              _showSearchModal(context);
            },
          ),
          // Account type indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isPartnerAccount
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPartnerAccount ? Colors.deepPurple : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Text(
                  _isPartnerAccount ? 'Partner' : 'User',
                  style: TextStyle(
                    color: _isPartnerAccount ? Colors.deepPurple : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Badge(
              label: Text('$_userCoins'),
              child: const Icon(Icons.monetization_on, color: Colors.amber),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Badge(
              label: Text('0'),
              child: Icon(Icons.shopping_cart_outlined, color: Colors.black87),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Badge(
              label: Text('1'),
              child: Icon(Icons.notifications_outlined, color: Colors.black87),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const NotificationsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            FilterBar(
              filterOptions: _filterOptions,
              selectedIndex: _selectedFilterIndex,
              onFilterSelected: (index) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildServicesFeed(),
                  MapView(
                    filterType: _filterOptions[_selectedFilterIndex],
                    serviceLocations: _serviceLocations,
                    onServiceSelected: _onServiceSelected,
                    selectedService: _selectedService,
                  ),
                  _buildCreateServiceScreen(),
                  _buildProfileScreen(),
                  _buildSettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      floatingActionButton: _selectedIndex == 0
          ? Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[300]!, Colors.blue[700]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2; // Go to create service screen
                  });
                },
                child: const Icon(
                  Icons.add,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        notchMargin: 6,
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Button
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),

              // Map Button
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),

              // QR Scan button (center)
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    // Show QR code scanner
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR code scanner coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),

              // Profile Button
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),

              // Settings Button
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: _selectedIndex == 4 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesFeed() {
    // Filter services based on selected filter
    final filteredServices = _serviceLocations.where((service) {
      if (_filterOptions[_selectedFilterIndex] == 'All') return true;
      if (_filterOptions[_selectedFilterIndex] == 'Quests')
        return service.isQuest;
      if (_filterOptions[_selectedFilterIndex] == 'Services')
        return !service.isQuest;
      if (_filterOptions[_selectedFilterIndex] == 'Nearby' &&
          _currentLocation != null) {
        // Calculate distance and return services within 2km
        final latDiff = (service.latitude - _currentLocation!.latitude!).abs();
        final lngDiff =
            (service.longitude - _currentLocation!.longitude!).abs();
        return (latDiff + lngDiff) < 0.05;
      }
      return true;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return PostCard(
          organizationName: service.providerName,
          location: service.address,
          rating: service.rating,
          title: service.title,
          description: service.description,
          imageUrl: service.imageUrl ??
              'https://picsum.photos/500/300?random=${service.id}',
          date: _formatDate(service.createdAt ?? DateTime.now()),
          questStatus: service.isQuest ? "Active" : "",
          coinPrice: service.coinPrice,
          isQuest: service.isQuest,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildCreateServiceScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create a Listing',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                // Account type toggle
                Switch(
                  value: _isPartnerAccount,
                  activeColor: Colors.deepPurple,
                  activeTrackColor: Colors.deepPurple.withOpacity(0.4),
                  inactiveThumbColor: Colors.blue,
                  inactiveTrackColor: Colors.blue.withOpacity(0.4),
                  onChanged: (value) {
                    setState(() {
                      _isPartnerAccount = value;
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 24.0),
              child: Text(
                _isPartnerAccount
                    ? 'You are creating as a Partner (can only create Quests)'
                    : 'You are creating as a User (can only create Services)',
                style: TextStyle(
                  color: _isPartnerAccount ? Colors.deepPurple : Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            // Card selection based on account type
            _isPartnerAccount
                ? _buildServiceTypeCard(
                    'Quest',
                    Icons.volunteer_activism,
                    Colors.blue,
                    'Community service and activities',
                    true,
                  )
                : _buildServiceTypeCard(
                    'Service',
                    Icons.home_repair_service,
                    Colors.deepPurple,
                    'Professional services for hire',
                    true,
                  ),
            const SizedBox(height: 24),
            DottedBorderBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  const Text('Upload Cover Image'),
                ],
              ),
              onTap: () {},
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Create Listing'),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeCard(
    String title,
    IconData icon,
    Color color,
    String description,
    bool isSelected,
  ) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),
        // Profile Header Section
        Row(
          children: [
            Hero(
              tag: 'profileImage',
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=${user?.id.hashCode ?? 0}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email?.split('@').first ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Account type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isPartnerAccount
                          ? Colors.deepPurple.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _isPartnerAccount ? Colors.deepPurple : Colors.blue,
                      ),
                    ),
                    child: Text(
                      _isPartnerAccount ? 'Partner Account' : 'User Account',
                      style: TextStyle(
                        color:
                            _isPartnerAccount ? Colors.deepPurple : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats Section
        _buildStatsCard(),
        const SizedBox(height: 16),

        // Achievements Section
        _buildAchievementsCard(),
        const SizedBox(height: 16),

        // Account Type Switch
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch between User and Partner mode to access different features',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAccountTypeOption(
                      'User',
                      Icons.person,
                      Colors.blue,
                      !_isPartnerAccount,
                      onTap: () {
                        setState(() {
                          _isPartnerAccount = false;
                        });
                      },
                    ),
                    _buildAccountTypeOption(
                      'Partner',
                      Icons.business,
                      Colors.deepPurple,
                      _isPartnerAccount,
                      onTap: () {
                        setState(() {
                          _isPartnerAccount = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Activity Timeline
        _buildActivityTimelineCard(),
        const SizedBox(height: 16),

        // My Activities
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Activities',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              _buildActivityItem(
                'Joined Beach Cleanup Quest',
                'Yesterday',
                Icons.volunteer_activism,
                Colors.blue,
              ),
              const Divider(height: 0),
              _buildActivityItem(
                'Listed Website Development Service',
                '3 days ago',
                Icons.computer,
                Colors.deepPurple,
              ),
              const Divider(height: 0),
              _buildActivityItem(
                'Completed Senior Support Quest',
                'Last week',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Wallet and Transactions
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wallet & Transactions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_userCoins coins',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              _buildTransactionItem(
                'Earned from Website Development',
                '+200 coins',
                '2 days ago',
                isPositive: true,
              ),
              const Divider(height: 0),
              _buildTransactionItem(
                'Spent on Car Detailing Service',
                '-150 coins',
                'Last week',
                isPositive: false,
              ),
              const Divider(height: 0),
              _buildTransactionItem(
                'Reward for Quest Completion',
                '+50 coins',
                '2 weeks ago',
                isPositive: true,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Top Up Coins'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.1),
                    foregroundColor: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Settings Section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedIndex = 4; // Go to settings screen
                  });
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 0),
              ListTile(
                leading:
                    const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '3 of 9 unlocked',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                _buildAchievementItem(
                  'First Quest',
                  'Completed your first community quest',
                  Icons.volunteer_activism,
                  Colors.blue,
                  true,
                ),
                _buildAchievementItem(
                  'Service Provider',
                  'Listed your first service',
                  Icons.home_repair_service,
                  Colors.deepPurple,
                  true,
                ),
                _buildAchievementItem(
                  'Top Rated',
                  'Received 5 star rating',
                  Icons.star,
                  Colors.amber,
                  true,
                ),
                _buildAchievementItem(
                  'Quest Master',
                  'Complete 10 community quests',
                  Icons.military_tech,
                  Colors.orange,
                  false,
                ),
                _buildAchievementItem(
                  'Eco Warrior',
                  'Participate in 5 environmental quests',
                  Icons.eco,
                  Colors.green,
                  false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('View All Achievements'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
    String title,
    String description,
    IconData icon,
    Color color,
    bool unlocked,
  ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: unlocked ? color.withOpacity(0.1) : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked ? color : Colors.grey,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: unlocked ? color : Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: unlocked ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          _buildTimelineItem(
            'Today',
            'Messaged John about Dog Walking Service',
            '2 hours ago',
            Icons.chat_bubble_outline,
            Colors.green,
          ),
          _buildTimelineConnector(),
          _buildTimelineItem(
            'Yesterday',
            'Joined Beach Cleanup Quest',
            '1 day ago',
            Icons.nature_people,
            Colors.blue,
          ),
          _buildTimelineConnector(),
          _buildTimelineItem(
            'July 15',
            'Created a new service listing',
            '3 days ago',
            Icons.add_circle_outline,
            Colors.deepPurple,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 16, top: 8),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history, size: 16),
              label: const Text('View full history'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String date,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: Container(
        width: 2,
        height: 30,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),

        // Account Settings
        _buildSettingsSection(
          title: 'Account Settings',
          icon: Icons.person_outline,
          children: [
            _buildSettingsTile(
              title: 'Personal Information',
              subtitle: 'Manage your profile details',
              icon: Icons.person_outline,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Personal Information coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildSettingsTile(
              title: 'Email & Notifications',
              subtitle: 'Manage how we contact you',
              icon: Icons.email_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Password & Security',
              subtitle: 'Update your password and security settings',
              icon: Icons.lock_outline,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Privacy & Data',
              subtitle: 'Control your data and privacy preferences',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payment Settings
        _buildSettingsSection(
          title: 'Payment Settings',
          icon: Icons.payments_outlined,
          children: [
            _buildSettingsTile(
              title: 'Payment Methods',
              subtitle: 'Add or remove payment methods',
              icon: Icons.credit_card_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Billing History',
              subtitle: 'View your transaction history',
              icon: Icons.receipt_long_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Subscription',
              subtitle: 'Manage your subscription plan',
              icon: Icons.subscriptions_outlined,
              onTap: () {},
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // App Settings
        _buildSettingsSection(
          title: 'App Settings',
          icon: Icons.app_settings_alt_outlined,
          children: [
            _buildSettingsTile(
              title: 'Theme',
              subtitle: 'Light, Dark, or System default',
              icon: Icons.color_lens_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Language',
              subtitle: 'Set your preferred language',
              icon: Icons.language_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              icon: Icons.notifications_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'App Permissions',
              subtitle: 'Manage app permissions',
              icon: Icons.security_outlined,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Support & About
        _buildSettingsSection(
          title: 'Support & About',
          icon: Icons.help_outline,
          children: [
            _buildSettingsTile(
              title: 'Help & Support',
              subtitle: 'Get help with ServiceExchange',
              icon: Icons.help_outline,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'About ServiceExchange',
              subtitle: 'Version 1.0.0',
              icon: Icons.info_outline,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Logout Button
        ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue, size: 18),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 0, indent: 72),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Services', '4'),
            _buildVerticalDivider(),
            _buildStatItem('Quests', '6'),
            _buildVerticalDivider(),
            _buildStatItem('Reviews', '12'),
            _buildVerticalDivider(),
            _buildStatItem('Rating', '4.8'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildAccountTypeOption(
    String title,
    IconData icon,
    Color color,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {},
    );
  }

  Widget _buildTransactionItem(
    String title,
    String amount,
    String time, {
    required bool isPositive,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {},
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text(
            'ServiceExchange needs access to your location to show services and quests near you. '
            'Would you like to enable location services?',
          ),
          actions: [
            TextButton(
              child: const Text('Not Now'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable'),
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSearchModal(BuildContext context) {
    final List<String> recentSearches = [
      'dog walking',
      'yard work',
      'tutoring',
      'beach cleanup',
      'computer help',
    ];

    final List<String> popularCategories = [
      'Home Services',
      'Education',
      'Environmental',
      'Tech Support',
      'Community Events',
      'Pet Care',
      'Legal Services',
      'Health & Wellness',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search for services or quests',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        // Handle search
                        Navigator.pop(context);
                        if (value.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Searching for: $value'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // Filter options
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSearchFilterChip('All', true),
                        _buildSearchFilterChip('Services', false),
                        _buildSearchFilterChip('Quests', false),
                        _buildSearchFilterChip('Nearby', false),
                        _buildSearchFilterChip('Popular', false),
                      ],
                    ),
                  ),

                  // Divider
                  const Divider(),

                  // Recent searches
                  if (recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Searches',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              // Clear search history
                            },
                            child: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.history, color: Colors.grey),
                            title: Text(recentSearches[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.north_west, size: 16),
                              onPressed: () {
                                // Use this search term
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Searching for: ${recentSearches[index]}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              // Use this search term
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Searching for: ${recentSearches[index]}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // Popular categories
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Popular Categories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: popularCategories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryButton(
                          popularCategories[index],
                          index: index,
                          onTap: () {
                            // Search for this category
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Browsing category: ${popularCategories[index]}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (selected) {
          // Update filter
        },
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        showCheckmark: false,
        selectedColor: Colors.blue.withOpacity(0.1),
        labelStyle: TextStyle(
          color: selected ? Colors.blue : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label,
      {required int index, required VoidCallback onTap}) {
    // Different colors for each category
    final List<Color> colors = [
      Colors.blue,
      Colors.deepPurple,
      Colors.green,
      Colors.amber,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final color = colors[index % colors.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const DottedBorderBox({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: Colors.grey.shade400,
        strokeWidth: 2,
        dashPattern: const [6, 3],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(child: child),
        ),
      ),
    );
  }
}
