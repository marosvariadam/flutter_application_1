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
import 'package:flutter_application_1/app/design/dt_text.dart';
import 'package:flutter_application_1/app/shared/reload_and_wait.dart';
import 'package:flutter_application_1/app/shared/widgets/empty_state.dart';
import 'package:flutter_application_1/app/shared/widgets/error_state.dart';
import 'package:flutter_application_1/app/shared/widgets/fade_switcher.dart';
import 'package:flutter_application_1/app/shared/widgets/refreshable_fill.dart';
import 'package:flutter_application_1/app/shared/widgets/skeleton.dart';
import 'package:flutter_application_1/app/shared/widgets/user_avatar.dart';

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
      appBar: const _AppBar(title: 'Sportolók'),
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
              builder: (context, rosterState) => FadeSwitcher(
                  child: _trainerList(context, rosterState)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTrainer() {
    final roster = context.read<RosterBloc>();
    context.read<MessagingBloc>().add(LoadConversations());
    return reloadAndWait(
        roster, () => roster.add(LoadRoster()), (s) => s is! RosterLoading);
  }

  Widget _trainerList(BuildContext context, RosterState rosterState) {
                if (rosterState is RosterError) {
                  return ErrorState(
                    key: const ValueKey('error'),
                    message: rosterState.message,
                    onRetry: () =>
                        context.read<RosterBloc>().add(LoadRoster()),
                  );
                }
                if (rosterState is! RosterLoaded) {
                  return const SkeletonList(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.all(DT.s4));
                }
                {
                  return BlocBuilder<MessagingBloc, MessagingState>(
                    key: const ValueKey('content'),
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
                        return RefreshIndicator(
                          onRefresh: _refreshTrainer,
                          child: RefreshableFill(
                            child: _searchQuery.isEmpty
                                ? const EmptyState(
                                    icon: Icons.people_outline,
                                    title: 'Még nincs sportoló a csapatodban',
                                    message:
                                        'Az elfogadott jelentkezőknek itt tudsz írni.',
                                  )
                                : const EmptyState(
                                    icon: Icons.search_off,
                                    title: 'Nincs találat',
                                  ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshTrainer,
                        child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                        ),
                      );
                    },
                  );
                }
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
              appBar: const _AppBar(title: 'Üzenetek'),
              body: const SkeletonList(padding: EdgeInsets.all(DT.s4)),
            );
          }

          if (state is MessagingError) {
            return Scaffold(
              backgroundColor: DT.of(context).cardSurface,
              appBar: const _AppBar(title: 'Üzenetek'),
              body: ErrorState(
                message: state.message,
                onRetry: () {
                  setState(() => _trainerLookupStarted = false);
                  context.read<MessagingBloc>().add(LoadConversations());
                },
              ),
            );
          }

          final messaging = context.read<MessagingBloc>();
          Future<void> refresh() => reloadAndWait(
              messaging,
              () => messaging.add(LoadConversations()),
              (s) => s is MessagingLoaded || s is MessagingError);

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
            appBar: const _AppBar(title: 'Üzenetek'),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: convs.isEmpty
                  ? const RefreshableFill(
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Még nincs üzeneted az edződdel',
                        message:
                            'Ha egy edző elfogadja a kérésed, itt tudsz neki írni.',
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: convs.length,
                      itemBuilder: (ctx, i) => _ConversationTile(
                        conversation: convs[i],
                        onTap: () =>
                            _openChat(ctx, convs[i].id, convs[i].contactName),
                      ),
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
  // ignore: unused_element_parameter
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
      title: Text(title, style: DTText.of(context).h1),
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
              ? IconButton(
                  tooltip: 'Keresés törlése',
                  onPressed: onClear,
                  icon: Icon(Icons.cancel,
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
        splashColor: DT.of(context).accentPrimary.withValues(alpha: 0.06),
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
                  UserAvatar(name: conversation.contactName, size: 56),
                  if (conversation.isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: DT.of(context).accentSuccess,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: DT.of(context).cardSurface, width: 2.5),
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
                                ? DT.of(context).accentPrimary
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
                            decoration: BoxDecoration(
                              color: DT.of(context).accentPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${conversation.unreadCount}',
                                style: TextStyle(
                                  color: DT.of(context).textOnAccent,
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
        splashColor: DT.of(context).accentPrimary.withValues(alpha: 0.06),
        highlightColor: DT.of(context).bg,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DT.s4, vertical: 10),
          child: Row(
            children: [
              UserAvatar(name: athlete.fullName, size: 56),
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
