import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:flutter_application_1/features/messaging/bloc/chat_bloc.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/trainer/bloc/roster_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';

//
// Page
//

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Set to true after the one-time auto-navigation fires. Never reset.
  // Using addPostFrameCallback + this flag makes the auto-nav loop-proof:
  // even if the MessagingPage remounts (branch reset via bottom-nav tap),
  // the flag prevents a second push.
  bool _autoNavDone = false;

  // Prevents duplicate LoadMyRequests dispatches for the trainer fallback.
  bool _trainerLookupStarted = false;

  // Trainer info resolved from the accepted trainer request (fallback path
  // used when no conversation history exists yet).
  String? _fallbackTrainerId;
  String? _fallbackTrainerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (UserSession.instance.isCoach) {
        if (context.read<RosterBloc>().state is! RosterLoaded) {
          context.read<RosterBloc>().add(LoadRoster());
        }
        context.read<MessagingBloc>().add(LoadConversations());
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

  // Helpers

  void _openChat(BuildContext context, String id, String name) {
    final chatBloc = context.read<ChatBloc>();
    final messagingBloc = context.read<MessagingBloc>();
    context.push('/messages/$id', extra: name).then((_) {
      if (!mounted) return;
      final chatState = chatBloc.state;
      if (chatState is ChatLoaded &&
          chatState.conversation.messages.isNotEmpty) {
        final last = chatState.conversation.messages.last;
        messagingBloc.add(BumpConversation(
          conversationId: id,
          lastMessage: last.text,
          lastMessageTime: last.timestamp,
        ));
      }
      messagingBloc.add(LoadConversations());
    });
  }

  void _resolveTrainer(List<TrainerRequestModel> requests) {
    for (final r in requests) {
      if (r.isAccepted && r.trainerId != null) {
        if (mounted) {
          setState(() {
            _fallbackTrainerId = r.trainerId;
            _fallbackTrainerName =
                r.trainerName ?? r.trainerEmail ?? 'Edző';
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (UserSession.instance.isCoach) {
      return _buildTrainerView(context);
    }
    return _buildAthleteView(context);
  }

  //
  // Trainer view - roster list -> tap -> open chat
  //

  Widget _buildTrainerView(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).cardSurface,
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
              builder: (context, rosterState) {
                if (rosterState is RosterLoading ||
                    rosterState is RosterInitial) {
                  return const Center(
                      child: CircularProgressIndicator(color: DT.metricBlue));
                }
                if (rosterState is RosterError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: DT.of(context).iconLightGrey),
                        const SizedBox(height: DT.s3),
                        Text(rosterState.message,
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
                if (rosterState is RosterLoaded) {
                  return BlocBuilder<MessagingBloc, MessagingState>(
                    builder: (context, msgState) {
                      // Build normalised-id->conversation map.
                      // Lowercase both keys and lookups to handle GUID casing
                      // differences between roster and conversations endpoints.
                      final convMap = <String, ConversationModel>{};
                      if (msgState is MessagingLoaded) {
                        for (final c in msgState.conversations) {
                          convMap[c.id.toLowerCase()] = c;
                        }
                      }

                      final lq = _searchQuery.toLowerCase();
                      var athletes = _searchQuery.isEmpty
                          ? rosterState.athletes.toList()
                          : rosterState.athletes
                              .where((a) =>
                                  a.fullName.toLowerCase().contains(lq) ||
                                  a.email.toLowerCase().contains(lq))
                              .toList();

                      // Sort: athletes with conversations first (newest on top),
                      // then athletes with no conversation yet.
                      athletes.sort((a, b) {
                        final ta = convMap[a.id.toLowerCase()]?.lastMessageTime;
                        final tb = convMap[b.id.toLowerCase()]?.lastMessageTime;
                        if (ta == null && tb == null) return 0;
                        if (ta == null) return 1;
                        if (tb == null) return -1;
                        return tb.compareTo(ta);
                      });

                      if (athletes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64,
                                  color: DT.of(context).iconLightGrey),
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
                        itemBuilder: (context, i) {
                          final athlete = athletes[i];
                          final conv = convMap[athlete.id.toLowerCase()];
                          if (conv != null) {
                            return _ConversationTile(
                              conversation: conv,
                              onTap: () => _openChat(
                                  context, athlete.id, athlete.fullName),
                            );
                          }
                          return _AthleteContactTile(athlete: athlete);
                        },
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
    );
  }

  //
  // Athlete view
  //

  Widget _buildAthleteView(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MessagingBloc, MessagingState>(
          listener: (context, state) {
            if (state is! MessagingLoaded) return;

            if (state.conversations.isNotEmpty && !_autoNavDone) {
              // Auto-navigate once to the trainer chat. Scheduling via
              // addPostFrameCallback avoids navigating mid-build and ensures
              // _autoNavDone is committed before the next listener fires.
              _autoNavDone = true;
              final conv = state.conversations.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _openChat(context, conv.id, conv.contactName);
              });
            } else if (state.conversations.isEmpty &&
                !_trainerLookupStarted) {
              // No conversation history yet - find the trainer via requests.
              _trainerLookupStarted = true;
              final reqState = context.read<TrainerRequestBloc>().state;
              if (reqState is TrainerRequestsLoaded) {
                _resolveTrainer(reqState.requests);
              } else {
                context.read<TrainerRequestBloc>().add(LoadMyRequests());
              }
            }
          },
        ),
        BlocListener<TrainerRequestBloc, TrainerRequestState>(
          listener: (context, state) {
            if (state is! TrainerRequestsLoaded) return;
            _resolveTrainer(state.requests);
            // If auto-nav hasn't fired yet and we just resolved a trainer,
            // navigate to that trainer's chat now (first-time user path).
            if (!_autoNavDone && _fallbackTrainerId != null) {
              _autoNavDone = true;
              final id = _fallbackTrainerId!;
              final name = _fallbackTrainerName ?? 'Edző';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _openChat(context, id, name);
              });
            }
          },
        ),
      ],
      child: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          if (state is MessagingLoading || state is MessagingInitial) {
            return Scaffold(
              backgroundColor: DT.of(context).cardSurface,
              appBar: _AppBar(title: 'Üzenetek'),
              body: const Center(
                  child: CircularProgressIndicator(color: DT.metricBlue)),
            );
          }

          if (state is MessagingError) {
            return Scaffold(
              backgroundColor: DT.of(context).cardSurface,
              appBar: _AppBar(title: 'Üzenetek'),
              body: _ErrorView(
                message: state.message,
                onRetry: () {
                  setState(() => _trainerLookupStarted = false);
                  context.read<MessagingBloc>().add(LoadConversations());
                },
              ),
            );
          }

          // MessagingLoaded - show conversation list.
          final loaded = state is MessagingLoaded ? state : null;
          List<ConversationModel> convs =
              loaded?.conversations.isNotEmpty == true
                  ? loaded!.conversations
                  : _fallbackTrainerId != null
                      ? [
                          ConversationModel(
                            id: _fallbackTrainerId!,
                            contactName: _fallbackTrainerName ?? 'Edző',
                            contactAvatarUrl: '',
                            lastMessage: 'Kezdj el üzenetet küldeni...',
                            lastMessageTime: DateTime.now(),
                            unreadCount: 0,
                            isOnline: false,
                            messages: const [],
                          )
                        ]
                      : [];

          return Scaffold(
            backgroundColor: DT.of(context).cardSurface,
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
                              color: DT.of(context).textSecondary,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: convs.length,
                    itemBuilder: (ctx, i) => _ConversationTile(
                      conversation: convs[i],
                      onTap: () =>
                          _openChat(ctx, convs[i].id, convs[i].contactName),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

//
// AppBar
//

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DT.of(context).cardSurface,
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

//
// Search bar
//

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

//
// Conversation tile
//

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
              // Avatar
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
                              color: DT.of(context).textOnAccent, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: DT.s3),

              // Text content
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

//
// Error view
//

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

//
// Athlete contact tile (trainer view)
//

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

//
// Small helpers
//

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

//
// AvatarWidget - PUBLIC so chat_page.dart can import it
//

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
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
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
