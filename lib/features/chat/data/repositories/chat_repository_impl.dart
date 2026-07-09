import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl(this.localDataSource);

  @override
  Future<List<ChatMessageModel>> getMessages() async {
    return localDataSource.getMessages();
  }

  @override
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    await localDataSource.saveMessages(messages);
  }

  @override
  Future<void> clearMessages() async {
    await localDataSource.clearMessages();
  }
}
