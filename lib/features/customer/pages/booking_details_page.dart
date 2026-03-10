import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/chat_service.dart';
import 'package:car_sync/core/services/image_picker_service.dart';
import 'package:car_sync/core/services/file_upload_service.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Status order for progress tracking
  final List<Map<String, dynamic>> _statusSteps = [
    {
      'status': 'requested',
      'label': 'Requested',
      'icon': Icons.pending_actions,
      'description':
          'Your booking request has been submitted. Waiting for admin to review. This process usually takes 1-2 hours.',
    },
    {
      'status': 'confirmed',
      'label': 'Confirmed',
      'icon': Icons.check_circle,
      'description':
          'Your booking has been confirmed by the admin. Please arrive at the workshop on your scheduled date.',
    },
    {
      'status': 'in_progress',
      'label': 'In Progress',
      'icon': Icons.build_circle,
      'description':
          'Your vehicle is currently being serviced. The technician will update the progress below.',
    },
    {
      'status': 'completed',
      'label': 'Completed',
      'icon': Icons.task_alt,
      'description':
          'Service completed! Your vehicle is ready for pickup. Thank you for choosing us.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  int _getStatusIndex(String status) {
    final index = _statusSteps.indexWhere(
      (s) => s['status'] == status.toLowerCase(),
    );
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.booking['id'] ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChatDialog(context, bookingId),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Booking not found',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final bookingData = snapshot.data!.data() as Map<String, dynamic>;
          bookingData['id'] = bookingId;

          final currentStatus = (bookingData['status'] ?? 'requested')
              .toString()
              .toLowerCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHorizontalProgressTracker(bookingData),
                const SizedBox(height: 24),
                _buildStatusTimeline(bookingData, bookingId),
                if (currentStatus == 'requested') ...[
                  const SizedBox(height: 24),
                  _buildCancelButton(bookingId),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalProgressTracker(Map<String, dynamic> booking) {
    final currentStatus = (booking['status'] ?? 'requested')
        .toString()
        .toLowerCase();
    final currentIndex = _getStatusIndex(currentStatus);
    final isCancelled = currentStatus == 'cancelled';

    if (isCancelled) {
      return _buildCancelledStatus();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Tracking',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(_statusSteps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isCompleted
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                );
              } else {
                // Circle icon
                final stepIndex = index ~/ 2;
                final step = _statusSteps[stepIndex];
                final isCompleted = stepIndex <= currentIndex;
                final isCurrent = stepIndex == currentIndex;

                return _buildStepCircle(
                  icon: step['icon'],
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                );
              }
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _statusSteps.map((step) {
              final stepIndex = _statusSteps.indexOf(step);
              final isCompleted = stepIndex <= currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return SizedBox(
                width: 70,
                child: Text(
                  step['label'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle({
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: AppColors.primary, width: 3)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isCompleted ? Colors.white : Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Cancelled',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'This booking has been cancelled',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Map<String, dynamic> booking, String bookingId) {
    final currentStatus = (booking['status'] ?? 'requested')
        .toString()
        .toLowerCase();
    final currentIndex = _getStatusIndex(currentStatus);
    final isCancelled = currentStatus == 'cancelled';

    if (isCancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status History',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Only show statuses that have been reached (completed or current)
          ...List.generate(_statusSteps.length, (index) {
            final step = _statusSteps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            // Skip statuses that haven't been reached yet
            if (!isCompleted && !isCurrent) {
              return const SizedBox.shrink();
            }

            // Find the last visible item for proper styling
            final isLastVisible = index == currentIndex;

            return _buildStatusHistoryItem(
              status: step['status'],
              label: step['label'],
              icon: step['icon'],
              description: step['description'],
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              timestamp: _getTimestampForStatus(booking, step['status']),
              isLast: isLastVisible,
              booking: booking,
              bookingId: bookingId,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusHistoryItem({
    required String status,
    required String label,
    required IconData icon,
    required String description,
    required bool isCompleted,
    required bool isCurrent,
    required String? timestamp,
    required bool isLast,
    required Map<String, dynamic> booking,
    required String bookingId,
  }) {
    final showTechnicianUpdates =
        status == 'in_progress' && (isCompleted || isCurrent);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Point and Line
          Column(
            children: [
              // Point/Dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              // Vertical Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Current',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (timestamp != null && isCompleted)
                    Text(
                      timestamp,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    )
                  else if (!isCompleted)
                    Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  // Status Description
                  if (isCurrent || isCompleted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  // Technician Updates for In Progress
                  if (showTechnicianUpdates) _buildTechnicianUpdates(bookingId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianUpdates(String bookingId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('repairUpdates')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 18,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Waiting for technician to start inspection...',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final updates = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.engineering, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Technician Updates',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...updates.map((doc) {
                final update = doc.data() as Map<String, dynamic>;
                return _buildUpdateItem(update);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final type = update['type'] ?? 'update';
    final title = update['title'] ?? 'Update';
    final description = update['description'] ?? '';

    // Handle photos as either a single string or an array
    List<String> photos = [];
    final photosData = update['photos'];
    if (photosData is List) {
      photos = photosData.map((e) => e.toString()).toList();
    } else if (photosData is String && photosData.isNotEmpty) {
      photos = [photosData];
    }

    String timeStr = '';
    if (update['createdAt'] != null) {
      try {
        final date = (update['createdAt'] as Timestamp).toDate();
        timeStr =
            '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    IconData typeIcon;
    Color typeColor;
    switch (type) {
      case 'inspection':
        typeIcon = Icons.search;
        typeColor = Colors.blue;
        break;
      case 'problem_found':
        typeIcon = Icons.warning_amber;
        typeColor = Colors.orange;
        break;
      case 'repair':
        typeIcon = Icons.build;
        typeColor = Colors.green;
        break;
      case 'parts':
        typeIcon = Icons.settings;
        typeColor = Colors.purple;
        break;
      case 'testing':
        typeIcon = Icons.speed;
        typeColor = Colors.teal;
        break;
      default:
        typeIcon = Icons.info_outline;
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
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
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showPhotoFullScreen(photos[index]),
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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

  void _showPhotoFullScreen(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(photoUrl, fit: BoxFit.contain),
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

  String? _getTimestampForStatus(Map<String, dynamic> booking, String status) {
    // Check for status history timestamps
    final statusHistory = booking['statusHistory'] as Map<String, dynamic>?;
    if (statusHistory != null && statusHistory[status] != null) {
      try {
        final date = (statusHistory[status] as Timestamp).toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // Fallback: show createdAt for requested
    if (status == 'requested' && booking['createdAt'] != null) {
      try {
        final date = (booking['createdAt'] as Timestamp).toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // Fallback: show updatedAt for confirmed status
    if (status == 'confirmed' && booking['updatedAt'] != null) {
      try {
        final date = (booking['updatedAt'] as Timestamp).toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // Fallback: show updatedAt for current status
    final currentStatus = (booking['status'] ?? '').toString().toLowerCase();
    if (status == currentStatus && booking['updatedAt'] != null) {
      try {
        final date = (booking['updatedAt'] as Timestamp).toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return null;
  }

  Widget _buildCancelButton(String bookingId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelBookingDialog(bookingId),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: Text(
          'Cancel Booking',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showCancelBookingDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep It',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking cancelled successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to previous page
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to cancel booking: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChatDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) =>
          _ChatDialog(bookingId: bookingId, firestore: _firestore),
    );
  }
}

class _ChatDialog extends StatefulWidget {
  final String bookingId;
  final FirebaseFirestore firestore;

  const _ChatDialog({required this.bookingId, required this.firestore});

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isSendingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat with Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),
            // Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.firestore
                    .collection('bookings')
                    .doc(widget.bookingId)
                    .collection('messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a message to the admin',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe =
                          message['senderId'] ==
                          FirebaseAuth.instance.currentUser?.uid;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 4),
                // Image attachment button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSendingImage ? null : _pickAndSendImage,
                    icon: _isSendingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.image,
                            color: Colors.grey.shade700,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Use smaller size for base64 storage in Firestore
    final file = await _imagePickerService.pickFromGallery(
      maxWidth: 400,
      quality: 60,
    );
    if (file == null) return;

    setState(() => _isSendingImage = true);

    try {
      // Get user name
      final userDoc = await widget.firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userName = userData['fullName'] ?? userData['name'] ?? 'Customer';

      // Convert image to base64
      final imageBase64 = await _fileUploadService.imageToBase64(file);

      await _chatService.sendImageMessage(
        bookingId: widget.bookingId,
        senderId: user.uid,
        senderName: userName,
        senderRole: 'customer',
        imageUrl: imageBase64,  // Store base64 string
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['text'] ?? '';
    final senderName = message['senderName'] ?? 'Unknown';
    final senderRole = message['senderRole'] ?? '';
    final messageType = message['type'] ?? 'text';
    final imageUrl = message['imageUrl'];

    String timeStr = '';
    if (message['createdAt'] != null) {
      try {
        final date = (message['createdAt'] as Timestamp).toDate();
        timeStr =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  '$senderName ${senderRole.isNotEmpty ? '($senderRole)' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: messageType == 'image'
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
              ),
              child: messageType == 'image' && imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          width: 180,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                timeStr,
                style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _messageController.clear();

    try {
      // Get user data for name
      final userDoc = await widget.firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userName = userData['fullName'] ?? userData['name'] ?? 'Customer';

      await widget.firestore
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('messages')
          .add({
            'text': text,
            'senderId': user.uid,
            'senderName': userName,
            'senderRole': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
