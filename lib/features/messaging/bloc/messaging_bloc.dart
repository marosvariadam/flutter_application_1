import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/messaging/data/models/conversation_model.dart';
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

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    try {
      final conversations = await _repo!.getConversations();
      emit(MessagingLoaded(conversations));
    } catch (_) {
      emit(MessagingError('Nem sikerült betölteni az üzeneteket.'));
    }
  }
}
