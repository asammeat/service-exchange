import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:async';
import '../models/service_location.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final List<ServiceLocation> _serviceLocations =
      ServiceLocation.generateMockLocations(15);
  final Map<String, Marker> _markers = {};
  final Location _locationService = Location();
  final Completer<GoogleMapController> _mapController = Completer();
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.422, -122.084), // Default to Google HQ
    zoom: 13,
  );
  LocationData? _currentLocation;
  bool _serviceSelected = false;
  ServiceLocation? _selectedService;
  String _mapFilterType = 'All';
  MapType _currentMapType = MapType.normal;

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

    // Move camera to current location
    if (_currentLocation != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
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
    final filteredLocations =
        _serviceLocations.where((location) {
          if (_mapFilterType == 'All') return true;
          if (_mapFilterType == 'Quests')
            return location.serviceType == 'quest';
          if (_mapFilterType == 'Services')
            return location.serviceType == 'service';
          if (_mapFilterType == 'Nearby' && _currentLocation != null) {
            // Calculate distance (simple approximation)
            final latDiff =
                (location.latitude - _currentLocation!.latitude!).abs();
            final lngDiff =
                (location.longitude - _currentLocation!.longitude!).abs();
            return (latDiff + lngDiff) < 0.05; // Roughly 5km
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
          snippet:
              location.serviceType == 'quest'
                  ? 'Quest'
                  : 'Service: ${location.coinPrice} coins',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          location.serviceType == 'quest'
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

  @override
  void initState() {
    super.initState();
    _initMarkers();
    // Get location when the app starts
    _getCurrentLocation();
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
          // Account type indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      _isPartnerAccount
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
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter tabs
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter tabs scrolling
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: List.generate(
                        _filterOptions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 8.0,
                          ),
                          child: FilterChip(
                            label: Text(_filterOptions[index]),
                            selected: _selectedFilterIndex == index,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            },
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    _selectedFilterIndex == index
                                        ? Colors.blue
                                        : Colors.grey[300]!,
                              ),
                            ),
                            showCheckmark: false,
                            selectedColor: Colors.blue.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color:
                                  _selectedFilterIndex == index
                                      ? Colors.blue
                                      : Colors.black,
                              fontWeight:
                                  _selectedFilterIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Currently showing text
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      bottom: 8.0,
                      top: 4.0,
                    ),
                    child: Text(
                      'Currently showing: ${_filterOptions[_selectedFilterIndex]}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  // Divider
                  const Divider(height: 1, thickness: 1),
                ],
              ),
            ),
            // Main content - Service/Quest listings
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Home Feed Tab
                  _buildServicesFeed(),

                  // Services Map Tab
                  _buildServicesMapScreen(),

                  // Create Service Tab
                  _buildCreateServiceScreen(),

                  // Following Tab
                  _buildFollowingScreen(),

                  // Profile Tab
                  _buildProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        elevation: 2,
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _selectedIndex = 2; // Go to create service screen
          });
        },
      ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quest card
        _buildQuestCard(
          organizationName: 'EcoGuardians',
          location: 'San Francisco, CA',
          rating: 4.7,
          title: 'Weekend Beach Cleanup',
          description:
              'Help us keep our local beaches clean and safe for wildlife!',
          imageUrl:
              'https://images.unsplash.com/photo-1501959915551-4e8d30928317?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
          date: 'Tomorrow, 9 AM - 12 PM',
          isQuest: true,
        ),

        // Service card
        _buildQuestCard(
          organizationName: 'Emily Parker',
          location: 'Oakland, CA',
          rating: 4.8,
          title: 'Modern Interior Design',
          description:
              'Transform your space with professional interior design services.',
          imageUrl:
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1776&q=80',
          date: 'Next week',
          isQuest: false,
        ),

        // Another service card
        _buildQuestCard(
          organizationName: 'Tech Solutions',
          location: 'Palo Alto, CA',
          rating: 4.9,
          title: 'Website Development',
          description:
              'Professional website development services for small businesses and startups.',
          imageUrl:
              'https://images.unsplash.com/photo-1460925895917-afdab827c52f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1115&q=80',
          date: 'Available now',
          isQuest: false,
        ),

        // Another quest
        _buildQuestCard(
          organizationName: 'Community Garden',
          location: 'Berkeley, CA',
          rating: 4.6,
          title: 'Plant Trees Day',
          description:
              'Join us for a day of planting trees to beautify our community and fight climate change.',
          imageUrl:
              'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
          date: 'This Saturday, 10 AM - 2 PM',
          isQuest: true,
        ),
      ],
    );
  }

  Widget _buildQuestCard({
    required String organizationName,
    required String location,
    required double rating,
    required String title,
    required String description,
    required String imageUrl,
    required String date,
    required bool isQuest,
  }) {
    final serviceType = isQuest ? 'QUEST' : 'SERVICE';
    final coinPrice = isQuest ? 0 : (25 + (title.length * 5));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization/provider info
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?img=${organizationName.hashCode}',
              ),
              onBackgroundImageError: (_, __) {
                // Handle image load error
              },
            ),
            title: Text(
              organizationName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                Text(
                  ' $rating',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),

          // Image
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isQuest ? Colors.blue : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    serviceType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (!isQuest)
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$coinPrice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], height: 1.3),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(date),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(isQuest ? 'Join Quest' : 'Apply Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isQuest ? Colors.blue : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesMapScreen() {
    // Initialize markers if needed
    if (_markers.isEmpty) {
      _initMarkers();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers.values.toSet(),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          mapType: _currentMapType,
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
            // Try to move to user's location when map is created
            _getCurrentLocation();
          },
          onTap: (_) {
            // Clear selection when tapping the map
            setState(() {
              _serviceSelected = false;
              _selectedService = null;
            });
          },
        ),

        // Filter chips for map view
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Service type filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        _buildMapFilterChip('All', _mapFilterType == 'All'),
                        _buildMapFilterChip(
                          'Quests',
                          _mapFilterType == 'Quests',
                        ),
                        _buildMapFilterChip(
                          'Services',
                          _mapFilterType == 'Services',
                        ),
                        _buildMapFilterChip(
                          'Nearby',
                          _mapFilterType == 'Nearby',
                        ),
                      ],
                    ),
                  ),

                  // Map type selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Map Type: ',
                          style: TextStyle(fontSize: 12),
                        ),
                        _buildMapTypeButton('Normal', MapType.normal),
                        _buildMapTypeButton('Satellite', MapType.satellite),
                        _buildMapTypeButton('Hybrid', MapType.hybrid),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Service details card when a marker is selected
        if (_serviceSelected && _selectedService != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildServiceInfoCard(_selectedService!),
          ),
      ],
    );
  }

  Widget _buildMapFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          setState(() {
            _mapFilterType = label;
            _initMarkers();
          });
        },
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? Colors.blue : Colors.grey[300]!),
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

  Widget _buildMapTypeButton(String label, MapType mapType) {
    final bool isSelected = _currentMapType == mapType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            _currentMapType = mapType;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(ServiceLocation service) {
    final bool isQuest = service.serviceType == 'quest';
    final Color cardColor = isQuest ? Colors.blue : Colors.deepPurple;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cardColor.withOpacity(0.1),
              child: Icon(
                isQuest ? Icons.volunteer_activism : Icons.home_repair_service,
                color: cardColor,
              ),
            ),
            title: Text(
              service.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(service.providerName),
            trailing:
                isQuest
                    ? const Chip(
                      label: Text('QUEST'),
                      backgroundColor: Colors.blue,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                    : Chip(
                      label: Text('${service.coinPrice} ¢'),
                      backgroundColor: Colors.amber,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Add a locate button
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Center on map',
                  onPressed: () {
                    _focusOnMarker(service.latLng);
                  },
                ),
                Expanded(
                  child: Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  onPressed: () {
                    _openDirections(service.latitude, service.longitude);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Apply for service or join quest
                  },
                  child: Text(isQuest ? 'Join Quest' : 'Apply Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Show error if unable to launch Google Maps
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open directions'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildFollowingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Following Screen',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=${user?.id.hashCode ?? 0}',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.email ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Account type toggle with label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('User Account'),
              Switch(
                value: _isPartnerAccount,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    _isPartnerAccount = value;
                  });
                },
              ),
              const Text('Partner Account'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isPartnerAccount
                ? 'Partner Account (create Quests only)'
                : 'User Account (create Services only)',
            style: TextStyle(
              color: _isPartnerAccount ? Colors.deepPurple : Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
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
