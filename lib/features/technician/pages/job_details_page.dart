import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:car_sync/core/constants/app_colors.dart';

class JobDetailsPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> jobData;

  const JobDetailsPage({super.key, required this.bookingId, required this.jobData});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  // Fetches vehicle details from the 'vehicles' collection
  Future<Map<String, dynamic>?> _getVehicleDetails() async {
    try {
      String? vehicleId = widget.jobData['vehicleId']; 
      if (vehicleId == null) return null;

      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error fetching vehicle: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Job Progress", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. HEADER & MAIN INSPECTION PHOTO (Live Streamed!)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
            builder: (context, statusSnap) {
              if (!statusSnap.hasData) return const SizedBox.shrink();
              
              final bookingData = statusSnap.data!.data() as Map<String, dynamic>?;
              String currentStatus = bookingData?['status'] ?? widget.jobData['status'] ?? 'pending';
              
              // This is the string URL we saved from the Home Screen camera!
              String? mainPictureUrl = bookingData?['picture']; 

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- VEHICLE INFO BOX ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getVehicleDetails(),
                          builder: (context, vehicleSnap) {
                            final vData = vehicleSnap.data;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${vData?['brand'] ?? 'Loading...'} ${vData?['model'] ?? ''}",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Plate: ${vData?['plateNumber'] ?? 'Checking...'}",
                                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                                ),
                              ],
                            );
                          }
                        ),
                        // Dynamic Status Chip
                        Chip(
                          label: Text(currentStatus.toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: _getStatusColor(currentStatus),
                        ),
                      ],
                    ),
                  ),

                  // --- MAIN INSPECTION PHOTO ---
                  if (mainPictureUrl != null && mainPictureUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Initial Inspection Photo", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              mainPictureUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 180, 
                                  child: Center(child: CircularProgressIndicator())
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
          ),

          // 2. REPAIR TIMELINE SECTION
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .collection('repairUpdates')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No updates yet.\nTap 'Add Photo' to document progress.", 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey)
                    )
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 80), // Bottom padding so FAB doesn't block last item
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    Timestamp? ts = data['createdAt'] as Timestamp?;
                    String? timelineImageUrl = data['imageUrl'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.build, size: 14, color: Colors.white)
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(data['title'] ?? 'Work Update', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  ts != null ? "${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}" : '',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(data['description'] ?? '', style: GoogleFonts.poppins(fontSize: 13)),
                            
                            // IF THIS TIMELINE UPDATE HAS A PHOTO, SHOW IT!
                            if (timelineImageUrl != null && timelineImageUrl.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  timelineImageUrl, 
                                  height: 150, 
                                  width: double.infinity, 
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // 3. UPDATED FAB: ACTUALLY OPENS CAMERA AND UPLOADS!
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _addTimelinePhoto(),
        label: Text("Add Photo", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  // Helper function for the status chip colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green[200]!;
      case 'in_progress': return Colors.orange[200]!;
      case 'inspecting': return Colors.blue[200]!;
      default: return Colors.grey[300]!;
    }
  }

  // --- ACTIONS ---
  // This now opens the camera, uploads the photo, and adds it to the timeline!
  Future<void> _addTimelinePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (pickedFile == null) return; 

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      final file = File(pickedFile.path);
      final fileName = 'timeline_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('bookings')
          .child(widget.bookingId)
          .child('timeline')
          .child(fileName);

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;

      // Add to the subcollection with the new image URL!
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('repairUpdates')
          .add({
        'title': 'Progress Photo',
        'description': 'Technician added a new update photo.',
        'imageUrl': downloadUrl, // Saves the picture here
        'createdAt': FieldValue.serverTimestamp(),
        'technicianId': user?.uid,
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo added to timeline!"))
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}