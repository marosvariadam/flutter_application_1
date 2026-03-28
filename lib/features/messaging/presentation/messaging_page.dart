import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

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

  // ── Athlete-only navigation state ──────────────────────────
  // True once the athlete has been auto-navigated to the trainer chat
  // (so we don't loop on state rebuilds).
  bool _navigated = false;
  // True once we've dispatched LoadMyRequests as a fallback for empty convos.
  bool _trainerFallbackStarted = false;
  // Trainer info resolved from the accepted trainer request (fallback).
  String? _fallbackTrainerId;
  String? _fallbackTrainerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (UserSession.instance.isCoach) {
        // Only load if not already populated.
        if (context.read<RosterBloc>().state is! RosterLoaded) {
          context.read<RosterBloc>().add(LoadRoster());
        }
      } else {
        context.read<MessagingBloc>().add(LoadConversations());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────

  void _navigateToChat(BuildContext context, String id, String name) {
    if (_navigated) return;
    _navigated = true;
    context.push('/messages/$id', extra: name).then((_) {
      // Refresh conversations when returning from chat (updates unread counts).
      if (mounted) {
        context.read<MessagingBloc>().add(LoadConversations());
      }
    });
  }

  void _handleTrainerRequests(
      BuildContext context, List<TrainerRequestModel> requests) {
    TrainerRequestModel? accepted;
    for (final r in requests) {
      if (r.isAccepted) {
        accepted = r;
        break;
      }
    }
    if (accepted == null) return;

    final id = accepted.trainerId;
    final name = accepted.trainerName ??
        accepted.trainerEmail ??
        'Edző';

    if (id != null) {
      setState(() {
        _fallbackTrainerId = id;
        _fallbackTrainerName = name;
      });
      _navigateToChat(context, id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (UserSession.instance.isCoach) {
      return _buildTrainerView(context);
    }
    return _buildAthleteView(context);
  }

  // ─────────────────────────────────────────────────────────────
  // Trainer view — roster list → tap → open chat
  // ─────────────────────────────────────────────────────────────

  Widget _buildTrainerView(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.gbWhite,
      appBar: _AppBar(title: 'Sportolók'),
      body: Column(
        children: [
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
          Expanded(
            child: BlocBuilder<RosterBloc, RosterState>(
              builder: (context, state) {
                if (state is RosterLoading || state is RosterInitial) {
                  return const Center(
                      child: CircularProgressIndicator(color: DT.metricBlue));
                }
                if (state is RosterError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: DT.of(context).iconLightGrey),
                        const SizedBox(height: DT.s3),
                        Text(state.message,
                            style: TextStyle(
                                color: DT.of(context).textSecondary)),
                        const SizedBox(height: DT.s4),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<RosterBloc>().add(LoadRoster()),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: DT.metricBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(DT.rCard))),
                          child: const Text('Újra'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is RosterLoaded) {
                  final lq = _searchQuery.toLowerCase();
                  final athletes = _searchQuery.isEmpty
                      ? state.athletes
                      : state.athletes
                          .where((a) =>
                              a.fullName.toLowerCase().contains(lq) ||
                              a.email.toLowerCase().contains(lq))
                          .toList();

                  if (athletes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: DT.of(context).iconLightGrey),
                          const SizedBox(height: DT.s4),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Még nincs sportoló a csapatodban.'
                                : 'Nincs találat.',
                            style: TextStyle(
                                color: DT.of(context).textSecondary,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: athletes.length,
                    itemBuilder: (context, i) =>
                        _AthleteContactTile(athlete: athletes[i]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Athlete view — auto-navigate to the (single) trainer chat
  // ─────────────────────────────────────────────────────────────

  Widget _buildAthleteView(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Primary: conversations API gives us the trainer's ID + name.
        BlocListener<MessagingBloc, MessagingState>(
          listener: (context, state) {
            if (state is MessagingLoaded) {
              if (state.conversations.isNotEmpty && !_navigated) {
                final conv = state.conversations.first;
                _navigateToChat(context, conv.id, conv.contactName);
              } else if (state.conversations.isEmpty &&
                  !_trainerFallbackStarted) {
                // No messages yet — look up the trainer from the accepted request.
                _trainerFallbackStarted = true;
                final reqState = context.read<TrainerRequestBloc>().state;
                if (reqState is TrainerRequestsLoaded) {
                  // Data already loaded, use it immediately.
                  _handleTrainerRequests(context, reqState.requests);
                } else {
                  context
                      .read<TrainerRequestBloc>()
                      .add(LoadMyRequests());
                }
              }
            }
          },
        ),
        // Fallback: accepted trainer request gives us the trainer's user ID.
        BlocListener<TrainerRequestBloc, TrainerRequestState>(
          listener: (context, state) {
            if (state is TrainerRequestsLoaded && _trainerFallbackStarted) {
              _handleTrainerRequests(context, state.requests);
            }
          },
        ),
      ],
      child: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          // After auto-navigation the athlete may press back.
          // Show the conversation list so they can tap to reopen the chat.
          if (_navigated) {
            return _buildAthleteConversationList(context, state);
          }

          // Still resolving — show a spinner.
          if (state is MessagingError) {
            return Scaffold(
              backgroundColor: DT.gbWhite,
              appBar: _AppBar(title: 'Üzenetek'),
              body: _ErrorView(
                message: state.message,
                onRetry: () {
                  setState(() {
                    _navigated = false;
                    _trainerFallbackStarted = false;
                  });
                  context.read<MessagingBloc>().add(LoadConversations());
                },
              ),
            );
          }

          return Scaffold(
            backgroundColor: DT.gbWhite,
            appBar: _AppBar(title: 'Üzenetek'),
            body: const Center(
                child: CircularProgressIndicator(color: DT.metricBlue)),
          );
        },
      ),
    );
  }

  /// Builds the athlete's "back to trainer" list shown after returning from chat.
  Widget _buildAthleteConversationList(
      BuildContext context, MessagingState state) {
    // Prefer live conversations from the API; fall back to resolved trainer info.
    List<ConversationModel> convs = [];
    if (state is MessagingLoaded && state.conversations.isNotEmpty) {
      convs = state.conversations;
    } else if (_fallbackTrainerId != null) {
      convs = [
        ConversationModel(
          id: _fallbackTrainerId!,
          contactName: _fallbackTrainerName ?? 'Edző',
          contactAvatarUrl: '',
          lastMessage: 'Kezdj el üzenetet küldeni...',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          isOnline: false,
          messages: const [],
        ),
      ];
    }

    return Scaffold(
      backgroundColor: DT.gbWhite,
      appBar: _AppBar(title: 'Üzenetek'),
      body: convs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: DT.of(context).iconLightGrey),
                  const SizedBox(height: DT.s4),
                  Text(
                    'Még nincs üzeneted az edződdel.',
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: convs.length,
              itemBuilder: (context, i) => _ConversationTile(
                conversation: convs[i],
                onTap: () {
                  setState(() => _navigated = false);
                  context
                      .push('/messages/${convs[i].id}',
                          extra: convs[i].contactName)
                      .then((_) {
                    if (mounted) {
                      setState(() => _navigated = true);
                      context
                          .read<MessagingBloc>()
                          .add(LoadConversations());
                    }
                  });
                },
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DT.gbWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: DT.of(context).textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
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
        color: DT.of(context).bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 15, color: DT.of(context).textPrimary),
        decoration: InputDecoration(
          hintText: 'Keresés',
          hintStyle:
              TextStyle(color: DT.of(context).textSecondary, fontSize: 15),
          prefixIcon:
              Icon(Icons.search, color: DT.of(context).iconLight, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.cancel,
                      color: DT.of(context).iconLight, size: 18),
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
        splashColor: DT.metricBlue.withValues(alpha: 0.06),
        highlightColor: DT.of(context).bg,
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
                              color: DT.of(context).textPrimary,
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
                                : DT.of(context).textSecondary,
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
                                  ? DT.of(context).textPrimary
                                  : DT.of(context).textSecondary,
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
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: 15)),
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
        decoration: BoxDecoration(
          color: DT.of(context).bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: DT.of(context).textPrimary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Athlete contact tile (trainer view)
// ─────────────────────────────────────────────────────────────

class _AthleteContactTile extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteContactTile({required this.athlete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/messages/${athlete.id}', extra: athlete.fullName),
        splashColor: DT.metricBlue.withValues(alpha: 0.06),
        highlightColor: DT.of(context).bg,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DT.s4, vertical: 10),
          child: Row(
            children: [
              AvatarWidget(name: athlete.fullName, size: 56),
              const SizedBox(width: DT.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DT.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      athlete.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: DT.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: DT.of(context).iconLight, size: 20),
            ],
          ),
        ),
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
        color: _color.withValues(alpha: 0.18),
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
