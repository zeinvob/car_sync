import 'package:car_sync/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WorkshopBookingProgressPage extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String workshopName;

  const WorkshopBookingProgressPage({
    super.key,
    required this.booking,
    required this.workshopName,
  });

  static const List<Map<String, dynamic>> _statusSteps = [
    {
      'status': 'requested',
      'label': 'Requested',
      'icon': Icons.receipt_long_rounded,
      'description': 'Booking request submitted by customer.',
    },
    {
      'status': 'confirmed',
      'label': 'Confirmed',
      'icon': Icons.event_available_rounded,
      'description': 'Booking confirmed by workshop admin.',
    },
    {
      'status': 'in_progress',
      'label': 'In Progress',
      'icon': Icons.build_circle_rounded,
      'description': 'Vehicle is currently being inspected or repaired.',
    },
    {
      'status': 'completed',
      'label': 'Completed',
      'icon': Icons.task_alt_rounded,
      'description': 'Service completed and vehicle is ready.',
    },
  ];

  String _formatStatusLabel(String status) {
    final value = status.trim().toLowerCase();

    switch (value) {
      case 'requested':
        return 'Requested';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return value
            .split('_')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return _formatDateTime(value.toDate());
    }
    return '-';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Colors.deepOrange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.amber.shade800;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _getStatusIndex(String status) {
    final index = _statusSteps.indexWhere(
      (s) => s['status'] == status.toLowerCase(),
    );
    return index >= 0 ? index : 0;
  }

  String? _getTimestampForStatus(Map<String, dynamic> booking, String status) {
    final rawStatusHistory = booking['statusHistory'];
    final Map<String, dynamic>? statusHistory = rawStatusHistory is Map
        ? Map<String, dynamic>.from(rawStatusHistory)
        : null;

    if (statusHistory != null && statusHistory[status] != null) {
      try {
        final date = (statusHistory[status] as Timestamp).toDate();
        return _formatDateTime(date);
      } catch (_) {}
    }

    if (status == 'requested' && booking['createdAt'] != null) {
      try {
        final date = (booking['createdAt'] as Timestamp).toDate();
        return _formatDateTime(date);
      } catch (_) {}
    }

    final currentStatus = (booking['status'] ?? '').toString().toLowerCase();
    if (status == currentStatus && booking['updatedAt'] != null) {
      try {
        final date = (booking['updatedAt'] as Timestamp).toDate();
        return _formatDateTime(date);
      } catch (_) {}
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final status = (booking['status'] ?? 'requested').toString().toLowerCase();
    final bookingId = (booking['id'] ?? '').toString();
    final currentIndex = _getStatusIndex(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Progress',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(context, status),
          const SizedBox(height: 16),
          _buildBookingInfoCard(context, onSurface, cardColor, status),
          const SizedBox(height: 16),
          _buildProgressOverview(context, currentIndex, status),
          const SizedBox(height: 16),
          _buildTimelineCard(context, bookingId, status),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String status) {
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.timeline_rounded,
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
                  booking['serviceType'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  workshopName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    _formatStatusLabel(status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard(
    BuildContext context,
    Color onSurface,
    Color cardColor,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.person_rounded,
            'Customer',
            booking['customerName'] ?? '-',
            onSurface,
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.directions_car_filled_rounded,
            'Vehicle',
            booking['vehicleDisplay'] ?? '-',
            onSurface,
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.calendar_month_rounded,
            'Booked Slot',
            _formatTimestamp(booking['bookingDate']),
            onSurface,
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.sticky_note_2_rounded,
            'Notes',
            (booking['notes'] ?? '').toString().trim().isEmpty
                ? 'No notes'
                : booking['notes'].toString(),
            onSurface,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value, Color onSurface) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverview(
    BuildContext context,
    int currentIndex,
    String currentStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(_statusSteps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isDone = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final step = _statusSteps[stepIndex];
              final isCompleted = stepIndex <= currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return _buildStepBubble(
                icon: step['icon'] as IconData,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _statusSteps.map((step) {
              final index = _statusSteps.indexOf(step);
              final isActive = index <= currentIndex;

              return SizedBox(
                width: 70,
                child: Text(
                  step['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
          if (currentStatus == 'cancelled') ...[
            const SizedBox(height: 14),
            Text(
              'This booking has been cancelled.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepBubble({
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.primary : Colors.grey.shade200,
        border: isCurrent
            ? Border.all(color: AppColors.primary, width: 3)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 20,
        color: isCompleted ? Colors.white : Colors.grey,
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    String bookingId,
    String currentStatus,
  ) {
    final currentIndex = _getStatusIndex(currentStatus);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Timeline',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(_statusSteps.length, (index) {
            final step = _statusSteps[index];
            final stepStatus = step['status'] as String;
            final isReached = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == _statusSteps.length - 1;

            return _buildTimelineItem(
              context: context,
              title: step['label'] as String,
              description: step['description'] as String,
              icon: step['icon'] as IconData,
              statusKey: stepStatus,
              timestamp: _getTimestampForStatus(booking, stepStatus),
              active: isReached,
              isCurrent: isCurrent,
              isLast: isLast,
              bookingId: bookingId,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required String statusKey,
    required String? timestamp,
    required bool active,
    required bool isCurrent,
    required bool isLast,
    required String bookingId,
  }) {
    final lineColor = active ? AppColors.primary : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: active
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withOpacity(0.06)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary.withOpacity(0.18)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: active ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Current',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timestamp ?? 'Waiting...',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: timestamp != null
                                ? Colors.grey[700]
                                : Colors.grey[500],
                            fontWeight: timestamp != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (statusKey == 'in_progress' && active) ...[
                      const SizedBox(height: 14),
                      _buildRepairUpdates(bookingId),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairUpdates(String bookingId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('repairUpdates')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No repair updates yet. Waiting for technician updates.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Updates',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildRepairUpdateCard(context, data);
            }),
          ],
        );
      },
    );
  }

  Widget _buildRepairUpdateCard(
    BuildContext context,
    Map<String, dynamic> update,
  ) {
    final type = (update['type'] ?? 'update').toString();
    final title = (update['title'] ?? 'Update').toString();
    final description = (update['description'] ?? '').toString();

    List<String> photos = [];
    final photosData = update['photos'];
    if (photosData is List) {
      photos = photosData.map((e) => e.toString()).toList();
    } else if (photosData is String && photosData.isNotEmpty) {
      photos = [photosData];
    }

    final createdAt = update['createdAt'];
    String timeText = '-';
    if (createdAt is Timestamp) {
      timeText = _formatDateTime(createdAt.toDate());
    }

    IconData icon;
    Color color;

    switch (type) {
      case 'inspection':
        icon = Icons.search_rounded;
        color = Colors.blue;
        break;
      case 'problem_found':
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case 'repair':
        icon = Icons.build_rounded;
        color = Colors.green;
        break;
      case 'parts':
        icon = Icons.settings_rounded;
        color = Colors.purple;
        break;
      case 'testing':
        icon = Icons.speed_rounded;
        color = Colors.teal;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.45,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showPhotoFullScreen(context, photos[index]),
                    child: Container(
                      width: 86,
                      height: 86,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoFullScreen(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(photoUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
