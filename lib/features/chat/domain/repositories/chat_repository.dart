import '../../data/models/chat_message_model.dart';

abstract class ChatRepository {
  /// Load persisted messages from local storage.
  Future<List<ChatMessageModel>> getMessages();

  /// Persist the full message list to local storage.
  Future<void> saveMessages(List<ChatMessageModel> messages);

  /// Wipe all persisted messages.
  Future<void> clearMessages();
}
