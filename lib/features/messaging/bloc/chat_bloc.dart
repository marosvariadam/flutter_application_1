import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_application_1/features/messaging/data/models/message_model.dart';
import 'package:flutter_application_1/features/messaging/bloc/messaging_bloc.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onLoadChat(
    LoadChat event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final conversation = MessagingBloc.getById(event.contactId);
      if (conversation == null) {
        emit(ChatError('A beszélgetés nem található.'));
        return;
      }
      emit(ChatLoaded(conversation));
    } catch (e) {
      emit(ChatError('Nem sikerült betölteni a beszélgetést.'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final newMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: event.text,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    final updatedMessages = [...current.conversation.messages, newMessage];
    emit(ChatLoaded(current.conversation.copyWith(messages: updatedMessages)));
  }
}
