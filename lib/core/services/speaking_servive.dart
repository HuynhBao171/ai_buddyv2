import 'dart:io';

import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/core/services/deepgram_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:loggy/loggy.dart';

class SpeakingService with ServiceLoggy {
  final DeepgramService deepgramService;

  SpeakingService({required this.deepgramService});

  Future initTts() async {
    loggy
      ..info('SpeakingService: Initializing TTS...')
      ..info('SpeakingService: TTS initialized.');
  }

  Future<void> speak(String text) async {
    loggy.info('SpeakingService: Speak requested. Text: $text');
    try {
      // Chuyển đổi text thành audio sử dụng DeepgramService
      loggy.info('SpeakingService: Converting text to audio...');
      final audioFilePath = await deepgramService.convertTextToAudio(text);
      loggy.info('SpeakingService: Audio file path: $audioFilePath');

      // Phát audio sử dụng AudioPlayer
      final player = AudioPlayer();
      loggy.info('SpeakingService: Playing audio...');
      await player.play(DeviceFileSource(audioFilePath));

      // Xóa audio file sau khi phát xong
      player.onPlayerComplete.listen((event) {
        loggy.info('SpeakingService: Audio playback completed.');
        File(audioFilePath).delete().then((_) {
          loggy.info('SpeakingService: Audio file deleted: $audioFilePath');
        }).catchError((error) {
          loggy.error('SpeakingService: Error deleting audio file: $error');
        });
      });
    } catch (e) {
      loggy.error('SpeakingService: Error speaking: $e');
    }
  }
}
