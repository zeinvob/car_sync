import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/features/technician/pages/technician_booking_chat_page.dart';

class JobDetailsPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> jobData;

  const JobDetailsPage({
    super.key,
    required this.bookingId,
    required this.jobData,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  /// 🔥 GET VEHICLE
  Future<Map<String, dynamic>?> _getVehicle() async {
    final firestore = FirebaseFirestore.instance;

    if (widget.jobData['vehicleId'] != null) {
      final doc = await firestore
          .collection('vehicles')
          .doc(widget.jobData['vehicleId'])
          .get();
      return doc.data();
    }

    final customerId = widget.jobData['customerId'];
    if (customerId == null) return null;

    final snapshot = await firestore
        .collection('vehicles')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data();
  }

  /// 🔥 FIXED STATUS UPDATE (NO INSPECTING)
  Future<void> _updateStatus() async {
    String current =
        (widget.jobData['status'] ?? 'requested').toString().toLowerCase();

    String? next;

    if (current == 'confirmed') {
      next = 'in_progress';
    } else if (current == 'in_progress') {
      next = 'completed';
    } else {
      return; // do nothing for requested/completed
    }

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    /// send to chat
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('messages')
        .add({
      'type': 'text',
      'text': "Status updated to ${next.replaceAll('_', ' ')}",
      'senderRole': 'technician',
      'senderName': 'Technician',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      widget.jobData['status'] = next!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.jobData;

    /// 🔥 SAFETY: remove old inspecting if still exists
    String status = (data['status'] ?? 'requested').toString();
    if (status == 'inspecting') {
      status = 'in_progress';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Job Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TechnicianBookingChatPage(
                    bookingId: widget.bookingId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔥 SERVICE + STATUS
            Card(
              child: ListTile(
                title: Text(data['serviceType'] ?? 'Service'),
                subtitle: Text("Status: $status"),
              ),
            ),

            const SizedBox(height: 10),

            /// 🚗 VEHICLE INFO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _getVehicle(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text("Loading vehicle...");
                    }

                    final v = snapshot.data;

                    if (v == null) {
                      return const Text("No vehicle info");
                    }

                    final plate = v['plateNumber'] ?? '';
                    final brand = v['brand'] ?? '';
                    final model = v['model'] ?? '';
                    final year = v['year'] ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$plate • $brand $model",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Year: $year"),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 STATUS BUTTON
            ElevatedButton(
              onPressed: _updateStatus,
              child: const Text("Update Status"),
            ),

            const SizedBox(height: 20),

            /// 🔥 RECENT CHAT
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(widget.bookingId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No updates yet"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final msg =
                          docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(msg['text'] ?? ''),
                          subtitle: Text(msg['senderRole'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}