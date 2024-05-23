import 'package:ai_buddy/feature/hive/model/audio_message/audio_message.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';

abstract class BaseHiveRepository {
  Future<void> saveChatBot({
    required ChatBot chatBot,
  });
  Future<void> deleteChatBot({
    required ChatBot chatBot,
  });
  Future<List<ChatBot>> getChatBots();

  Future<void> saveAudioMessage({required AudioMessage audioMessage});

  Future<AudioMessage?> getAudioMessage({required String id});

  Future<void> deleteAudioMessage({
    required String id,
  });
}
