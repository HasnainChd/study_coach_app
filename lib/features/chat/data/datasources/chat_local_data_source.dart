import 'package:hive/hive.dart';
import '../models/chat_message_model.dart';

abstract class ChatLocalDataSource {
  Future<List<ChatMessageModel>> getMessages();
  Future<void> saveMessages(List<ChatMessageModel> messages);
  Future<void> clearMessages();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final Box _box;

  ChatLocalDataSourceImpl(this._box);

  static const String _keyMessages = 'chat_messages';

  @override
  Future<List<ChatMessageModel>> getMessages() async {
    final List<dynamic>? rawList = _box.get(_keyMessages);
    if (rawList == null) return [];
    return rawList
        .map(
          (item) =>
              ChatMessageModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    final rawList = messages.map((m) => m.toMap()).toList();
    await _box.put(_keyMessages, rawList);
  }

  @override
  Future<void> clearMessages() async {
    await _box.delete(_keyMessages);
  }
}
