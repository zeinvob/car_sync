import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/features/technician/pages/job_details_page.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> jobData;
  final String documentId;
  final VoidCallback onStatusUpdate;
  final VoidCallback onCameraTap;

  const JobCard({
    super.key,
    required this.jobData,
    required this.documentId,
    required this.onStatusUpdate,
    required this.onCameraTap,
  });

  Future<Map<String, dynamic>?> _getVehicleDetails() async {
    try {
      String? vehicleId = jobData['vehicleId']; 
      if (vehicleId == null) return null;

      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    String status = jobData['status']?.toLowerCase() ?? 'pending';
    String serviceType = jobData['serviceType'] ?? 'General Service';
    
    // --- NEW: 4 STAGES OF JOB PROGRESS ---
    bool isPending = status == 'pending';
    bool isInspecting = status == 'inspecting';
    bool isRepairing = status == 'in_progress';
    bool isCompleted = status == 'completed';

    String timeString = "No Time";

    if (isCompleted) {
      Timestamp? ts = jobData['updatedAt'] as Timestamp? ?? jobData['bookingDate'] as Timestamp?;
      if (ts != null) {
        DateTime date = ts.toDate();
        timeString = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      }
    } else {
      if (jobData['bookingDate'] != null) {
        DateTime date = (jobData['bookingDate'] as Timestamp).toDate();
        timeString = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      }
    }

    // --- NEW: DYNAMIC BUTTON LOGIC ---
    Color buttonColor = Colors.blueAccent;
    String buttonText = 'Start Inspection';
    IconData buttonIcon = Icons.search_rounded;

    if (isInspecting) {
      buttonColor = Colors.orange;
      buttonText = 'Start Repair';
      buttonIcon = Icons.build_rounded;
    } else if (isRepairing) {
      buttonColor = Colors.green;
      buttonText = 'Mark Done';
      buttonIcon = Icons.check_circle_rounded;
    } else if (isCompleted) {
      buttonColor = Colors.grey;
      buttonText = 'Completed';
      buttonIcon = Icons.done_all_rounded;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsPage(bookingId: documentId, jobData: jobData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: onSurface.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeString, style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Text('#${documentId.substring(0, 6).toUpperCase()}', style: GoogleFonts.poppins(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
            Divider(color: onSurface.withOpacity(0.1), height: 24),
            
            Text('Vehicle Detail:', style: GoogleFonts.poppins(fontSize: 11, color: onSurface.withOpacity(0.6))),
            
            FutureBuilder<Map<String, dynamic>?>(
              future: _getVehicleDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading vehicle...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
                }
                
                final vData = snapshot.data;
                String plate = vData?['plateNumber'] ?? 'No Plate';
                String vehicleName = "${vData?['brand'] ?? 'Unknown'} ${vData?['model'] ?? 'Vehicle'}";

                return Text(
                  "$plate - $vehicleName", 
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)
                );
              }
            ),
            
            const SizedBox(height: 8),
            Text('Issue: $serviceType', style: GoogleFonts.poppins(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: isCompleted ? null : onStatusUpdate,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                
                // The Camera Button: Remains active as long as the job isn't finished!
                if (!isCompleted) 
                  Container(
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      onPressed: onCameraTap,
                      icon: const Icon(Icons.camera_alt_rounded),
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}