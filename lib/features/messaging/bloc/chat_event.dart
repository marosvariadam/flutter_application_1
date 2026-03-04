part of 'chat_bloc.dart';

abstract class ChatEvent {}

class LoadChat extends ChatEvent {
  final String contactId;
  LoadChat(this.contactId);
}

class SendMessage extends ChatEvent {
  final String text;
  SendMessage(this.text);
}

/// Fired when the SignalR hub pushes a new message.
class MessageReceivedFromHub extends ChatEvent {
  final Map<String, dynamic> data;
  MessageReceivedFromHub(this.data);
}
