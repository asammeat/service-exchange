import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/user_profile_screen.dart';
import '../../screens/service_detail_screen.dart';
import '../../models/service_location.dart';

class PostCard extends StatelessWidget {
  final String organizationName;
  final String location;
  final double rating;
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String questStatus;
  final int coinPrice;
  final bool isQuest;
  final VoidCallback? onTap;

  const PostCard({
    Key? key,
    required this.organizationName,
    required this.location,
    required this.rating,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.questStatus,
    required this.coinPrice,
    required this.isQuest,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert relative time to DateTime
    DateTime parsedDate = DateTime.now();
    if (date.contains('hours ago')) {
      int hours = int.parse(date.split(' ')[0]);
      parsedDate = DateTime.now().subtract(Duration(hours: hours));
    } else if (date.contains('minutes ago')) {
      int minutes = int.parse(date.split(' ')[0]);
      parsedDate = DateTime.now().subtract(Duration(minutes: minutes));
    } else if (date.contains('days ago')) {
      int days = int.parse(date.split(' ')[0]);
      parsedDate = DateTime.now().subtract(Duration(days: days));
    } else {
      try {
        parsedDate = DateFormat('MMM d, yyyy').parse(date);
      } catch (e) {
        // If parsing fails, default to current time
        parsedDate = DateTime.now();
      }
    }

    // Create a ServiceLocation object for this post using the fromCardData factory
    final serviceLocation = ServiceLocation.fromCardData(
      title: title,
      organization: organizationName,
      location: location,
      rating: rating,
      imageUrl: imageUrl,
      date: parsedDate,
      description: description,
      isQuest: isQuest,
      coinPrice: coinPrice,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with organization info
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      username: organizationName,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://picsum.photos/100/100?random=${organizationName.hashCode}',
                ),
                onBackgroundImageError: (exception, stackTrace) {
                  // Handle avatar image error
                },
                child:
                    Icon(Icons.person, color: Theme.of(context).primaryColor),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            username: organizationName,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      organizationName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(location),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isQuest
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isQuest ? 'Quest' : 'Service',
                    style: TextStyle(
                      color: isQuest ? Colors.blue : Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildOptionsSheet(context),
                );
              },
            ),
          ),

          // Main image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    serviceLocation: serviceLocation,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 300,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isQuest ? Icons.volunteer_activism : Icons.handyman,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),

          // Instagram-like title and description section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons (like, comment, share, save)
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 24, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline,
                        size: 24, color: Colors.grey[800]),
                    const SizedBox(width: 16),
                    Icon(Icons.send_outlined,
                        size: 24, color: Colors.grey[800]),
                    const Spacer(),
                    Icon(Icons.bookmark_border,
                        size: 24, color: Colors.grey[800]),
                  ],
                ),

                // Apply button
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailScreen(
                            serviceLocation: serviceLocation,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isQuest ? Colors.blue : Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isQuest ? 'Join Quest' : 'Apply Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Likes count
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$rating (${(rating * 10).toInt()} likes)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.monetization_on,
                        color: Colors.amber[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$coinPrice coins',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Title and description
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: '$organizationName ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: description,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Date/time
                const SizedBox(height: 8),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[500],
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

  Widget _buildOptionsSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Add share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              // Add report functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              // Add block functionality
            },
          ),
        ],
      ),
    );
  }
}
