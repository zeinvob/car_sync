import 'package:car_sync/core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';

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
        body: const Center(child: Text('No user found')),
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
        stream: _notificationService.notificationsStream(role: 'admin'),
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
              child: Text(
                'No notifications yet',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
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

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () async {
                    await _notificationService.markNotificationAsReadForUser(
                      notificationId: item['id'],
                      userId: user.uid,
                    );

                    final relatedWorkshopId = (item['relatedWorkshopId'] ?? '')
                        .toString();
                    final relatedBookingId = (item['relatedBookingId'] ?? '')
                        .toString();

                    final extraData =
                        (item['extraData'] is Map<String, dynamic>)
                        ? item['extraData'] as Map<String, dynamic>
                        : <String, dynamic>{};

                    final workshopName =
                        (extraData['workshopName'] ?? 'Workshop').toString();

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
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey.withOpacity(0.15)
                        : Colors.red.withOpacity(0.12),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: isRead ? Colors.grey[700] : Colors.red,
                    ),
                  ),
                  title: Text(
                    item['title'] ?? 'Notification',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    item['body'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12),
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
