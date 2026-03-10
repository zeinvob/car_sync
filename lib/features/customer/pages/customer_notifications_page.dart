import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/features/customer/pages/booking_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerNotificationsPage extends StatefulWidget {
  const CustomerNotificationsPage({super.key});

  @override
  State<CustomerNotificationsPage> createState() =>
      _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState extends State<CustomerNotificationsPage> {
  final NotificationService _notificationService = NotificationService.instance;

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _notificationService.markAllUserNotificationsAsRead(userId: user.uid);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_status_update':
        return Icons.update;
      case 'repair_update':
        return Icons.build;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String? newStatus) {
    switch (newStatus?.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ),
        body: const Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 6, 80, 160),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.userNotificationsStream(userId: user.uid),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];

          if (snapshot.hasError) {
            final errorText = snapshot.error.toString();

            final friendlyMessage =
                errorText.contains('requires an index') ||
                    errorText.contains('currently building')
                ? 'Notifications are getting ready. Please try again in a moment.'
                : 'Something went wrong while loading notifications.';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  friendlyMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive updates about your bookings here',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final List<dynamic> isReadBy = item['isReadBy'] ?? [];
              final bool isRead = isReadBy.contains(user.uid);
              final String type = item['type'] ?? '';
              final extraData = (item['extraData'] is Map<String, dynamic>)
                  ? item['extraData'] as Map<String, dynamic>
                  : <String, dynamic>{};
              final String? newStatus = extraData['newStatus']?.toString();

              return GestureDetector(
                onTap: () async {
                  // Mark as read
                  await _notificationService.markNotificationAsReadForUser(
                    notificationId: item['id'],
                    userId: user.uid,
                  );

                  // Navigate to booking details if available
                  final relatedBookingId = (item['relatedBookingId'] ?? '')
                      .toString();

                  if (relatedBookingId.isNotEmpty && mounted) {
                    // Fetch booking data from Firestore
                    try {
                      final bookingDoc = await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(relatedBookingId)
                          .get();

                      if (bookingDoc.exists && mounted) {
                        final bookingData = bookingDoc.data()!;
                        bookingData['id'] = bookingDoc.id;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailsPage(booking: bookingData),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error fetching booking: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not load booking details'),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Theme.of(context).cardColor
                        : Theme.of(context).cardColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: isRead
                        ? null
                        : Border.all(
                            color: _getNotificationColor(
                              newStatus,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.grey.withOpacity(0.15)
                              : _getNotificationColor(
                                  newStatus,
                                ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getNotificationIcon(type),
                          color: isRead
                              ? Colors.grey[600]
                              : _getNotificationColor(newStatus),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] ?? 'Notification',
                                    style: GoogleFonts.poppins(
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(newStatus),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['body'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTimestamp(item['createdAt']),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
