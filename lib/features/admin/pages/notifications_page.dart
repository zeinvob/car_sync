import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/features/admin/pages/workshop_bookings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService.instance;

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _notificationService.markAllRoleNotificationsAsReadForUser(
      role: 'admin',
      userId: user.uid,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  Color _getAccentColor(BuildContext context, Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString();
    final extraData = item['extraData'] is Map<String, dynamic>
        ? item['extraData'] as Map<String, dynamic>
        : <String, dynamic>{};
    final status = (extraData['newStatus'] ?? '').toString().toLowerCase();

    if (type == 'new_booking') return const Color(0xFF2563EB);
    if (status == 'in_progress') return const Color(0xFFF59E0B);
    if (status == 'completed') return const Color(0xFF10B981);

    return Theme.of(context).colorScheme.primary;
  }

  IconData _getNotificationIcon(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString();
    final extraData = item['extraData'] is Map<String, dynamic>
        ? item['extraData'] as Map<String, dynamic>
        : <String, dynamic>{};
    final status = (extraData['newStatus'] ?? '').toString().toLowerCase();

    if (type == 'new_booking') return Icons.calendar_today_rounded;
    if (status == 'in_progress') return Icons.build_circle_rounded;
    if (status == 'completed') return Icons.check_circle_rounded;

    return Icons.notifications_active_rounded;
  }

  String _getTagText(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString();
    final extraData = item['extraData'] is Map<String, dynamic>
        ? item['extraData'] as Map<String, dynamic>
        : <String, dynamic>{};
    final status = (extraData['newStatus'] ?? '').toString().toLowerCase();

    if (type == 'new_booking') return 'New Booking';
    if (status == 'in_progress') return 'In Progress';
    if (status == 'completed') return 'Completed';

    return 'Update';
  }

  Future<void> _handleTap(Map<String, dynamic> item, String userId) async {
    await _notificationService.markNotificationAsReadForUser(
      notificationId: item['id'],
      userId: userId,
    );

    final relatedWorkshopId = (item['relatedWorkshopId'] ?? '').toString();
    final relatedBookingId = (item['relatedBookingId'] ?? '').toString();

    final extraData = item['extraData'] is Map<String, dynamic>
        ? item['extraData'] as Map<String, dynamic>
        : <String, dynamic>{};

    final workshopName = (extraData['workshopName'] ?? 'Workshop').toString();

    if (relatedWorkshopId.isNotEmpty) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkshopBookingsPage(
            workshopId: relatedWorkshopId,
            workshopName: workshopName,
            highlightBookingId: relatedBookingId.isNotEmpty
                ? relatedBookingId
                : null,
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context, int totalCount, int unreadCount) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Notifications',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount unread • $totalCount total',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '$unreadCount new',
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required bool isRead,
    required String userId,
  }) {
    final accentColor = _getAccentColor(context, item);
    final icon = _getNotificationIcon(item);
    final time = _formatTime(item['createdAt'] as Timestamp?);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _handleTap(item, userId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isRead
                ? Colors.grey.withOpacity(0.12)
                : accentColor.withOpacity(0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withOpacity(0.04)
                  : accentColor.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isRead ? 0.10 : 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (item['title'] ?? 'Notification').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (item['body'] ?? '').toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _getTagText(item),
                          style: GoogleFonts.poppins(
                            color: accentColor,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When technicians update bookings or new bookings arrive, they will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No user found',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.notificationsStream(role: 'admin'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorText = snapshot.error.toString();

            final friendlyMessage =
                errorText.contains('requires an index') ||
                        errorText.contains('currently building')
                    ? 'Notifications are getting ready. Please try again in a moment.'
                    : 'Something went wrong while loading notifications.';

            return _buildErrorState(friendlyMessage);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          int unreadCount = 0;
          for (final item in notifications) {
            final List<dynamic> isReadBy = item['isReadBy'] ?? [];
            if (!isReadBy.contains(user.uid)) {
              unreadCount++;
            }
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: notifications.length + 1,
              separatorBuilder: (_, index) {
                if (index == 0) return const SizedBox(height: 18);
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(
                    context,
                    notifications.length,
                    unreadCount,
                  );
                }

                final item = notifications[index - 1];
                final List<dynamic> isReadBy = item['isReadBy'] ?? [];
                final bool isRead = isReadBy.contains(user.uid);

                return _buildNotificationCard(
                  context: context,
                  item: item,
                  isRead: isRead,
                  userId: user.uid,
                );
              },
            ),
          );
        },
      ),
    );
  }
}