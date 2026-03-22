import 'dart:convert';
import 'dart:io';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/chat_service.dart';
import 'package:car_sync/core/services/document_picker_service.dart';
import 'package:car_sync/core/services/file_upload_service.dart';
import 'package:car_sync/core/services/image_picker_service.dart';
import 'package:car_sync/core/services/location_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:car_sync/features/admin/pages/workshop_bookings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminChatInboxPage extends StatefulWidget {
  const AdminChatInboxPage({super.key});

  @override
  State<AdminChatInboxPage> createState() => _AdminChatInboxPageState();
}

class _AdminChatInboxPageState extends State<AdminChatInboxPage> {
  final WorkshopService _workshopService = WorkshopService();
  final ChatService _chatService = ChatService();

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final now = DateTime.now();

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      return DateFormat('hh:mm a').format(date);
    }

    return DateFormat('dd MMM').format(date);
  }

  String _lastMessagePreview(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'text').toString();
    final text = (data['text'] ?? data['message'] ?? '').toString().trim();

    switch (type) {
      case 'image':
        return text.isNotEmpty ? '📷 $text' : '📷 Image';
      case 'file':
        final fileName = (data['fileName'] ?? 'Document').toString();
        return '📄 $fileName';
      case 'location':
        return '📍 ${text.isNotEmpty ? text : 'Shared Location'}';
      default:
        return text.isEmpty ? 'No message' : text;
    }
  }

  Future<List<Map<String, dynamic>>> _loadInboxItems() async {
    final bookings = await _workshopService.getAllActiveBookingsForChat();
    final List<Map<String, dynamic>> result = [];

    for (final booking in bookings) {
      final bookingId = (booking['id'] ?? '').toString();
      if (bookingId.isEmpty) continue;

      final lastMessage = await _chatService.getLastMessage(bookingId);
      if (lastMessage == null) continue;

      final unreadCount = await _chatService.getUnreadCountForAdmin(bookingId);

      String customerProfileImageUrl = '';
      final customerId = (booking['customerId'] ?? '').toString();

      if (customerId.isNotEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            customerProfileImageUrl = (userData['profileImageUrl'] ?? '')
                .toString();
          }
        } catch (e) {
          debugPrint('Failed to load customer profile image: $e');
        }
      }

      result.add({
        ...booking,
        'lastMessage': lastMessage,
        'unreadCount': unreadCount,
        'customerProfileImageUrl': customerProfileImageUrl,
      });
    }

    result.sort((a, b) {
      final rawATime = a['lastMessage'];
      final rawBTime = b['lastMessage'];

      final aMap = rawATime is Map ? Map<String, dynamic>.from(rawATime) : {};
      final bMap = rawBTime is Map ? Map<String, dynamic>.from(rawBTime) : {};

      final aTime = aMap['createdAt'];
      final bTime = bMap['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Chats',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadInboxItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No active chats found.',
                style: GoogleFonts.poppins(color: onSurface.withOpacity(0.65)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final customerName = (item['customerName'] ?? 'Customer')
                  .toString();
              final serviceType = (item['serviceType'] ?? 'Service').toString();
              final vehicleDisplay = (item['vehicleDisplay'] ?? '').toString();
              final unreadCount = (item['unreadCount'] ?? 0) as int;
              final customerProfileImageUrl =
                  (item['customerProfileImageUrl'] ?? '').toString().trim();

              final rawLastMessage = item['lastMessage'];
              final Map<String, dynamic> lastMessage = rawLastMessage is Map
                  ? Map<String, dynamic>.from(rawLastMessage)
                  : <String, dynamic>{};

              final preview = _lastMessagePreview(lastMessage);
              final time = _formatTime(lastMessage['createdAt']);

              return Slidable(
                key: ValueKey(item['id']),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.36,
                  children: [
                    SlidableAction(
                      onPressed: (_) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkshopBookingsPage(
                              workshopId: (item['workshopId'] ?? '').toString(),
                              workshopName: (item['workshopName'] ?? 'Workshop')
                                  .toString(),
                              highlightBookingId: (item['id'] ?? '').toString(),
                            ),
                          ),
                        );
                      },
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      icon: Icons.assignment_outlined,
                      label: 'Take to Booking',
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(18),
                        right: Radius.circular(18),
                      ),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminBookingChatPage(booking: item),
                      ),
                    );

                    if (mounted) {
                      setState(() {});
                    }

                    if (changed == true && mounted) {
                      Navigator.pop(context, true);
                    }

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                          child: ClipOval(
                            child: customerProfileImageUrl.isNotEmpty
                                ? Builder(
                                    builder: (context) {
                                      try {
                                        return Image.memory(
                                          base64Decode(customerProfileImageUrl),
                                          fit: BoxFit.cover,
                                        );
                                      } catch (_) {
                                        return Center(
                                          child: Text(
                                            customerName.isNotEmpty
                                                ? customerName[0].toUpperCase()
                                                : 'C',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      customerName.isNotEmpty
                                          ? customerName[0].toUpperCase()
                                          : 'C',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: onSurface.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$serviceType${vehicleDisplay.isNotEmpty ? ' • $vehicleDisplay' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: onSurface.withOpacity(0.65),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: unreadCount > 0
                                            ? onSurface
                                            : onSurface.withOpacity(0.62),
                                      ),
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : '$unreadCount',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}

class AdminBookingChatPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const AdminBookingChatPage({super.key, required this.booking});

  @override
  State<AdminBookingChatPage> createState() => _AdminBookingChatPageState();
}

class _AdminBookingChatPageState extends State<AdminBookingChatPage> {
  final ChatService _chatService = ChatService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final DocumentPickerService _documentPickerService = DocumentPickerService();
  final LocationService _locationService = LocationService();

  final TextEditingController _messageController = TextEditingController();

  String get bookingId => (widget.booking['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesReadByAdmin(bookingId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickAndSendImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final file = await _imagePickerService.pickFromGallery();
    if (file == null) return;

    final imageBase64 = await _fileUploadService.imageToBase64(file);

    await _chatService.sendImageMessage(
      bookingId: bookingId,
      senderId: user.uid,
      senderName: 'Admin',
      senderRole: 'workshop',
      imageUrl: imageBase64,
    );
  }

  Future<void> _pickAndSendDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await _documentPickerService.pickAnyFileWithInfo();
    if (picked == null) return;

    final file = picked['file'] as File;
    final fileName = picked['name'].toString();
    final extension = picked['extension'].toString();

    final fileUrl = await _fileUploadService.uploadChatFile(
      file: file,
      bookingId: bookingId,
      fileName: fileName,
    );

    await _chatService.sendFileMessage(
      bookingId: bookingId,
      senderId: user.uid,
      senderName: 'Admin',
      senderRole: 'workshop',
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: extension,
    );
  }

  Future<void> _shareCurrentLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final position = await _locationService.getCurrentLocation();
    if (position == null) return;

    await _chatService.sendLocationMessage(
      bookingId: bookingId,
      senderId: user.uid,
      senderName: 'Admin',
      senderRole: 'workshop',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _showAttachmentMenu() async {
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
      await _pickAndSendImage();
    } else if (choice == 'file') {
      await _pickAndSendDocument();
    } else if (choice == 'location') {
      await _shareCurrentLocation();
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _chatService.sendTextMessage(
      bookingId: bookingId,
      senderId: user.uid,
      senderName: 'Admin',
      senderRole: 'workshop',
      text: text,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final customerName = (widget.booking['customerName'] ?? 'Customer')
        .toString();
    final serviceType = (widget.booking['serviceType'] ?? 'Service').toString();
    final vehicleDisplay = (widget.booking['vehicleDisplay'] ?? '').toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            Text(
              '$serviceType${vehicleDisplay.isNotEmpty ? ' • $vehicleDisplay' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markMessagesReadByAdmin(bookingId);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final sender = (data['senderName'] ?? 'Unknown').toString();
                    final senderRole = (data['senderRole'] ?? '').toString();
                    final messageType = (data['type'] ?? 'text').toString();
                    final messageText = (data['text'] ?? data['message'] ?? '')
                        .toString();

                    final isMe =
                        senderRole == 'workshop' || senderRole == 'admin';

                    final createdAt = data['createdAt'];
                    final timeText = createdAt is Timestamp
                        ? DateFormat('hh:mm a').format(createdAt.toDate())
                        : '';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.68,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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

                                        final isBase64Image =
                                            imageData.startsWith('/9j/') ||
                                            imageData.startsWith('iVBOR') ||
                                            imageData.startsWith('R0lGOD') ||
                                            imageData.startsWith('UklGR');

                                        Widget previewImage() {
                                          if (isBase64Image) {
                                            try {
                                              return Image.memory(
                                                base64Decode(imageData),
                                                width: 170,
                                                height: 125,
                                                fit: BoxFit.cover,
                                              );
                                            } catch (_) {
                                              return Container(
                                                width: 170,
                                                height: 125,
                                                color: Colors.grey.shade300,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              );
                                            }
                                          }

                                          return Image.network(
                                            imageData,
                                            width: 170,
                                            height: 125,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 170,
                                                    height: 125,
                                                    color: Colors.grey.shade300,
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                    ),
                                                  );
                                                },
                                          );
                                        }

                                        Widget fullImage() {
                                          if (isBase64Image) {
                                            try {
                                              return Image.memory(
                                                base64Decode(imageData),
                                                fit: BoxFit.contain,
                                              );
                                            } catch (_) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              );
                                            }
                                          }

                                          return Image.network(
                                            imageData,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                  );
                                                },
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
                                                      child: fullImage(),
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
                                                          color: Colors.white,
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: previewImage(),
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
                                        color: isMe ? Colors.white : onSurface,
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
                                    _openUrl(url);
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
                                          decoration: TextDecoration.underline,
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
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              timeText,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : onSurface.withOpacity(0.55),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showAttachmentMenu,
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
                    onPressed: _sendText,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
