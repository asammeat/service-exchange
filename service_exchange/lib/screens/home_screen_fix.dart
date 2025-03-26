import 'package:flutter/material.dart';
import '../models/service_location.dart';
import 'service_detail_screen.dart';

// Here's a snippet showing how to correctly navigate to the ServiceDetailScreen
void navigateToServiceDetail(BuildContext context, ServiceLocation location) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceDetailScreen(serviceLocation: location),
    ),
  );
}

// Here's how to create a service location from card data
ServiceLocation createServiceLocationFromCardData({
  required String title,
  required String organizationName,
  required String location,
  required double rating,
  required String imageUrl,
  required DateTime? date,
  required String description,
  required bool isQuest,
  required int coinPrice,
}) {
  return ServiceLocation.fromCardData(
    title: title,
    organization: organizationName,
    location: location,
    rating: rating,
    imageUrl: imageUrl,
    date: date,
    description: description,
    isQuest: isQuest,
    coinPrice: coinPrice,
  );
}

// For services on the map
Widget buildServiceInfoCard(BuildContext context, ServiceLocation service) {
  final bool isQuest = service.isQuest;

  // When navigating from this card
  return Card(
    // Card UI details here
    child: ElevatedButton(
      onPressed: () {
        navigateToServiceDetail(context, service);
      },
      child: const Text('View Details'),
    ),
  );
}

// For service cards in the feed
Widget buildQuestCard(
  BuildContext context, {
  required String organizationName,
  required String location,
  required double rating,
  required String title,
  required String description,
  required String imageUrl,
  required DateTime? date,
  required bool isQuest,
  required int coinPrice,
}) {
  return Card(
    // Card UI details here
    child: InkWell(
      onTap: () {
        final serviceLocation = createServiceLocationFromCardData(
          title: title,
          organizationName: organizationName,
          location: location,
          rating: rating,
          imageUrl: imageUrl,
          date: date,
          description: description,
          isQuest: isQuest,
          coinPrice: coinPrice,
        );

        navigateToServiceDetail(context, serviceLocation);
      },
      child: Container(
          // UI details here
          ),
    ),
  );
}

// Example of calling the buildQuestCard function properly
Widget buildQuestCardExample(BuildContext context) {
  return buildQuestCard(
    context,
    organizationName: 'EcoGuardians',
    location: 'Miami Beach, FL',
    rating: 4.8,
    title: 'Weekend Beach Cleanup',
    description:
        'Join our weekend beach cleanup event and help preserve our beautiful coastline!',
    imageUrl: 'https://example.com/image.jpg',
    date: DateTime.now().add(const Duration(days: 3)),
    isQuest: true,
    coinPrice: 0,
  );
}
