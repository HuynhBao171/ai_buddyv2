import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/feature/hive/model/audio_message/audio_message.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:ai_buddy/feature/hive/repository/base_hive_repository.dart';
import 'package:hive/hive.dart';

class HiveRepository with RepositoryLoggy implements BaseHiveRepository {
  HiveRepository();
  final Box<ChatBot> _chatBot = Hive.box<ChatBot>('chatbots');
  final Box<AudioMessage> _audioMessage =
      Hive.box<AudioMessage>('audioMessages');

  @override
  Future<void> saveChatBot({required ChatBot chatBot}) async {
    await _chatBot.put(chatBot.id, chatBot);
  }

  @override
  Future<List<ChatBot>> getChatBots() async {
    final chatBotBox = await Hive.openBox<ChatBot>('chatBots');
    final List<ChatBot> chatBotsList = chatBotBox.values.toList();
    return chatBotsList;
  }

  @override
  Future<void> deleteChatBot({required ChatBot chatBot}) async {
    await _chatBot.delete(chatBot.id);
  }

  @override
Future<void> saveAudioMessage({required AudioMessage audioMessage}) async {
  try {
    await _audioMessage.put(audioMessage.id, audioMessage);
    loggy.info('Audio message with id ${audioMessage.id} saved successfully');
  } catch (e) {
    loggy.error('Error saving audio message with id ${audioMessage.id}: $e');
    rethrow;
  }
}

  @override
  Future<AudioMessage> getAudioMessage({required String id}) async {
    try {
      final audioMessage = _audioMessage.get(id);
      if (audioMessage == null) {
        throw Exception('Audio message with id $id not found');
      }
      loggy.info('Audio message with id $id retrieved successfully');
      return audioMessage;
    } catch (e) {
      loggy.error('Error retrieving audio message with id $id: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAudioMessage({required String id}) {
    return _audioMessage.delete(id);
  }
}
