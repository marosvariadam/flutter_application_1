import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  MessagingBloc() : super(MessagingInitial()) {
    on<LoadConversations>(_onLoadConversations);
  }

  static final _now = DateTime.now();

  // Mock data — replace with repository/API call when backend is ready
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
          id: 'm2',
          text: 'Nagyon jól ment! Az alsó testem fájt, de kitartottam.',
          timestamp: _now.subtract(const Duration(hours: 1, minutes: 20)),
          isSentByMe: true,
        ),
        MessageModel(
          id: 'm3',
          text: 'Kiváló! Büszke vagyok rád. A kitartás a siker kulcsa.',
          timestamp: _now.subtract(const Duration(hours: 1)),
          isSentByMe: false,
        ),
        MessageModel(
          id: 'm4',
          text: 'Köszönöm! Mikor találkozunk legközelebb?',
          timestamp: _now.subtract(const Duration(minutes: 10)),
          isSentByMe: true,
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
          id: 'm1',
          text: 'Szia Anna! Mehetünk holnap kora reggeli edzésre?',
          timestamp: _now.subtract(const Duration(hours: 3)),
          isSentByMe: true,
        ),
        MessageModel(
          id: 'm2',
          text: 'Természetesen! 7:00-ra ott leszek.',
          timestamp: _now.subtract(const Duration(hours: 2, minutes: 45)),
          isSentByMe: false,
        ),
        MessageModel(
          id: 'm3',
          text: 'Remek teljesítmény ma! Büszke vagyok rád.',
          timestamp: _now.subtract(const Duration(hours: 1)),
          isSentByMe: false,
        ),
      ],
    ),
    ConversationModel(
      id: '3',
      contactName: 'Edzőterem Csoport',
      contactAvatarUrl: '',
      lastMessage: 'Ne felejtsétek el a versenyt szombaton!',
      lastMessageTime: _now.subtract(const Duration(hours: 3)),
      unreadCount: 5,
      isOnline: false,
      messages: [
        MessageModel(
          id: 'm1',
          text: 'Helló mindenki! Ki jön el a hétvégi csoportos edzésre?',
          timestamp: _now.subtract(const Duration(hours: 5)),
          isSentByMe: false,
        ),
        MessageModel(
          id: 'm2',
          text: 'Én ott leszek!',
          timestamp: _now.subtract(const Duration(hours: 4, minutes: 30)),
          isSentByMe: true,
        ),
        MessageModel(
          id: 'm3',
          text: 'Ne felejtsétek el a versenyt szombaton!',
          timestamp: _now.subtract(const Duration(hours: 3)),
          isSentByMe: false,
        ),
      ],
    ),
    ConversationModel(
      id: '4',
      contactName: 'Kiss Péter',
      contactAvatarUrl: '',
      lastMessage: 'Együtt edzünk holnap?',
      lastMessageTime: _now.subtract(const Duration(days: 1)),
      unreadCount: 1,
      isOnline: true,
      messages: [
        MessageModel(
          id: 'm1',
          text: 'Szia! Milyen tempóban futottál ma?',
          timestamp: _now.subtract(const Duration(days: 1, hours: 2)),
          isSentByMe: false,
        ),
        MessageModel(
          id: 'm2',
          text: '5:30 perc/km, elég jól sikerült!',
          timestamp: _now.subtract(const Duration(days: 1, hours: 1)),
          isSentByMe: true,
        ),
        MessageModel(
          id: 'm3',
          text: 'Együtt edzünk holnap?',
          timestamp: _now.subtract(const Duration(days: 1)),
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
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      emit(MessagingLoaded(List.from(_mockConversations)));
    } catch (e) {
      emit(MessagingError('Nem sikerült betölteni az üzeneteket.'));
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
