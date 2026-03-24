import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/features/technician/widgets/job_card.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  String? _myWorkshopId;
  bool _isLoadingWorkshop = true;

  @override
  void initState() {
    super.initState();
    _fetchMyWorkshopId();
  }

  Future<void> _fetchMyWorkshopId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _myWorkshopId = doc.data()?['workshopId'];
          _isLoadingWorkshop = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingWorkshop) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myWorkshopId == null) {
      return const Scaffold(
        body: Center(child: Text("No workshop assigned.")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            'Service Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Active Jobs"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('workshopId', isEqualTo: _myWorkshopId)
              .where(
                'assignedTechnicianId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No jobs found for your workshop."),
              );
            }

            final allJobs = snapshot.data!.docs;

            final activeJobs = allJobs.where((doc) {
              final status = (doc.data() as Map<String, dynamic>)['status']
                      ?.toString()
                      .toLowerCase() ??
                  'requested';
              return status != 'completed';
            }).toList();

            final historyJobs = allJobs.where((doc) {
              final status = (doc.data() as Map<String, dynamic>)['status']
                      ?.toString()
                      .toLowerCase() ??
                  'requested';
              return status == 'completed';
            }).toList();

            activeJobs.sort((a, b) => _sortByDate(a, b));
            historyJobs.sort((a, b) => _sortByDate(a, b));

            return TabBarView(
              children: [
                _buildJobList(activeJobs, "No active jobs right now!"),
                _buildJobList(historyJobs, "No completed jobs yet."),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobList(
      List<QueryDocumentSnapshot> jobs, String emptyMessage) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: jobs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final jobData = jobs[index].data() as Map<String, dynamic>;
        final docId = jobs[index].id;

        return JobCard(
          jobData: jobData,
          documentId: docId,
          onStatusUpdate: () =>
              _updateJobStatus(docId, jobData['status']?.toString()),
        );
      },
    );
  }

  int _sortByDate(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
    Timestamp? timeA =
        (a.data() as Map<String, dynamic>)['bookingDate'];
    Timestamp? timeB =
        (b.data() as Map<String, dynamic>)['bookingDate'];

    if (timeA == null) return 1;
    if (timeB == null) return -1;

    return timeB.compareTo(timeA);
  }

  /// 🔥 FIXED STATUS FLOW
  void _updateJobStatus(String docId, String? currentStatus) async {
    final status = currentStatus?.toLowerCase() ?? 'requested';

    String? nextStatus;

    if (status == 'confirmed') {
      nextStatus = 'in_progress';
    } else if (status == 'in_progress') {
      nextStatus = 'completed';
    } else {
      return; // do nothing for requested/completed
    }

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'completed'
                ? "Job Completed!"
                : "Job Started!",
          ),
        ),
      );
    }
  }
}