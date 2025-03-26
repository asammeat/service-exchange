import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate loading from Supabase
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _notifications = [
        NotificationItem(
          type: NotificationType.quest,
          title: 'New Quest Available',
          message: 'Beach Cleanup Quest is starting soon in your area!',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          actionable: true,
          questId: '123',
        ),
        NotificationItem(
          type: NotificationType.service,
          title: 'Service Booking Confirmed',
          message: 'Your web development service booking has been confirmed',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          actionable: true,
          serviceId: '456',
        ),
        NotificationItem(
          type: NotificationType.social,
          title: 'New Follower',
          message: 'John Doe started following you',
          time: DateTime.now().subtract(const Duration(days: 1)),
          isRead: false,
          actionable: true,
          userId: '789',
        ),
        // Add more mock notifications here
      ];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Mentions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blue),
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification.isRead = true;
                }
              });
              // Show confirmation snackbar with animation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('All notifications marked as read'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  animation: CurvedAnimation(
                    parent: const AlwaysStoppedAnimation(1),
                    curve: Curves.easeInOut,
                  ),
                ),
              );
            },
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              // Handle menu item selection
              switch (value) {
                case 'settings':
                  // Navigate to notification settings
                  break;
                case 'clear':
                  setState(() {
                    _notifications.clear();
                  });
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Notification Settings'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_notifications),
                _buildNotificationsList(
                    _notifications.where((n) => !n.isRead).toList()),
                _buildNotificationsList(
                    _notifications.where((n) => n.hasMention).toList()),
              ],
            ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          // Add stagger animation for list items
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildNotificationCard(notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.hashCode.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
            // Handle notification tap based on type
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.white
                  : Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(notification.time),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          if (notification.actionable) ...[
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  _handleNotificationAction(notification),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _getActionButtonText(notification),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationItem notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.quest:
        icon = Icons.volunteer_activism;
        color = Colors.blue;
        break;
      case NotificationType.service:
        icon = Icons.home_repair_service;
        color = Colors.deepPurple;
        break;
      case NotificationType.social:
        icon = Icons.person;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  String _getActionButtonText(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.quest:
        return 'View Quest';
      case NotificationType.service:
        return 'View Service';
      case NotificationType.social:
        return 'View Profile';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.quest:
        if (notification.questId != null) {
          Navigator.pushNamed(
            context,
            '/quest-details',
            arguments: {'questId': notification.questId},
          );
        }
        break;
      case NotificationType.service:
        if (notification.serviceId != null) {
          Navigator.pushNamed(
            context,
            '/service-details',
            arguments: {'serviceId': notification.serviceId},
          );
        }
        break;
      case NotificationType.social:
        if (notification.userId != null) {
          Navigator.pushNamed(
            context,
            '/user-profile',
            arguments: {'userId': notification.userId},
          );
        }
        break;
    }
  }

  void _handleNotificationAction(NotificationItem notification) {
    _handleNotificationTap(notification);
  }
}

enum NotificationType {
  quest,
  service,
  social,
}

class NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final bool actionable;
  final String? questId;
  final String? serviceId;
  final String? userId;
  final bool hasMention;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.actionable = false,
    this.questId,
    this.serviceId,
    this.userId,
    this.hasMention = false,
  });
}
