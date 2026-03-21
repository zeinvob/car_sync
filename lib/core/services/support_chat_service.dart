import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportChatService {
  SupportChatService._();
  static final SupportChatService instance = SupportChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _supportChats =>
      _firestore.collection('support_chats');

  Stream<QuerySnapshot<Map<String, dynamic>>> supportChatsStream() {
    return _supportChats
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (value, _) => value,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    return _supportChats
        .doc(chatId)
        .collection('messages')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (value, _) => value,
        )
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendAdminTextMessage({
    required String chatId,
    required String text,
    required String adminName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatRef = _supportChats.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'senderId': user.uid,
        'senderName': adminName,
        'senderRole': 'admin',
        'text': text,
        'type': 'text',
        'createdAt': now,
        'isReadByAdmin': true,
        'isReadByCustomer': false,
      });

      transaction.update(chatRef, {
        'lastMessage': text,
        'lastMessageAt': now,
        'unreadByAdmin': 0,
        'unreadByCustomer': FieldValue.increment(1),
        'status': 'active',
      });
    });
  }

  Future<void> markChatAsReadByAdmin(String chatId) async {
    final chatRef = _supportChats.doc(chatId);
    final unreadMessages = await chatRef
        .collection('messages')
        .where('senderRole', isEqualTo: 'customer')
        .where('isReadByAdmin', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isReadByAdmin': true,
      });
    }

    batch.update(chatRef, {
      'unreadByAdmin': 0,
    });

    await batch.commit();
  }

  Future<int> getUnreadSupportChatsCountOnce() async {
    final snapshot = await _supportChats.where('unreadByAdmin', isGreaterThan: 0).get();
    return snapshot.docs.length;
  }

  Stream<int> unreadSupportChatsCountStream() {
    return _supportChats.snapshots().map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unread = (data['unreadByAdmin'] ?? 0);
        final unreadCount = unread is int ? unread : int.tryParse('$unread') ?? 0;
        if (unreadCount > 0) count++;
      }
      return count;
    });
  }
}