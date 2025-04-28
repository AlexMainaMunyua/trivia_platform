import 'package:flutter/material.dart';
import 'package:frontend/models/notificatons.dart';
import 'package:provider/provider.dart';
import '../../../../providers/notification_provider.dart';
import 'dart:math' as math;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _showElevation = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Start animation
    _animationController.forward();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_showElevation) {
      setState(() {
        _showElevation = true;
      });
    } else if (_scrollController.offset <= 0 && _showElevation) {
      setState(() {
        _showElevation = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(primaryColor),
          ];
        },
        body: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notificationProvider.notifications.isEmpty) {
              return _buildEmptyState();
            }

            // Group notifications by date
            final groupedNotifications = _groupNotificationsByDate(
              notificationProvider.notifications
            );

            return RefreshIndicator(
              onRefresh: () => notificationProvider.fetchNotifications(),
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Added bottom padding for navigation bar
                itemCount: groupedNotifications.length,
                itemBuilder: (context, index) {
                  final dateGroup = groupedNotifications.keys.elementAt(index);
                  final notifications = groupedNotifications[dateGroup]!;

                  return _buildNotificationGroup(context, dateGroup, notifications, primaryColor, index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 90.0,
      floating: false,
      pinned: true,
      elevation: _showElevation ? 4 : 0,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background pattern
            CustomPaint(
              painter: NotificationPatternPainter(Colors.white.withOpacity(0.1)),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.8),
                    primaryColor,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            final unreadCount = notificationProvider.unreadCount;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Mark all as read',
                child: InkWell(
                  onTap: unreadCount > 0
                      ? () {
                          notificationProvider.markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('All notifications marked as read'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: unreadCount > 0
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.done_all,
                      color: unreadCount > 0 ? Colors.white : Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup(BuildContext context, String dateGroup, List<AppNotification> notifications, Color primaryColor, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            dateGroup,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        // Notifications for this date
        ...notifications.asMap().entries.map((entry) {
          final notificationIndex = entry.key;
          final notification = entry.value;

          // Create staggered animation for each item
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                math.min(0.1 * (notificationIndex + index * 5), 0.9), // Stagger the animations
                math.min(0.1 * (notificationIndex + index * 5) + 0.4, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: NotificationCard(
                notification: notification,
                onMarkAsRead: () {
                  Provider.of<NotificationProvider>(context, listen: false).markAsRead(notification.id);
                },
                primaryColor: primaryColor,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Group notifications by date for better organization
  Map<String, List<AppNotification>> _groupNotificationsByDate(List<AppNotification> notifications) {
    final groupedNotifications = <String, List<AppNotification>>{};
    final now = DateTime.now();

    for (final notification in notifications) {
      final date = notification.createdAt;
      final difference = now.difference(date);

      String dateGroup;
      if (difference.inDays == 0) {
        dateGroup = 'Today';
      } else if (difference.inDays == 1) {
        dateGroup = 'Yesterday';
      } else if (difference.inDays < 7) {
        dateGroup = 'This Week';
      } else if (difference.inDays < 30) {
        dateGroup = 'This Month';
      } else {
        dateGroup = 'Older';
      }

      if (!groupedNotifications.containsKey(dateGroup)) {
        groupedNotifications[dateGroup] = [];
      }

      groupedNotifications[dateGroup]!.add(notification);
    }

    return groupedNotifications;
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkAsRead;
  final Color primaryColor;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final notificationType = _getNotificationType(notification.type);
    final notificationColor = _getNotificationColor(notification.type, primaryColor);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: notificationColor.withOpacity(0.3), width: 1),
      ),
      color: notification.isRead
          ? Colors.white
          : notificationColor.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to appropriate screen based on notification type
          if (!notification.isRead) {
            onMarkAsRead();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: notificationColor.withOpacity(notification.isRead ? 0.1 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: notification.isRead
                        ? notificationColor.withOpacity(0.7)
                        : notificationColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification type label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: notificationColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notificationType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: notificationColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Notification message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Timestamp and read status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!notification.isRead)
                          InkWell(
                            onTap: onMarkAsRead,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'Mark as read',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'game_invitation':
        return Icons.card_giftcard;
      case 'invitation_response':
        return Icons.reply;
      case 'game_started':
        return Icons.play_circle_filled;
      case 'game_ended':
        return Icons.flag;
      case 'friend_request':
        return Icons.person_add;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationType(String type) {
    switch (type) {
      case 'game_invitation':
        return 'INVITATION';
      case 'invitation_response':
        return 'RESPONSE';
      case 'game_started':
        return 'GAME STARTED';
      case 'game_ended':
        return 'GAME ENDED';
      case 'friend_request':
        return 'FRIEND REQUEST';
      case 'achievement':
        return 'ACHIEVEMENT';
      default:
        return 'NOTIFICATION';
    }
  }

  Color _getNotificationColor(String type, Color primaryColor) {
    switch (type) {
      case 'game_invitation':
        return Colors.purple;
      case 'invitation_response':
        return Colors.blue;
      case 'game_started':
        return Colors.green;
      case 'game_ended':
        return Colors.orange;
      case 'friend_request':
        return Colors.teal;
      case 'achievement':
        return Colors.amber[700]!;
      default:
        return primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Custom painter for background pattern
class NotificationPatternPainter extends CustomPainter {
  final Color color;

  NotificationPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw pattern elements
    final random = math.Random(47); // Unique seed for this screen
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 4.0 + random.nextDouble() * 8;

      // Draw notification bell shapes (simplified as circles)
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
