import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _messagesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc('current_user')
      .collection('messages');

  final List<String> _quickReplies = [
    "How to list an item?",
    "Safety tips for meetups",
    "How do payments work?",
    "Contact support",
  ];

  @override
  void initState() {
    super.initState();
    _checkAndAddWelcomeMessage();
  }

  Future<void> _checkAndAddWelcomeMessage() async {
    final snapshot = await _messagesRef.get();
    if (snapshot.docs.isEmpty) {
      await _messagesRef.add({
        'text': "Hello! Welcome to Local Marketplace Support. How can I help you today?",
        'isUser': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();

    // Save user message to Firestore
    await _messagesRef.add({
      'text': text,
      'isUser': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Simulate rule-based bot reply after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _getBotResponse(text);
    });
  }

  Future<void> _getBotResponse(String userQuery) async {
    String query = userQuery.toLowerCase();
    String botReply;

    if (query.contains('list') || query.contains('sell') || query.contains('add')) {
      botReply = "To list an item, tap the '+' icon on the top right of the home screen, fill out the product details, and hit Save!";
    } else if (query.contains('safe') || query.contains('meetup') || query.contains('location')) {
      botReply = "Safety First: Always meet buyers or sellers in well-lit public places like shopping malls, coffee shops, or local police station exchange zones.";
    } else if (query.contains('payment') || query.contains('pay') || query.contains('price')) {
      botReply = "Payment terms are arranged directly between buyer and seller. We recommend cash on pickup or secure peer-to-peer transfer apps.";
    } else if (query.contains('contact') || query.contains('support') || query.contains('help')) {
      botReply = "You can reach human support anytime via email at support@localmarketplace.com.";
    } else {
      botReply = "I'm your rule-based marketplace assistant. Try asking about 'safety', 'how to list', or 'payments'.";
    }

    // Save bot response to Firestore
    await _messagesRef.add({
      'text': botReply,
      'isUser': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final text = data['text'] ?? '';
                    final isUser = data['isUser'] ?? false;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.teal.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Quick Reply Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(_quickReplies[index]),
                    onPressed: () => _handleSubmitted(_quickReplies[index]),
                  ),
                );
              },
            ),
          ),
          // Text Input Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: () => _handleSubmitted(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}