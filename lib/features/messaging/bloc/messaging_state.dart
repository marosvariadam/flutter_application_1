part of 'messaging_bloc.dart';

abstract class MessagingState {}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class MessagingLoaded extends MessagingState {
  final List<ConversationModel> conversations;
  MessagingLoaded(this.conversations);
}

class MessagingError extends MessagingState {
  final String message;
  MessagingError(this.message);
}
