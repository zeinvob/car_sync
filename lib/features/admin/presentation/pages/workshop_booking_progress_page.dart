import 'package:car_sync/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class WorkshopBookingProgressPage extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String workshopName;

  const WorkshopBookingProgressPage({
    super.key,
    required this.booking,
    required this.workshopName,
  });

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

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final status = (booking['status'] ?? '').toString();

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  booking['serviceType'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Customer: ${booking['customerName'] ?? '-'}",
                  style: GoogleFonts.poppins(fontSize: 13, color: onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  "Workshop: $workshopName",
                  style: GoogleFonts.poppins(fontSize: 13, color: onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  "Vehicle: ${booking['vehicleDisplay'] ?? '-'}",
                  style: GoogleFonts.poppins(fontSize: 13, color: onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  "Booked Slot: ${_formatTimestamp(booking['bookingDate'])}",
                  style: GoogleFonts.poppins(fontSize: 13, color: onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  "Current Status: ${_formatStatusLabel(status)}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Notes: ${(booking['notes'] ?? '').toString().trim().isEmpty ? 'No notes' : booking['notes']}",
                  style: GoogleFonts.poppins(fontSize: 13, color: onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Timeline',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _timelineItem(title: 'Requested', active: true),
                _timelineItem(
                  title: 'Confirmed',
                  active: [
                    'confirmed',
                    'in_progress',
                    'completed',
                  ].contains(status),
                ),
                _timelineItem(
                  title: 'In Progress',
                  active: ['in_progress', 'completed'].contains(status),
                ),
                _timelineItem(
                  title: 'Completed',
                  active: status == 'completed',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required String title,
    required bool active,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: active
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: active ? AppColors.primary : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
