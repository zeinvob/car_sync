import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final status = (jobData['status'] ?? 'pending').toString().toLowerCase();
    final serviceType = jobData['serviceType'] ?? 'Service';
    final customerName = jobData['customerName'] ?? 'Customer';
    final vehicleInfo = jobData['vehicleInfo'] ?? '';
    final bookingDate = jobData['bookingDate'] as Timestamp?;
    final notes = jobData['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  serviceType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Vehicle info
                if (vehicleInfo.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.directions_car_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vehicleInfo,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Date
                if (bookingDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(bookingDate.toDate()),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Notes
                if (notes.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Camera button
                IconButton(
                  onPressed: onCameraTap,
                  icon: const Icon(Icons.camera_alt_outlined),
                  color: AppColors.primary,
                  tooltip: 'Upload Photo',
                ),
                const Spacer(),
                // Update status button
                if (status != 'completed')
                  ElevatedButton.icon(
                    onPressed: onStatusUpdate,
                    icon: Icon(_getNextStatusIcon(status), size: 18),
                    label: Text(
                      _getNextStatusLabel(status),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(status),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (status == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'inspecting':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'inspecting':
        return 'Inspecting';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  String _getNextStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Start Inspection';
      case 'inspecting':
        return 'Start Repair';
      case 'in_progress':
        return 'Mark Complete';
      default:
        return 'Update';
    }
  }

  IconData _getNextStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.search;
      case 'inspecting':
        return Icons.build;
      case 'in_progress':
        return Icons.check;
      default:
        return Icons.arrow_forward;
    }
  }
}
