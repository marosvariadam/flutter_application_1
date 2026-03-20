import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/messaging/bloc/chat_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';
import 'package:flutter_application_1/features/messaging/presentation/messaging_page.dart'
    show AvatarWidget;

// ─────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Main view (stateful — owns controllers)
// ─────────────────────────────────────────────────────────────

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      final v = _inputCtrl.text.trim().isNotEmpty;
      if (v != _canSend) setState(() => _canSend = v);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(SendMessage(text));
    _inputCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: DT.metricBlue)),
          );
        }
        if (state is ChatError) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: DT.of(context).textPrimary, size: 20),
                onPressed: () => context.pop(),
              ),
              backgroundColor: DT.gbWhite,
              elevation: 0,
            ),
            body: Center(
              child: Text(state.message,
                  style: TextStyle(color: DT.of(context).textSecondary)),
            ),
          );
        }
        if (state is ChatLoaded) {
          return _buildScaffold(context, state.conversation);
        }
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  // ── Scaffold ─────────────────────────────────────────────

  Widget _buildScaffold(
      BuildContext context, ConversationModel conversation) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: _ChatAppBar(conversation: conversation),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context, conversation)),
          _InputBar(
            controller: _inputCtrl,
            canSend: _canSend,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────

  Widget _buildMessageList(
      BuildContext context, ConversationModel conversation) {
    final msgs = conversation.messages;
    if (msgs.isEmpty) {
      return _EmptyChat(name: conversation.contactName);
    }

    final lastSentIdx = msgs.lastIndexWhere((m) => m.isSentByMe);

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: DT.s3, vertical: DT.s3),
      itemCount: msgs.length,
      itemBuilder: (context, i) {
        final msg = msgs[i];
        final prev = i > 0 ? msgs[i - 1] : null;
        final next = i < msgs.length - 1 ? msgs[i + 1] : null;

        // Grouping: same sender within 5 min = same group
        final isGroupStart = prev == null ||
            prev.isSentByMe != msg.isSentByMe ||
            msg.timestamp.difference(prev.timestamp).inMinutes >= 5;

        final isGroupEnd = next == null ||
            next.isSentByMe != msg.isSentByMe ||
            next.timestamp.difference(msg.timestamp).inMinutes >= 5;

        // Time divider: gap > 30 min from previous message
        final showDivider = prev == null ||
            msg.timestamp.difference(prev.timestamp).inMinutes >= 30;

        return _MessageRow(
          message: msg,
          contactName: conversation.contactName,
          isGroupStart: isGroupStart,
          isGroupEnd: isGroupEnd,
          showTimeDivider: showDivider,
          showDelivered: msg.isSentByMe && i == lastSentIdx,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel conversation;
  const _ChatAppBar({required this.conversation});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DT.gbWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            color: DT.of(context).textPrimary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: GestureDetector(
        // Tapping the header could open profile — placeholder
        onTap: () {},
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(name: conversation.contactName, size: 40),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: DT.gbWhite, width: 2),
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
                  style: TextStyle(
                    color: DT.of(context).textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  conversation.isOnline ? 'Aktív most' : 'Offline',
                  style: TextStyle(
                    color: conversation.isOnline
                        ? Colors.green
                        : DT.of(context).textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined,
              color: DT.metricBlue, size: 24),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.video_call_outlined,
              color: DT.metricBlue, size: 26),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message row (one message + surrounding chrome)
// ─────────────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  final MessageModel message;
  final String contactName;
  final bool isGroupStart;
  final bool isGroupEnd;
  final bool showTimeDivider;
  final bool showDelivered;

  const _MessageRow({
    required this.message,
    required this.contactName,
    required this.isGroupStart,
    required this.isGroupEnd,
    required this.showTimeDivider,
    required this.showDelivered,
  });

  static final _hm = DateFormat('HH:mm');
  static final _full = DateFormat('MMM dd. HH:mm');

  bool get _today {
    final n = DateTime.now();
    final t = message.timestamp;
    return n.day == t.day && n.month == t.month && n.year == t.year;
  }

  // Border radius following Messenger convention:
  //   Sent  → left corners always full; right top = full only on group-start,
  //            right bottom always 4 (the "tail")
  //   Received → right corners always full; left top = full on group-start,
  //              left bottom always 4 (the "tail")
  BorderRadius _radius() {
    const full = Radius.circular(18);
    const tail = Radius.circular(4);
    if (message.isSentByMe) {
      return BorderRadius.only(
        topLeft: full,
        bottomLeft: full,
        topRight: isGroupStart ? full : tail,
        bottomRight: tail,
      );
    } else {
      return BorderRadius.only(
        topRight: full,
        bottomRight: full,
        topLeft: isGroupStart ? full : tail,
        bottomLeft: tail,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Time divider ─────────────────────────────────
        if (showTimeDivider)
          Padding(
            padding: EdgeInsets.only(
              top: isGroupStart ? DT.s4 : DT.s2,
              bottom: DT.s3,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DT.s3, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius:
                      BorderRadius.circular(DT.rChip),
                ),
                child: Text(
                  _today
                      ? _hm.format(message.timestamp)
                      : _full.format(message.timestamp),
                  style: TextStyle(
                      fontSize: 11,
                      color: DT.of(context).textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          )
        else if (isGroupStart)
          const SizedBox(height: 8)
        else
          const SizedBox(height: 2),

        // ── Bubble row ───────────────────────────────────
        Row(
          mainAxisAlignment: message.isSentByMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Received: small avatar only on last of group
            if (!message.isSentByMe) ...[
              SizedBox(
                width: 28,
                height: 28,
                child: isGroupEnd
                    ? AvatarWidget(name: contactName, size: 28)
                    : null,
              ),
              const SizedBox(width: 6),
            ],

            // Bubble
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: screenW * 0.72),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isSentByMe
                      ? DT.metricBlue
                      : DT.of(context).challengeCardGradientStart,
                  borderRadius: _radius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                            ? Colors.white
                            : DT.of(context).textPrimary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _hm.format(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isSentByMe
                            ? Colors.white.withOpacity(0.6)
                            : DT.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── "Kézbesítve" under last sent message ─────────
        if (showDelivered)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: DT.s3, bottom: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Kézbesítve',
                style: TextStyle(
                    fontSize: 11,
                    color: DT.of(context).textSecondary,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: DT.gbWhite,
        border: Border(
            top: BorderSide(color: DT.of(context).borderLight, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        left: DT.s3,
        right: DT.s3,
        top: DT.s2,
        bottom: DT.s2 + bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji button
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () {},
              child: const Icon(
                Icons.sentiment_satisfied_alt_outlined,
                color: DT.metricBlue,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: DT.s2),

          // Text field (pill)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: Container(
                decoration: BoxDecoration(
                  color: DT.of(context).bg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  style: TextStyle(
                      fontSize: 15, color: DT.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Aa',
                    hintStyle: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: DT.s2),

          // Right side: animated switch between media icons and send
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: canSend
                  ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: onSend,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: DT.metricBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    )
                  : Row(
                      key: const ValueKey('media'),
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.camera_alt_outlined,
                            color: DT.metricBlue, size: 28),
                        SizedBox(width: DT.s3),
                        Icon(Icons.mic_none_outlined,
                            color: DT.metricBlue, size: 28),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty chat state
// ─────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarWidget(name: name, size: 72),
          const SizedBox(height: DT.s4),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DT.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            'Küldj egy üzenetet a beszélgetés indításához!',
            style:
                TextStyle(color: DT.of(context).textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
