part of 'messaging_bloc.dart';

abstract class MessagingEvent {}

class LoadConversations extends MessagingEvent {}

/// Immediately moves a conversation to the top of the list using a locally
/// known timestamp (e.g. from ChatBloc after sending/receiving a message).
/// This fires before LoadConversations so the UI re-orders instantly without
/// waiting for the server round-trip.
class BumpConversation extends MessagingEvent {
  final String conversationId;
  final String lastMessage;
  final DateTime lastMessageTime;
  BumpConversation({
    required this.conversationId,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}
