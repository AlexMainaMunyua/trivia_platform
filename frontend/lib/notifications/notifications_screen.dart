import 'package:flutter/material.dart';
import 'package:frontend/models/notificatons.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return ListView.builder(
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
        child: Icon(
          _getNotificationIcon(notification.type),
          color: Colors.white,
        ),
      ),
      title: Text(notification.message),
      subtitle: Text(
        _formatDate(notification.createdAt),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: !notification.isRead
          ? IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Provider.of<NotificationProvider>(context, listen: false)
                    .markAsRead(notification.id);
              },
            )
          : null,
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'game_invitation':
        return Icons.mail;
      case 'invitation_response':
        return Icons.reply;
      default:
        return Icons.notifications;
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