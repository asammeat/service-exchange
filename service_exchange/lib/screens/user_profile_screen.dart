import 'package:flutter/material.dart';
import '../models/service_location.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String? userId;
  final String? avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.username,
    this.userId,
    this.avatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = false;
  final int _servicesCount = 12;
  final int _questsCount = 8;
  final int _followersCount = 245;
  final int _followingCount = 189;
  final double _rating = 4.8;

  // Mock service/quest data
  final List<Map<String, dynamic>> _services = List.generate(
      12,
      (index) => {
            'id': 'service_$index',
            'title': 'Service ${index + 1}',
            'image': 'https://picsum.photos/500/500?random=${index + 200}',
            'price': (15 + (index * 5)).toDouble(),
            'liked': math.Random().nextBool(),
            'likesCount': math.Random().nextInt(50) + 10,
          });

  final List<Map<String, dynamic>> _quests = List.generate(
      8,
      (index) => {
            'id': 'quest_$index',
            'title': 'Quest ${index + 1}',
            'image': 'https://picsum.photos/500/500?random=${index + 100}',
            'liked': math.Random().nextBool(),
            'likesCount': math.Random().nextInt(30) + 5,
          });

  final List<Map<String, dynamic>> _reviews = List.generate(
      10,
      (index) => {
            'id': 'review_$index',
            'username': 'User${index + 1}',
            'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
            'rating': math.Random().nextInt(2) + 4, // 4 or 5 stars
            'comment':
                'Great service! Very professional and helpful. Would recommend to everyone.',
            'service': 'Service ${math.Random().nextInt(12) + 1}',
            'date': '${math.Random().nextInt(7) + 1} days ago',
          });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserData();
  }

  void _loadUserData() async {
    // Simulate loading user data from API
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _toggleFollow() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFollowing = !_isFollowing;

      // Show feedback to user
      if (_isFollowing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now following ${widget.username}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: _toggleFollow,
            ),
          ),
        );
      }
    });
  }

  void _openMessages() {
    HapticFeedback.selectionClick();
    // Show a dialog since we don't have a messages screen yet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Messages'),
        content: Text('Opening chat with ${widget.username}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _toggleLike(String type, int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (type == 'service') {
        _services[index]['liked'] = !_services[index]['liked'];
        _services[index]['likesCount'] = _services[index]['liked']
            ? _services[index]['likesCount'] + 1
            : _services[index]['likesCount'] - 1;
      } else {
        _quests[index]['liked'] = !_quests[index]['liked'];
        _quests[index]['likesCount'] = _quests[index]['liked']
            ? _quests[index]['likesCount'] + 1
            : _quests[index]['likesCount'] - 1;
      }
    });
  }

  void _showPostDetails(String imageUrl, bool isService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isService ? Colors.deepPurple : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isService ? 'SERVICE' : 'COMMUNITY QUEST',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isService)
                        Text(
                          '\$${(15 + imageUrl.hashCode % 50).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isService
                        ? 'Professional ${isService ? "Service" : "Quest"} ${imageUrl.hashCode % 10 + 1}'
                        : 'Community Quest ${imageUrl.hashCode % 10 + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${widget.username}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Nullam eget felis vel dolor efficitur elementum. '
                    'Pellentesque habitant morbi tristique senectus et netus et '
                    'malesuada fames ac turpis egestas.',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isService
                              ? 'Service booked successfully!'
                              : 'You have joined this quest!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isService ? Colors.deepPurple : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isService ? 'Book Now' : 'Join Quest',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    floating: true,
                    title: Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.black),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: const Text('Share Profile'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Sharing profile...')));
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.report),
                                  title: const Text('Report User'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Report User'),
                                        content: const Text(
                                            'Do you want to report this user?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('CANCEL'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Report submitted')));
                                            },
                                            child: const Text('REPORT'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.block),
                                  title: const Text('Block User'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Block User'),
                                        content: Text(
                                            'Block ${widget.username}? You won\'t see their content anymore.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('CANCEL'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '${widget.username} has been blocked'),
                                                  action: SnackBarAction(
                                                    label: 'UNDO',
                                                    onPressed: () {},
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('BLOCK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header with Background Image
                        Stack(
                          children: [
                            // Background Image
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://picsum.photos/800/400?random=${widget.username.hashCode}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Gradient Overlay
                            Container(
                              height: 200,
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
                            // Profile Content
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Profile Image with Border
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          widget.avatarUrl ??
                                              'https://i.pravatar.cc/150?img=${widget.username.hashCode}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // User Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Professional service provider',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Stats Cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Services',
                                  _servicesCount.toString(),
                                  Icons.home_repair_service,
                                  Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Quests',
                                  _questsCount.toString(),
                                  Icons.volunteer_activism,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Rating',
                                  _rating.toString(),
                                  Icons.star,
                                  Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bio Section with Custom Design
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Passionate about helping others and making a difference in the community 🌟',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Miami, FL',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Member since March 2024',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons with Custom Design
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? Colors.grey[200]
                                        : Colors.blue,
                                    foregroundColor: _isFollowing
                                        ? Colors.black
                                        : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  icon: Icon(
                                    _isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openMessages,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  icon: const Icon(Icons.message_outlined,
                                      size: 20),
                                  label: const Text(
                                    'Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Achievement Badges with Custom Design
                        Container(
                          height: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildAchievementBadge(
                                'Top Rated',
                                '4.8 ⭐',
                                Colors.amber,
                                Icons.workspace_premium,
                              ),
                              _buildAchievementBadge(
                                'Quest Master',
                                '50+ Quests',
                                Colors.blue,
                                Icons.military_tech,
                              ),
                              _buildAchievementBadge(
                                'Super Helper',
                                '100+ Services',
                                Colors.green,
                                Icons.emoji_events,
                              ),
                              _buildAchievementBadge(
                                'Early Bird',
                                'Member',
                                Colors.purple,
                                Icons.rocket_launch,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.black,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Services'),
                          Tab(text: 'Quests'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildServicesGrid(),
                  _buildQuestsGrid(),
                  _buildReviewsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (label == 'Services') {
          _tabController.animateTo(0);
        } else if (label == 'Quests') {
          _tabController.animateTo(1);
        } else if (label == 'Rating') {
          _tabController.animateTo(2);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
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
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetails(title, subtitle, color, icon);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.8),
                    color,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(
      String title, String subtitle, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievement: $title ($subtitle)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This badge is awarded to users who consistently provide high-quality services and maintain excellent ratings from clients.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                const Text('Achievement unlocked on March 15, 2024'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _servicesCount,
      itemBuilder: (context, index) {
        return _buildGridItem(
          _services[index]['image'],
          isService: true,
        );
      },
    );
  }

  Widget _buildQuestsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _questsCount,
      itemBuilder: (context, index) {
        return _buildGridItem(
          _quests[index]['image'],
          isService: false,
        );
      },
    );
  }

  Widget _buildGridItem(String imageUrl, {required bool isService}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showPostDetails(imageUrl, isService);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isService ? Colors.deepPurple : Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isService ? 'SERVICE' : 'QUEST',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          // Like button overlay
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isService ? 12 + (imageUrl.hashCode % 30) : 8 + (imageUrl.hashCode % 20)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildReviewItem(index);
      },
    );
  }

  Widget _buildReviewItem(int index) {
    final bool isPositive =
        index % 5 != 0; // Make every 5th review less positive for variety
    final int rating = isPositive ? 5 : 3 + (index % 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${index + 10}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${index + 1} ${index == 0 ? "day" : "days"} ago',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (starIndex) => Icon(
                    Icons.star,
                    size: 16,
                    color: starIndex < rating ? Colors.amber : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Amazing service! Very professional and friendly. ${index % 2 == 0 ? "Would definitely recommend to others." : "Looking forward to working together again soon!"}'
                : 'Good service but could improve on communication. ${index % 2 == 0 ? "Delivered the work on time though." : "Would use the service again with some adjustments."}',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                index % 3 == 0
                    ? 'Web Development Service'
                    : index % 3 == 1
                        ? 'Interior Design Service'
                        : 'Math Tutoring Service',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reported review'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.flag_outlined,
                      size: 16, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload some images for smoother experience
    for (var i = 0; i < 3; i++) {
      precacheImage(
        NetworkImage('https://picsum.photos/500/500?random=${i + 100}'),
        context,
      );
      precacheImage(
        NetworkImage('https://picsum.photos/500/500?random=${i + 200}'),
        context,
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
