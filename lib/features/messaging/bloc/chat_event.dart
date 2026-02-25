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
