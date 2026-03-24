import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/features/technician/pages/job_details_page.dart';
import 'package:car_sync/features/technician/pages/technician_booking_chat_page.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> jobData;
  final String documentId;
  final VoidCallback onStatusUpdate;

  const JobCard({
    super.key,
    required this.jobData,
    required this.documentId,
    required this.onStatusUpdate,
  });

  /// 🔴 UNREAD COUNT
  Future<int> _getUnreadCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(documentId)
        .collection('messages')
        .where('senderRole', isEqualTo: 'customer')
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final status = (jobData['status'] ?? 'requested').toString();
    final serviceType = jobData['serviceType'] ?? 'Service';

    /// 🔥 CORRECT STATUS LOGIC
    Color buttonColor = Colors.grey;
    String buttonText = "Waiting Approval";
    IconData buttonIcon = Icons.hourglass_empty;
    bool isDisabled = true;

    if (status == 'confirmed') {
      buttonColor = Colors.orange;
      buttonText = "Start Job";
      buttonIcon = Icons.build;
      isDisabled = false;
    } else if (status == 'in_progress') {
      buttonColor = Colors.green;
      buttonText = "Mark Done";
      buttonIcon = Icons.check;
      isDisabled = false;
    } else if (status == 'completed') {
      buttonColor = Colors.grey;
      buttonText = "Completed";
      buttonIcon = Icons.done_all;
      isDisabled = true;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailsPage(
              bookingId: documentId,
              jobData: jobData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  serviceType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Tap to view job details",
              style: GoogleFonts.poppins(fontSize: 13),
            ),

            const SizedBox(height: 16),

            /// 🔹 ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: isDisabled ? null : onStatusUpdate,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ),
                ),

                /// 💬 CHAT + BADGE
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat),
                      color: AppColors.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TechnicianBookingChatPage(
                              bookingId: documentId,
                            ),
                          ),
                        );
                      },
                    ),

                    Positioned(
                      right: 6,
                      top: 6,
                      child: FutureBuilder<int>(
                        future: _getUnreadCount(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          int unread = snapshot.data!;

                          if (unread == 0) {
                            return const SizedBox();
                          }

                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}