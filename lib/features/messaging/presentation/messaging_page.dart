import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

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
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: DT.gbWhite,
          appBar: _AppBar(onBack: () => ctx.go('/home')),
          body: Column(
            children: [
              // ── Search bar ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(DT.s4, DT.s2, DT.s4, DT.s2),
                child: _SearchBar(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

              // ── Content ─────────────────────────────────
              Expanded(
                child: BlocBuilder<MessagingBloc, MessagingState>(
                  builder: (context, state) {
                    if (state is MessagingLoading) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: DT.metricBlue));
                    }
                    if (state is MessagingError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () =>
                            context.read<MessagingBloc>().add(LoadConversations()),
                      );
                    }
                    if (state is MessagingLoaded) {
                      return _ConversationList(
                        all: state.conversations,
                        query: _searchQuery,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const _AppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DT.gbWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: DT.textPrimary, size: 20),
        onPressed: onBack,
      ),
      title: const Text(
        'Üzenetek',
        style: TextStyle(
          color: DT.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        _CircleBtn(icon: Icons.video_call_outlined, onTap: () {}),
        const SizedBox(width: DT.s2),
        _CircleBtn(icon: Icons.edit_note_outlined, onTap: () {}),
        const SizedBox(width: DT.s3),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar(
      {required this.controller,
      required this.onChanged,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: DT.bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: DT.textPrimary),
        decoration: InputDecoration(
          hintText: 'Keresés',
          hintStyle:
              const TextStyle(color: DT.textSecondary, fontSize: 15),
          prefixIcon:
              const Icon(Icons.search, color: DT.iconLight, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.cancel,
                      color: DT.iconLight, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: DT.s4),
          isDense: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Conversation list
// ─────────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<ConversationModel> all;
  final String query;

  const _ConversationList({required this.all, required this.query});

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? all
        : all
            .where((c) =>
                c.contactName.toLowerCase().contains(query.toLowerCase()))
            .toList();

    final online = all.where((c) => c.isOnline).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: DT.iconLightGrey),
            SizedBox(height: DT.s4),
            Text('Nincs találat.',
                style:
                    TextStyle(color: DT.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Active-now strip
        if (online.isNotEmpty && query.isEmpty)
          SliverToBoxAdapter(
            child: _ActiveNowStrip(
              contacts: online,
              onTap: (id) => context.push('/messages/$id'),
            ),
          ),

        // Section label
        if (query.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
              child: Text(
                'ÜZENETEK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DT.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _ConversationTile(
              conversation: filtered[i],
              onTap: () => context.push('/messages/${filtered[i].id}'),
            ),
            childCount: filtered.length,
          ),
        ),

        // Bottom safe-area padding
        const SliverToBoxAdapter(child: SizedBox(height: DT.s4)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Active-now horizontal strip
// ─────────────────────────────────────────────────────────────

class _ActiveNowStrip extends StatelessWidget {
  final List<ConversationModel> contacts;
  final ValueChanged<String> onTap;

  const _ActiveNowStrip({required this.contacts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(DT.s4, DT.s3, DT.s4, DT.s2),
          child: Text(
            'AKTÍV MOST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DT.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: DT.s4),
            itemCount: contacts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: DT.s4),
            itemBuilder: (context, i) {
              final c = contacts[i];
              return GestureDetector(
                onTap: () => onTap(c.id),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar with green ring
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.green, width: 2.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: AvatarWidget(
                              name: c.contactName, size: 50),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        c.contactName.split(' ').first,
                        style: const TextStyle(
                            fontSize: 12,
                            color: DT.textSecondary,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(color: DT.borderLight, height: 1, thickness: 0.8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Conversation tile
// ─────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile(
      {required this.conversation, required this.onTap});

  String _ts(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Most';
    if (diff.inHours < 1) return '${diff.inMinutes}p';
    if (diff.inDays < 1) return '${diff.inHours}ó';
    if (diff.inDays == 1) return 'Tegnap';
    return DateFormat('MM.dd').format(t);
  }

  bool get _unread => conversation.unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: DT.metricBlue.withOpacity(0.06),
        highlightColor: DT.bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DT.s4, vertical: 10),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(
                      name: conversation.contactName, size: 56),
                  if (conversation.isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: DT.gbWhite, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: DT.s3),

              // ── Text content ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.contactName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: DT.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: DT.s2),
                        Text(
                          _ts(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: _unread
                                ? DT.metricBlue
                                : DT.textSecondary,
                            fontWeight: _unread
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
                              fontSize: 13,
                              color: _unread
                                  ? DT.textPrimary
                                  : DT.textSecondary,
                              fontWeight: _unread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_unread) ...[
                          const SizedBox(width: DT.s2),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: DT.metricBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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

// ─────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: DT.cardRed),
          const SizedBox(height: DT.s4),
          Text(message,
              style: const TextStyle(
                  color: DT.textSecondary, fontSize: 15)),
          const SizedBox(height: DT.s4),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: DT.metricBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.rCard))),
            child: const Text('Újra'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: DT.bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: DT.textPrimary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AvatarWidget — PUBLIC so chat_page.dart can import it
// ─────────────────────────────────────────────────────────────

class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;

  const AvatarWidget({super.key, required this.name, this.size = 50});

  static const _palette = [
    Color(0xFF428AE9), // blue
    Color(0xFF4ECDC4), // teal
    Color(0xFFFF6B35), // orange
    Color(0xFFFFC85D), // yellow
    Color(0xFFFF6B6B), // red
    Color(0xFF9B59B6), // purple
  ];

  Color get _color => _palette[name.codeUnitAt(0) % _palette.length];

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.18),
      ),
      child: Center(
        child: Text(
          _initials.toUpperCase(),
          style: TextStyle(
            color: _color,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
