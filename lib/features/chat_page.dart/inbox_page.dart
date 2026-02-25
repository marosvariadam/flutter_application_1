import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/services/chat_service.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    try {
      final data = await _chatService.getInbox();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba az üzenetek betöltésekor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Üzenetek',
          style: TextStyle(
            color: DT.textPrimary,
            fontSize: DT.s6,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false, 
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DT.metricBlue))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(DT.s4),
                  itemCount: _conversations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: DT.s3),
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    return _buildChatCard(chat);
                  },
                ),
    );
  }

  Widget _buildChatCard(dynamic chat) {
    final int unreadCount = chat['unreadCount'] ?? 0;
    final String lastMessage = chat['lastMessageContent'] ?? '';
    final String otherUserId = chat['otherUserId'];
    
    // Formatting date crudely for (use intl package later)
    final DateTime date = DateTime.parse(chat['lastMessageTime']);
    final String timeString = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        
        context.push('/chat', extra: otherUserId).then((_) {
          
          _loadInbox();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(DT.s4),
        decoration: BoxDecoration(
          color: DT.gbWhite,
          borderRadius: BorderRadius.circular(DT.rCardSmall),
          boxShadow: [
            BoxShadow(
              color: DT.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            
            CircleAvatar(
              radius: 24,
              backgroundColor: DT.cardBlue.withOpacity(0.3),
              child: const Icon(Icons.person, color: DT.metricBlue),
            ),
            const SizedBox(width: DT.s3),
            
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Felhasználó', // real names later
                        style: TextStyle(
                          color: DT.textPrimary,
                          fontSize: DT.s4,
                          fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: unreadCount > 0 ? DT.metricBlue : DT.textSecondary,
                          fontSize: DT.s3,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DT.s1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? DT.textPrimary : DT.textSecondary,
                            fontSize: DT.s3 + 1, 
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: DT.s2),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: DT.metricBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: DT.textSecondary.withOpacity(0.5)),
          const SizedBox(height: DT.s4),
          Text(
            'Nincsenek üzeneteid',
            style: TextStyle(
              color: DT.textSecondary,
              fontSize: DT.s4,
            ),
          ),
        ],
      ),
    );
  }
}