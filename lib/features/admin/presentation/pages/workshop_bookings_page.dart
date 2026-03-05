import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';

class WorkshopBookingsPage extends StatefulWidget {
  final String workshopId;
  final String workshopName;

  const WorkshopBookingsPage({
    super.key,
    required this.workshopId,
    required this.workshopName,
  });

  @override
  State<WorkshopBookingsPage> createState() => _WorkshopBookingsPageState();
}

class _WorkshopBookingsPageState extends State<WorkshopBookingsPage> {
  final StorageService _storageService = StorageService();

  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All'; // All | Active | Completed
  bool _showPast = true; // show past bookings toggle

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -------- status color mapping --------

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'requested') return Colors.red;
    if (s == 'confirmed') return Colors.orange;
    if (s == 'in_progress') return Colors.blue;
    if (s == 'completed') return Colors.green;
    return Colors.grey;
    // you can add "cancelled" etc here too
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
    }
    return '-';
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Future<void> _changeStatus(String bookingId, String currentStatus) async {
    final statuses = ['requested', 'confirmed', 'in_progress', 'completed'];
    String selected = currentStatus;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Update Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => selected = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result != currentStatus) {
      await _storageService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: result,
      );
      setState(() {});
    }
  }

  // -------- search + filter + sort --------

  List<Map<String, dynamic>> _applySearchFilterSort(
    List<Map<String, dynamic>> bookings,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    // 1) search
    var result = bookings.where((b) {
      if (query.isEmpty) return true;

      final customer = (b['customerName'] ?? '').toString().toLowerCase();
      final phone = (b['customerPhone'] ?? '').toString().toLowerCase();
      final email = (b['customerEmail'] ?? '').toString().toLowerCase();
      final service = (b['serviceType'] ?? '').toString().toLowerCase();

      return customer.contains(query) ||
          phone.contains(query) ||
          email.contains(query) ||
          service.contains(query);
    }).toList();

    // 2) filter
    if (_filter == 'Active') {
      result = result.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s != 'completed';
      }).toList();
    } else if (_filter == 'Completed') {
      result = result.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'completed';
      }).toList();
    }

    // 3) optionally hide past bookings
    if (!_showPast) {
      final now = DateTime.now();
      result = result.where((b) {
        final dt = _timestampToDate(b['slotTime']);
        if (dt == null) return true;
        return dt.isAfter(now.subtract(const Duration(minutes: 1)));
      }).toList();
    }

    // 4) sort by slotTime:
    //    upcoming first; past goes down.
    final now = DateTime.now();
    result.sort((a, b) {
      final aDt = _timestampToDate(a['slotTime']) ?? DateTime(1970);
      final bDt = _timestampToDate(b['slotTime']) ?? DateTime(1970);

      final aIsPast = aDt.isBefore(now);
      final bIsPast = bDt.isBefore(now);

      // upcoming before past
      if (aIsPast != bIsPast) return aIsPast ? 1 : -1;

      // both upcoming: earliest first
      if (!aIsPast && !bIsPast) return aDt.compareTo(bDt);

      // both past: newest past first (recent past on top of past section)
      return bDt.compareTo(aDt);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,

      // Gradient AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    widget.workshopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // -------- SEARCH + FILTER BAR --------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(color: onSurface),
                  decoration: InputDecoration(
                    hintText: "Search customer, phone, email, service...",
                    hintStyle: GoogleFonts.poppins(
                      color: onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: onSurface.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter row
                Row(
                  children: [
                    _filterChip("All"),
                    const SizedBox(width: 8),
                    _filterChip("Active"),
                    const SizedBox(width: 8),
                    _filterChip("Completed"),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          "Show Past",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.8),
                          ),
                        ),
                        Switch(
                          value: _showPast,
                          onChanged: (v) => setState(() => _showPast = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -------- BOOKINGS LIST --------
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _storageService.getBookingsByWorkshop(widget.workshopId),
              builder: (context, snapshot) {
                final rawBookings = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = _applySearchFilterSort(rawBookings);

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      'No bookings found.',
                      style: GoogleFonts.poppins(
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final status = (booking['status'] ?? '').toString();
                    final statusColor = _statusColor(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gradient strip
                          Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['serviceType'] ?? 'Service',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  "Customer: ${booking['customerName'] ?? 'Unknown'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  "Contact: ${booking['customerPhone'] ?? '-'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: onSurface.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  "Email: ${booking['customerEmail'] ?? '-'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: onSurface.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  "Slot Time: ${_formatTimestamp(booking['slotTime'])}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: onSurface.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // ✅ Status badge with changing color
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.7),
                                    ),
                                  ),
                                  child: Text(
                                    "Status: $status",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // ✅ Update (outlined) + Chat (gradient)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _changeStatus(
                                            booking['id'],
                                            (booking['status'] ?? 'requested')
                                                .toString(),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: Text(
                                          "UPDATE",
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GradientButton(
                                        text: "CHAT",
                                        height: 45,
                                        borderRadius: 12,
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Open chat feature next',
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
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------- Filter Chip UI --------
  Widget _filterChip(String label) {
    final selected = _filter == label;

    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primary.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
