import 'package:cloud_firestore/cloud_firestore.dart';

/// GLOBAL CHAT SERVICE
/// Reusable for customer, admin, workshop, and technician chat.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all chat messages for a booking
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBookingMessages(
    String bookingId,
  ) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Send plain text message
  Future<void> sendTextMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          'type': 'text',
          'text': text,
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': senderRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Send image message
  Future<void> sendImageMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String imageUrl,
    String caption = '',
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          'type': 'image',
          'text': caption,
          'imageUrl': imageUrl,
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': senderRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Send file/document message
  Future<void> sendFileMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String fileUrl,
    required String fileName,
    String fileType = '',
    String caption = '',
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          'type': 'file',
          'text': caption,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileType': fileType,
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': senderRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Send location message

  Future<void> sendLocationMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required double latitude,
    required double longitude,
    String label = 'Shared Location',
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          'type': 'location',
          'text': label,
          'latitude': latitude,
          'longitude': longitude,
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': senderRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
