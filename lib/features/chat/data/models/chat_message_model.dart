/// A serialisable wrapper around a chat message.
///
/// Stored as a plain [Map<String, dynamic>] inside a Hive [Box], using the
/// same pattern as [AgendaItemModel] — no generated type adapters required.
class ChatMessageModel {
  final String id;

  /// 'bot' or 'user'
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      sender: map['sender'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
