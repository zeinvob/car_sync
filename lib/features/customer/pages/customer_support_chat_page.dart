import 'package:car_sync/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Customer Support Chat Page
/// Single unified chat per customer - all inquiries go to the same conversation
class CustomerSupportChatPage extends StatefulWidget {
  /// Optional: Initial message context (e.g., "Asking about: Brake Pad")
  /// This will be sent as the first message if provided
  final String? initialContext;

  const CustomerSupportChatPage({
    super.key,
    this.initialContext,
  });

  @override
  State<CustomerSupportChatPage> createState() => _CustomerSupportChatPageState();
}

class _CustomerSupportChatPageState extends State<CustomerSupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _chatId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Always look for existing chat for this customer (ONE chat per customer)
      final existingChat = await _firestore
          .collection('support_chats')
          .where('customerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        _chatId = existingChat.docs.first.id;
      } else {
        // Create new chat for this customer
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};

        final chatDoc = await _firestore.collection('support_chats').add({
          'customerId': user.uid,
          'customerName': userData['fullName'] ?? userData['name'] ?? 'Customer',
          'customerEmail': user.email ?? '',
          'customerPhone': userData['phone'] ?? '',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadByAdmin': 0,
          'unreadByCustomer': 0,
        });

        _chatId = chatDoc.id;
      }

      // If there's initial context (e.g., from spare parts), pre-fill the message
      if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
        _messageController.text = widget.initialContext!;
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore
          .collection('support_chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'type': 'text',
        'text': text,
        'senderId': user.uid,
        'senderName': userData['fullName'] ?? userData['name'] ?? 'Customer',
        'senderRole': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'isReadByAdmin': false,
        'isReadByCustomer': true,
      });

      // Update chat metadata
      await _firestore.collection('support_chats').doc(_chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'unreadByAdmin': FieldValue.increment(1),
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _markAsRead() async {
    if (_chatId == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Mark messages as read
      final unreadMessages = await _firestore
          .collection('support_chats')
          .doc(_chatId)
          .collection('messages')
          .where('isReadByCustomer', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isReadByCustomer': true});
      }

      // Reset unread count
      await _firestore.collection('support_chats').doc(_chatId).update({
        'unreadByCustomer': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Chat with Admin',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Please login to chat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with Admin',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages
                Expanded(
                  child: _chatId == null
                      ? _buildErrorState()
                      : StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('support_chats')
                              .doc(_chatId)
                              .collection('messages')
                              .orderBy('createdAt', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            // Mark messages as read when viewing
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _markAsRead();
                            });

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            final messages = snapshot.data!.docs;

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index].data() as Map<String, dynamic>;
                                final isMe = message['senderRole'] == 'customer';
                                return _buildMessageBubble(message, isMe);
                              },
                            );
                          },
                        ),
                ),

                // Input area
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How can we help you?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with our team.\nWe\'re here to assist you!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Quick question suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Product availability'),
                _buildSuggestionChip('Delivery time'),
                _buildSuggestionChip('Price inquiry'),
                _buildSuggestionChip('Service hours'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      onPressed: () {
        _messageController.text = text;
      },
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load chat',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _initializeChat();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['text'] ?? '';
    final senderName = message['senderName'] ?? 'Unknown';
    final timestamp = message['createdAt'] as Timestamp?;
    final time = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
