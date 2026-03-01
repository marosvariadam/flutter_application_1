import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/messaging/bloc/chat_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';

class ChatPage extends StatelessWidget {
  final String contactId;
  const ChatPage({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc()..add(LoadChat(contactId)),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final canSend = _inputController.text.trim().isNotEmpty;
      if (canSend != _canSend) setState(() => _canSend = canSend);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(SendMessage(text));
    _inputController.clear();
    // Scroll to bottom after frame renders the new message
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ChatError) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Text(state.message,
                  style: const TextStyle(color: DT.textSecondary)),
            ),
          );
        }

        if (state is ChatLoaded) {
          return _buildChat(context, state.conversation);
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildChat(BuildContext context, ConversationModel conversation) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: _buildAppBar(context, conversation),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: conversation.messages.isEmpty
                ? _buildEmptyState(conversation.contactName)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: DT.s4, vertical: DT.s3),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = conversation.messages[index];
                      final prev = index > 0
                          ? conversation.messages[index - 1]
                          : null;
                      final showTimestamp = prev == null ||
                          message.timestamp
                                  .difference(prev.timestamp)
                                  .inMinutes >
                              30;
                      return _MessageBubble(
                        message: message,
                        showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),

          // Input bar
          _buildInputBar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ConversationModel conversation) {
    return AppBar(
      backgroundColor: DT.gbWhite,
      elevation: 0,
      shadowColor: DT.shadowLight,
      surfaceTintColor: DT.gbWhite,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: DT.textPrimary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DT.challengeCardGradientStart,
                  border: Border.all(color: DT.borderGrey, width: 1),
                ),
                child: ClipOval(
                  child: conversation.contactAvatarUrl.isNotEmpty
                      ? Image.network(conversation.contactAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AvatarFallback(conversation.contactName))
                      : _AvatarFallback(conversation.contactName),
                ),
              ),
              if (conversation.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: DT.difficultyLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: DT.gbWhite, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: DT.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.contactName,
                style: const TextStyle(
                  color: DT.textPrimary,
                  fontSize: DT.s4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                conversation.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: conversation.isOnline
                      ? DT.difficultyLight
                      : DT.textSecondary,
                  fontSize: DT.s3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: DT.textPrimary),
          onPressed: () {},
        ),
        IconButton(
          icon:
              const Icon(Icons.more_vert_outlined, color: DT.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildEmptyState(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 64, color: DT.iconLightGrey),
          const SizedBox(height: DT.s4),
          Text(
            'Kezdj el beszélgetni $name-vel!',
            style: const TextStyle(color: DT.textSecondary, fontSize: DT.s4),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DT.gbWhite,
        boxShadow: [
          BoxShadow(
            color: DT.shadowLight,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: DT.s4,
        right: DT.s4,
        top: DT.s3,
        bottom: DT.s3 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          // Attachment button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DT.bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: DT.iconLight, size: DT.s5),
          ),
          const SizedBox(width: DT.s2),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DT.bg,
                borderRadius: BorderRadius.circular(DT.rCard),
              ),
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                    fontSize: DT.s4, color: DT.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Írj üzenetet...',
                  hintStyle:
                      TextStyle(color: DT.textSecondary, fontSize: DT.s4),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: DT.s4, vertical: DT.s3),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: DT.s2),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _canSend ? DT.metricBlue : DT.iconLightGrey,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _canSend ? _send : null,
                child: const Center(
                  child: Icon(Icons.send_rounded,
                      color: DT.gbWhite, size: DT.s5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback(this.name);

  static const _colors = [
    DT.cardBlue,
    DT.cardTeal,
    DT.cardOrange,
    DT.cardYellow,
    DT.metricBlue,
    DT.cardRed,
  ];

  Color get _color => _colors[name.codeUnitAt(0) % _colors.length];

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          _initials.toUpperCase(),
          style: TextStyle(
            color: _color,
            fontSize: DT.s4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool showTimestamp;

  const _MessageBubble(
      {required this.message, required this.showTimestamp});

  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('MMM dd, HH:mm');

  bool get _isToday {
    final now = DateTime.now();
    final t = message.timestamp;
    return now.day == t.day &&
        now.month == t.month &&
        now.year == t.year;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timestamp divider
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DT.s4),
            child: Row(
              children: [
                const Expanded(child: Divider(color: DT.borderLight)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DT.s3),
                  child: Text(
                    _isToday
                        ? _timeFormat.format(message.timestamp)
                        : _dateFormat.format(message.timestamp),
                    style: const TextStyle(
                        color: DT.textSecondary, fontSize: 11),
                  ),
                ),
                const Expanded(child: Divider(color: DT.borderLight)),
              ],
            ),
          ),

        // Bubble
        Align(
          alignment: message.isSentByMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom: 2,
                left: message.isSentByMe ? DT.s8 : 0,
                right: message.isSentByMe ? 0 : DT.s8,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s4, vertical: DT.s3),
              decoration: BoxDecoration(
                color: message.isSentByMe
                    ? DT.bottomNavBG
                    : DT.gbWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(DT.rCard),
                  topRight: const Radius.circular(DT.rCard),
                  bottomLeft: Radius.circular(
                      message.isSentByMe ? DT.rCard : 4),
                  bottomRight: Radius.circular(
                      message.isSentByMe ? 4 : DT.rCard),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: DT.shadowLight,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: message.isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isSentByMe
                          ? DT.gbWhite
                          : DT.textPrimary,
                      fontSize: DT.s4,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeFormat.format(message.timestamp),
                    style: TextStyle(
                      color: message.isSentByMe
                          ? Colors.white.withOpacity(0.55)
                          : DT.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
