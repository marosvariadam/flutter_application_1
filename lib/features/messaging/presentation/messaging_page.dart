import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MessagingBloc()..add(LoadConversations()),
      child: Scaffold(
        backgroundColor: DT.bg,
        appBar: AppBar(
          backgroundColor: DT.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: DT.textPrimary, size: 20),
            onPressed: () => context.go('/home'),
          ),
          title: const Text(
            'Üzenetek',
            style: TextStyle(
              color: DT.textPrimary,
              fontSize: DT.s5,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: DT.textPrimary),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s5, vertical: DT.s3),
              child: Container(
                decoration: BoxDecoration(
                  color: DT.gbWhite,
                  borderRadius: BorderRadius.circular(DT.rCardSmall),
                  boxShadow: const [
                    BoxShadow(
                      color: DT.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(
                      fontSize: DT.s4, color: DT.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Keresés...',
                    hintStyle: const TextStyle(
                        color: DT.textSecondary, fontSize: DT.s4),
                    prefixIcon:
                        const Icon(Icons.search, color: DT.iconLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: DT.iconLight, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: DT.s3, horizontal: DT.s4),
                  ),
                ),
              ),
            ),

            // Conversation list
            Expanded(
              child: BlocBuilder<MessagingBloc, MessagingState>(
                builder: (context, state) {
                  if (state is MessagingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MessagingError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: DT.cardRed),
                          const SizedBox(height: DT.s4),
                          Text(
                            state.message,
                            style: const TextStyle(
                                color: DT.textSecondary, fontSize: DT.s4),
                          ),
                          const SizedBox(height: DT.s4),
                          ElevatedButton(
                            onPressed: () => context
                                .read<MessagingBloc>()
                                .add(LoadConversations()),
                            child: const Text('Újra'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MessagingLoaded) {
                    final filtered = _searchQuery.isEmpty
                        ? state.conversations
                        : state.conversations
                            .where((c) => c.contactName
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off,
                                size: 64, color: DT.iconLightGrey),
                            SizedBox(height: DT.s4),
                            Text(
                              'Nincs találat.',
                              style: TextStyle(
                                  color: DT.textSecondary, fontSize: DT.s4),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _ConversationTile(
                          conversation: filtered[index],
                          onTap: () => context.push(
                              '/messages/${filtered[index].id}'),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile(
      {required this.conversation, required this.onTap});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Most';
    if (diff.inHours < 1) return '${diff.inMinutes} perce';
    if (diff.inDays < 1) return '${diff.inHours} órája';
    if (diff.inDays == 1) return 'Tegnap';
    return DateFormat('MM.dd').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DT.s5, vertical: DT.s3),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DT.challengeCardGradientStart,
                      border: Border.all(color: DT.borderGrey, width: 1),
                    ),
                    child: ClipOval(
                      child: conversation.contactAvatarUrl.isNotEmpty
                          ? Image.network(
                              conversation.contactAvatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _AvatarFallback(conversation.contactName),
                            )
                          : _AvatarFallback(conversation.contactName),
                    ),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 13,
                        height: 13,
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

              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation.contactName,
                          style: TextStyle(
                            fontSize: DT.s4,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: DT.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: DT.s3,
                            color: conversation.unreadCount > 0
                                ? DT.metricBlue
                                : DT.textSecondary,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontSize: DT.s3,
                              color: conversation.unreadCount > 0
                                  ? DT.textPrimary
                                  : DT.textSecondary,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: DT.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: DT.metricBlue,
                              borderRadius:
                                  BorderRadius.circular(DT.rChip),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: DT.gbWhite,
                                fontSize: 11,
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
  }
}

/// Generates a coloured circle with initials when no avatar image is available.
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
      color: _color.withOpacity(0.3),
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
