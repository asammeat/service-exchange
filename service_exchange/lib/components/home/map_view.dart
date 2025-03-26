import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';
import '../../models/service_location.dart';

class MapView extends StatefulWidget {
  final String filterType;
  final List<ServiceLocation> serviceLocations;
  final Function(ServiceLocation) onServiceSelected;
  final ServiceLocation? selectedService;

  const MapView({
    Key? key,
    required this.filterType,
    required this.serviceLocations,
    required this.onServiceSelected,
    this.selectedService,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Location _locationService = Location();
  final Completer<GoogleMapController> _mapController = Completer();
  LocationData? _currentLocation;
  final Map<String, Marker> _markers = {};
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initMarkers();
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterType != widget.filterType ||
        oldWidget.selectedService != widget.selectedService) {
      _initMarkers();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _currentLocation = await _locationService.getLocation();
    if (_currentLocation != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          14,
        ),
      );
    }
  }

  void _initMarkers() {
    _markers.clear();

    final filteredLocations = widget.serviceLocations.where((location) {
      if (widget.filterType == 'All') return true;
      if (widget.filterType == 'Quests') return location.isQuest;
      if (widget.filterType == 'Services') return !location.isQuest;
      if (widget.filterType == 'Nearby' && _currentLocation != null) {
        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        );
        return distance < 2000; // Show locations within 2km
      }
      return true;
    }).toList();

    for (final location in filteredLocations) {
      final bool isSelected = widget.selectedService?.id == location.id;

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
        zIndex: isSelected ? 2 : 1,
        onTap: () => widget.onServiceSelected(location),
      );
      _markers[location.id] = marker;
    }
    setState(() {});
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371e3; // Earth's radius in meters
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<void> _focusOnMarker(LatLng position) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _mapController.complete(controller),
          initialCameraPosition: CameraPosition(
            target: const LatLng(40.7128, -74.0060), // Default to NYC
            zoom: 12,
          ),
          markers: Set<Marker>.of(_markers.values),
          mapType: _currentMapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _onMapTypeButtonPressed,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            mini: true,
            child: const Icon(Icons.layers),
          ),
        ),
      ],
    );
  }
}
