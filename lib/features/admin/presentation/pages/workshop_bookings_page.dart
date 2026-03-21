import 'dart:io';
import 'dart:convert';
import 'package:map_launcher/map_launcher.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/chat_service.dart';
import 'package:car_sync/core/services/document_picker_service.dart';
import 'package:car_sync/core/services/file_upload_service.dart';
import 'package:car_sync/core/services/image_picker_service.dart';
import 'package:car_sync/core/services/location_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_booking_progress_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkshopBookingsPage extends StatefulWidget {
  final String workshopId;
  final String workshopName;
  final String? highlightBookingId;

  const WorkshopBookingsPage({
    super.key,
    required this.workshopId,
    required this.workshopName,
    this.highlightBookingId,
  });

  @override
  State<WorkshopBookingsPage> createState() => _WorkshopBookingsPageState();
}

//
class _WorkshopBookingsPageState extends State<WorkshopBookingsPage> {
  final WorkshopService _workshopService = WorkshopService();
  final ChatService _chatService = ChatService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final DocumentPickerService _documentPickerService = DocumentPickerService();
  final LocationService _locationService = LocationService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _filter = 'All';
  bool _showPast = true;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'requested') return Colors.red;
    if (s == 'confirmed') return Colors.orange;
    if (s == 'in_progress') return Colors.blue;
    if (s == 'completed') return Colors.green;
    if (s == 'pending') return Colors.red;
    if (s == 'cancelled') return Colors.grey;
    return Colors.grey;
  }

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

  String _formatTimeOnly(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('hh:mm a').format(value.toDate());
    }
    return '-';
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Future<void> _openInGoogleMaps({
    required double latitude,
    required double longitude,
    String title = 'Shared Location',
  }) async {
    final availableMaps = await MapLauncher.installedMaps;

    if (availableMaps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No map application found')),
        );
      }
      return;
    }

    final googleMaps = availableMaps
        .where((map) => map.mapType == MapType.google)
        .toList();

    if (googleMaps.isNotEmpty) {
      await googleMaps.first.showMarker(
        coords: Coords(latitude, longitude),
        title: title,
      );
      return;
    }

    await availableMaps.first.showMarker(
      coords: Coords(latitude, longitude),
      title: title,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link')));
    }
  }

  Future<void> _pickAndSendImage(String bookingId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        }
        return;
      }

      final file = await _imagePickerService.pickFromGallery();
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No image selected')));
        }
        return;
      }

      final imageBase64 = await _fileUploadService.imageToBase64(file);

      await _chatService.sendImageMessage(
        bookingId: bookingId,
        senderId: user.uid,
        senderName: widget.workshopName,
        senderRole: 'workshop',
        imageUrl: imageBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent successfully')),
        );
      }
    } catch (e) {
      debugPrint('Send image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
      }
    }
  }

  Future<void> _pickAndSendDocument(String bookingId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        }
        return;
      }

      final picked = await _documentPickerService.pickAnyFileWithInfo();

      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected')));
        }
        return;
      }

      final file = picked['file'] as File;
      final fileName = picked['name'].toString();
      final extension = picked['extension'].toString();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selected: $fileName')));
      }

      final fileUrl = await _fileUploadService.uploadChatFile(
        file: file,
        bookingId: bookingId,
        fileName: fileName,
      );

      await _chatService.sendFileMessage(
        bookingId: bookingId,
        senderId: user.uid,
        senderName: widget.workshopName,
        senderRole: 'workshop',
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: extension,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File sent successfully')));
      }
    } catch (e) {
      debugPrint('File picker/send error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
      }
    }
  }

  Future<void> _shareCurrentLocation(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final position = await _locationService.getCurrentLocation();
    if (position == null) return;

    await _chatService.sendLocationMessage(
      bookingId: bookingId,
      senderId: user.uid,
      senderName: widget.workshopName,
      senderRole: 'workshop',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _openLocationInMap(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFileUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _changeStatus(
    String bookingId,
    String currentStatus, {
    String? currentTechnicianId,
  }) async {
    final statuses = [
      'requested',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
    ];

    String selectedStatus = currentStatus;
    String? technicianError;

    String? selectedTechnicianId =
        (currentTechnicianId != null && currentTechnicianId.trim().isNotEmpty)
        ? currentTechnicianId
        : null;

    List<Map<String, dynamic>> technicians = [];
    try {
      technicians = await _workshopService.getWorkshopTechnicians(
        widget.workshopId,
      );
    } catch (_) {
      technicians = [];
    }

    final Map<String, Map<String, dynamic>> uniqueTechnicians = {};
    for (final tech in technicians) {
      final id = (tech['id'] ?? '').toString().trim();
      if (id.isNotEmpty) {
        uniqueTechnicians[id] = tech;
      }
    }
    final technicianList = uniqueTechnicians.values.toList();

    if (selectedTechnicianId != null &&
        !technicianList.any(
          (tech) => tech['id'].toString() == selectedTechnicianId,
        )) {
      selectedTechnicianId = null;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              title: Text(
                'Update Booking',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            _formatStatusLabel(status),
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                            if (selectedStatus != 'confirmed') {
                              technicianError = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String?>(
                      value: selectedTechnicianId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Assign Technician',
                        labelStyle: GoogleFonts.poppins(),
                        errorText: technicianError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'No Technician',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        ...technicianList.map((tech) {
                          return DropdownMenuItem<String?>(
                            value: tech['id'].toString(),
                            child: Text(
                              tech['name'].toString(),
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTechnicianId = value;
                          technicianError = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                SizedBox(
                  width: 110,
                  child: GradientButton(
                    text: "Save",
                    height: 45,
                    borderRadius: 12,
                    onPressed: () {
                      if (selectedStatus == 'confirmed' &&
                          (selectedTechnicianId == null ||
                              selectedTechnicianId!.trim().isEmpty)) {
                        setDialogState(() {
                          technicianError =
                              'Technician is required when status is Confirmed';
                        });
                        return;
                      }

                      Navigator.pop(context, {
                        'status': selectedStatus,
                        'technicianId': selectedTechnicianId,
                      });
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _workshopService.updateBookingStatusAndTechnician(
        bookingId: bookingId,
        newStatus: result['status'].toString(),
        technicianId: result['technicianId']?.toString(),
      );

      if (mounted) setState(() {});
    }
  }

  Future<void> _showAttachmentMenu(String bookingId) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text('Send Image', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text('Send File', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text('Share Location', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, 'location'),
              ),
            ],
          ),
        );
      },
    );

    if (choice == 'image') {
      await _pickAndSendImage(bookingId);
    } else if (choice == 'file') {
      await _pickAndSendDocument(bookingId);
    } else if (choice == 'location') {
      await _shareCurrentLocation(bookingId);
    }
  }

  void _showChatPopup(Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? '').toString();
    if (bookingId.isEmpty) return;

    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = Theme.of(context).dialogBackgroundColor;
        final cardBg = Theme.of(context).cardColor;
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return Dialog(
          backgroundColor: dialogBg,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            height: 540,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Booking Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chatService.streamBookingMessages(bookingId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No chat messages yet.',
                            style: GoogleFonts.poppins(
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final sender = (data['senderName'] ?? 'Unknown')
                              .toString();
                          final senderRole = (data['senderRole'] ?? '')
                              .toString();
                          final messageType = (data['type'] ?? 'text')
                              .toString();
                          final messageText =
                              (data['text'] ?? data['message'] ?? '')
                                  .toString();

                          final isMe =
                              senderRole == 'workshop' || senderRole == 'admin';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.68,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary
                                    : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : Colors.grey.shade100),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.black.withOpacity(0.05),
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? 'You' : sender,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isMe
                                          ? Colors.white.withOpacity(0.9)
                                          : onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (messageType == 'text')
                                    Text(
                                      messageText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isMe ? Colors.white : onSurface,
                                      ),
                                    ),
                                  if (messageType == 'image')
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if ((data['imageUrl'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Builder(
                                            builder: (context) {
                                              final imageData =
                                                  (data['imageUrl'] ?? '')
                                                      .toString()
                                                      .trim();

                                              Widget previewImage;
                                              Widget fullImage;

                                              try {
                                                final decodedBytes =
                                                    base64Decode(imageData);

                                                previewImage = Image.memory(
                                                  decodedBytes,
                                                  width: 170,
                                                  height: 125,
                                                  fit: BoxFit.cover,
                                                );

                                                fullImage = Image.memory(
                                                  decodedBytes,
                                                  fit: BoxFit.contain,
                                                );
                                              } catch (e) {
                                                previewImage = Container(
                                                  width: 170,
                                                  height: 125,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                );

                                                fullImage = const Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                );
                                              }

                                              return GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      child: Stack(
                                                        children: [
                                                          InteractiveViewer(
                                                            child: fullImage,
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            right: 10,
                                                            child: IconButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                                size: 30,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: previewImage,
                                                ),
                                              );
                                            },
                                          ),
                                        if (messageText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            messageText,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: isMe
                                                  ? Colors.white
                                                  : onSurface,
                                            ),
                                          ),
                                        ],
                                        if (messageText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            messageText,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: isMe
                                                  ? Colors.white
                                                  : onSurface,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  if (messageType == 'file')
                                    InkWell(
                                      onTap: () {
                                        final url = (data['fileUrl'] ?? '')
                                            .toString();
                                        if (url.isNotEmpty) {
                                          _openFileUrl(url);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.insert_drive_file_outlined,
                                            color: isMe
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              (data['fileName'] ?? 'Document')
                                                  .toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: isMe
                                                    ? Colors.white
                                                    : onSurface,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (messageType == 'location')
                                    InkWell(
                                      onTap: () async {
                                        final mapUrl = (data['mapUrl'] ?? '')
                                            .toString();
                                        final lat = (data['latitude'] as num?)
                                            ?.toDouble();
                                        final lng = (data['longitude'] as num?)
                                            ?.toDouble();

                                        if (mapUrl.isNotEmpty) {
                                          await _openUrl(mapUrl);
                                        } else if (lat != null && lng != null) {
                                          await _openUrl(
                                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                          );
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  messageText.isEmpty
                                                      ? 'Shared Location'
                                                      : messageText,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: isMe
                                                        ? Colors.white
                                                        : onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Open in Google Maps',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: isMe
                                                  ? Colors.white70
                                                  : AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAttachmentMenu(bookingId),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.poppins(color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Type message...',
                          hintStyle: GoogleFonts.poppins(
                            color: onSurface.withOpacity(0.55),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF222222) : cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final text = _messageController.text.trim();
                        if (text.isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        await _chatService.sendTextMessage(
                          bookingId: bookingId,
                          senderId: user.uid,
                          senderName: widget.workshopName,
                          senderRole: 'workshop',
                          text: text,
                        );

                        _messageController.clear();
                      },
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _applySearchFilterSort(
    List<Map<String, dynamic>> bookings,
  ) {
    final query = _searchController.text.trim().toLowerCase();

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

    if (_filter == 'Active') {
      result = result.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s != 'completed' && s != 'cancelled';
      }).toList();
    } else if (_filter == 'Completed') {
      result = result.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'completed';
      }).toList();
    } else if (_filter == 'Cancelled') {
      result = result.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'cancelled';
      }).toList();
    }

    if (!_showPast) {
      final now = DateTime.now();
      result = result.where((b) {
        final dt = _timestampToDate(b['bookingDate']);
        if (dt == null) return true;
        return dt.isAfter(now.subtract(const Duration(minutes: 1)));
      }).toList();
    }

    final now = DateTime.now();
    result.sort((a, b) {
      final aCreated = _timestampToDate(a['createdAt']) ?? DateTime(1970);
      final bCreated = _timestampToDate(b['createdAt']) ?? DateTime(1970);

      final aBookingDate = _timestampToDate(a['bookingDate']) ?? DateTime(1970);
      final bBookingDate = _timestampToDate(b['bookingDate']) ?? DateTime(1970);

      final aIsPast = aBookingDate.isBefore(now);
      final bIsPast = bBookingDate.isBefore(now);

      if (aIsPast != bIsPast) return aIsPast ? 1 : -1;

      return bCreated.compareTo(aCreated);
    });

    if (widget.highlightBookingId != null &&
        widget.highlightBookingId!.isNotEmpty) {
      result.sort((a, b) {
        final aMatch = a['id'] == widget.highlightBookingId;
        final bMatch = b['id'] == widget.highlightBookingId;

        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });
    }

    return result;
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.35,
                  color: onSurface.withOpacity(0.78),
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(0.92),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.35,
                      color: onSurface.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
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
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            _filterChip("All"),
                            const SizedBox(width: 8),
                            _filterChip("Active"),
                            const SizedBox(width: 8),
                            _filterChip("Completed"),
                            const SizedBox(width: 8),
                            _filterChip("Cancelled"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_toggle_off,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Show Past Bookings",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showPast,
                            onChanged: (v) => setState(() => _showPast = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _workshopService.getBookingsByWorkshop(widget.workshopId),
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
                    final isHighlighted =
                        booking['id'] == widget.highlightBookingId;

                    return Slidable(
                      key: ValueKey(booking['id']),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.5,
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              _changeStatus(
                                booking['id'],
                                (booking['status'] ?? 'pending').toString(),
                                currentTechnicianId:
                                    booking['assignedTechnicianId']?.toString(),
                              );
                            },
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            icon: Icons.edit_outlined,
                            label: 'Update',
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                          ),
                          SlidableAction(
                            onPressed: (_) {
                              _showChatPopup(booking);
                            },
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.chat_bubble_outline,
                            label: 'Chat',
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(14),
                            ),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkshopBookingProgressPage(
                                booking: booking,
                                workshopName: widget.workshopName,
                              ),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? AppColors.primary.withOpacity(0.06)
                                : cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isHighlighted
                                  ? AppColors.primary.withOpacity(0.55)
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.08),
                              width: isHighlighted ? 1.4 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.00
                                      : 0.35,
                                ),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 10,
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
                                    top: Radius.circular(20),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          AppColors
                                                              .gradientStart,
                                                          AppColors.gradientEnd,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .miscellaneous_services_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  booking['serviceType'] ??
                                                      'Service',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 17,
                                                    color: onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Booked On",
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: onSurface.withOpacity(
                                                  0.55,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatTimestamp(
                                                booking['createdAt'],
                                              ),
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: onSurface.withOpacity(
                                                  0.75,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (isHighlighted) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Selected from notification',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    _infoRow(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Customer',
                                      value:
                                          (booking['customerName'] ?? 'Unknown')
                                              .toString(),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.phone_outlined,
                                      label: 'Contact',
                                      value: (booking['customerPhone'] ?? '-')
                                          .toString(),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      value: (booking['customerEmail'] ?? '-')
                                          .toString(),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.directions_car_outlined,
                                      label: 'Vehicle',
                                      value:
                                          (booking['vehicleDisplay'] ?? '')
                                              .toString()
                                              .isEmpty
                                          ? '-'
                                          : booking['vehicleDisplay']
                                                .toString(),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.sticky_note_2_outlined,
                                      label: 'Notes',
                                      value:
                                          (booking['notes'] ?? '')
                                              .toString()
                                              .trim()
                                              .isEmpty
                                          ? 'No notes'
                                          : booking['notes'].toString(),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.event_outlined,
                                      label: 'Booked Slot',
                                      value: _formatTimestamp(
                                        booking['bookingDate'],
                                      ),
                                      onSurface: onSurface,
                                    ),
                                    _infoRow(
                                      icon: Icons.access_time_outlined,
                                      label: 'Time Only',
                                      value: _formatTimeOnly(
                                        booking['bookingDate'],
                                      ),
                                      onSurface: onSurface,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.30),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            status == 'completed'
                                                ? Icons.check_circle
                                                : status == 'cancelled'
                                                ? Icons.cancel
                                                : status == 'in_progress'
                                                ? Icons.build_circle
                                                : status == 'confirmed'
                                                ? Icons.verified
                                                : Icons.hourglass_top_rounded,
                                            size: 15,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatStatusLabel(status),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if ((booking['assignedTechnicianId'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      FutureBuilder<String?>(
                                        future: _workshopService
                                            .getTechnicianName(
                                              booking['assignedTechnicianId']
                                                  .toString(),
                                            ),
                                        builder: (context, snapshot) {
                                          final techName = snapshot.data;
                                          if (techName == null ||
                                              techName.trim().isEmpty) {
                                            return const SizedBox.shrink();
                                          }

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.18),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.engineering_rounded,
                                                  size: 15,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    "Technician: $techName",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final isDark =
                                                  Theme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark;

                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  gradient: isDark
                                                      ? const LinearGradient(
                                                          colors: [
                                                            AppColors
                                                                .gradientStart,
                                                            AppColors
                                                                .gradientEnd,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        )
                                                      : null,
                                                  boxShadow: isDark
                                                      ? [
                                                          BoxShadow(
                                                            color: AppColors
                                                                .gradientEnd
                                                                .withOpacity(
                                                                  0.30,
                                                                ),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    _changeStatus(
                                                      booking['id'],
                                                      (booking['status'] ??
                                                              'pending')
                                                          .toString(),
                                                      currentTechnicianId:
                                                          booking['assignedTechnicianId']
                                                              ?.toString(),
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor: isDark
                                                        ? Colors.transparent
                                                        : null,
                                                    side: BorderSide(
                                                      color: isDark
                                                          ? Colors.transparent
                                                          : AppColors.primary,
                                                      width: 1.6,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "UPDATE",
                                                    style: GoogleFonts.poppins(
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () {
                                            _showChatPopup(booking);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.gradientStart,
                                                  AppColors.gradientEnd,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.chat_bubble_outline,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isCancelled = label == "Cancelled";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filter = label),
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: isCancelled
                          ? [const Color(0xFFE57373), const Color(0xFFD32F2F)]
                          : [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : isCancelled
                    ? Colors.red.withOpacity(0.25)
                    : AppColors.primary.withOpacity(0.20),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: (isCancelled ? Colors.red : AppColors.primary)
                            .withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label == "All") ...[
                  Icon(
                    Icons.grid_view_rounded,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : onSurface.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                ],
                if (label == "Active") ...[
                  Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : onSurface.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                ],
                if (label == "Completed") ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : onSurface.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                ],
                if (label == "Cancelled") ...[
                  Icon(
                    Icons.cancel_rounded,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : Colors.red.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
