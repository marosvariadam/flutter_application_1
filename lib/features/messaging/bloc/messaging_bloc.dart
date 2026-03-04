import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';
import 'package:flutter_application_1/features/messaging/data/repositories/message_repository.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessageRepository? _repo;

  MessagingBloc({MessageRepository? repo})
      : _repo = repo,
        super(MessagingInitial()) {
    on<LoadConversations>(_onLoadConversations);
  }

  static final _now = DateTime.now();

  // Mock data — used as fallback when no repository is provided
  static final List<ConversationModel> _mockConversations = [
    ConversationModel(
      id: '1',
      contactName: 'Bajnok Ádám',
      contactAvatarUrl: '',
      lastMessage: 'Holnap 10-kor találkozunk!',
      lastMessageTime: _now.subtract(const Duration(minutes: 2)),
      unreadCount: 2,
      isOnline: true,
      messages: [
        MessageModel(
          id: 'm1',
          text: 'Szia! Hogy sikerült a mai edzés?',
          timestamp: _now.subtract(const Duration(hours: 1, minutes: 30)),
          isSentByMe: false,
        ),
        MessageModel(
          id: 'm5',
          text: 'Holnap 10-kor találkozunk!',
          timestamp: _now.subtract(const Duration(minutes: 2)),
          isSentByMe: false,
        ),
      ],
    ),
    ConversationModel(
      id: '2',
      contactName: 'Szilágyi Anna',
      contactAvatarUrl: '',
      lastMessage: 'Remek teljesítmény ma! Büszke vagyok rád.',
      lastMessageTime: _now.subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
      messages: [
        MessageModel(
          id: 'm3',
          text: 'Remek teljesítmény ma! Büszke vagyok rád.',
          timestamp: _now.subtract(const Duration(hours: 1)),
          isSentByMe: false,
        ),
      ],
    ),
  ];

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    try {
      if (_repo != null) {
        final conversations = await _repo!.getConversations();
        emit(MessagingLoaded(conversations));
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        emit(MessagingLoaded(List.from(_mockConversations)));
      }
    } catch (_) {
      // API failed — fall back to mock
      emit(MessagingLoaded(List.from(_mockConversations)));
    }
  }

  static ConversationModel? getById(String id) {
    try {
      return _mockConversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
