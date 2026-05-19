import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';
import 'package:flutter_application_1/features/messaging/data/repositories/message_repository.dart';
import 'package:flutter_application_1/features/messaging/services/chat_hub_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository? _repo;
  final ChatHubService? _hub;

  ChatBloc({MessageRepository? repo, ChatHubService? hub})
      : _repo = repo,
        _hub = hub,
        super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<MessageReceivedFromHub>(_onHubMessage);

    _hub?.onMessageReceived = (data) {
      try {
        add(MessageReceivedFromHub(data));
      } catch (_) {}
    };
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    // If we're re-entering a conversation we already have in memory, keep
    // those messages visible while we try to refresh from the server.
    // This prevents a blank flash when the backend history endpoint isn't
    // implemented or temporarily unavailable.
    final current = state;
    final cached = (current is ChatLoaded &&
            current.conversation.id == event.contactId)
        ? current.conversation
        : null;

    if (cached == null) emit(ChatLoading());

    try {
      final repo = _repo!;
      final messages = await repo.getThread(event.contactId);

      if (messages.isNotEmpty) {
        // Server returned history - use it as the source of truth.
        emit(ChatLoaded(ConversationModel(
          id: event.contactId,
          contactName:
              event.contactName ?? cached?.contactName ?? event.contactId,
          contactAvatarUrl: '',
          lastMessage: messages.last.text,
          lastMessageTime: messages.last.timestamp,
          unreadCount: 0,
          isOnline: false,
          messages: messages,
        )));
      } else if (cached != null) {
        // Server returned empty but we have in-memory messages - keep them.
        // This is the common case when the backend history endpoint is not
        // yet implemented (returns 200 [] or 404).
      } else {
        emit(ChatLoaded(_emptyConversation(event.contactId, event.contactName)));
      }

      // markRead is (do not await).
      try {
        await repo.markRead(event.contactId);
      } catch (_) {}
    } catch (_) {
      // API call failed. If we have cached messages, keep them; otherwise
      // show an empty chat so the user can still send a first message.
      if (cached == null) {
        emit(ChatLoaded(_emptyConversation(event.contactId, event.contactName)));
      }
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final newMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: event.text,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    final previousMessages = current.conversation.messages.toList();
    final updated = [...previousMessages, newMessage];
    emit(ChatLoaded(current.conversation.copyWith(messages: updated)));
    try {
      await _repo?.sendMessage(current.conversation.id, event.text);
    } catch (_) {
      // Revert the optimistic message on failure.
      emit(ChatLoaded(current.conversation.copyWith(messages: previousMessages)));
    }
  }

  ConversationModel _emptyConversation(String id, String? name) =>
      ConversationModel(
        id: id,
        contactName: name ?? id,
        contactAvatarUrl: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: false,
        messages: const [],
      );

  void _onHubMessage(
      MessageReceivedFromHub event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded) return;
    try {
      final msg = MessageModel(
        id: event.data['id'] as String? ??
            'hub_${DateTime.now().millisecondsSinceEpoch}',
        text: event.data['content'] as String? ?? '',
        timestamp: event.data['createdAt'] != null
            ? DateTime.parse(event.data['createdAt'] as String)
            : DateTime.now(),
        isSentByMe: false,
      );
      final updated = [...current.conversation.messages, msg];
      emit(ChatLoaded(current.conversation.copyWith(messages: updated)));
    } catch (_) {}
  }
}
