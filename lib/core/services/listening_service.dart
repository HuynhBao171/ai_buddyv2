import 'dart:async';

import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/feature/hive/model/audio_message/audio_message.dart';
import 'package:ai_buddy/feature/hive/repository/hive_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ListeningService with ServiceLoggy {
  final SpeechToText _speechToText = SpeechToText();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _speechEnabled = false;
  bool isFinished = false;
  String? _recordedFilePath;
  String? recognizedText;

  Future<void> initSpeech() async {
    loggy.info('Initializing speech-to-text service...');
    isFinished = false;
    try {
      _speechEnabled = await _speechToText.initialize();
      loggy.info('Speech-to-text service initialized successfully.');
    } catch (e) {
      loggy.error('Error initializing speech-to-text service: $e');
    }
  }

  Future<void> startListening() async {
    loggy.info('Starting listening...');
    if (!_speechEnabled) {
      loggy.warning('Speech-to-text is not enabled.');
      return;
    }

    try {
      if (await Permission.microphone.request().isGranted &&
          await Permission.storage.request().isGranted) {
        recognizedText = null;

        // Bắt đầu ghi âm
        final tempDir = await getTemporaryDirectory();
        _recordedFilePath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
        await _audioRecorder.start(
          const RecordConfig(),
          path: _recordedFilePath!,
        );

        // Bắt đầu speech-to-text
        await _speechToText.listen(onResult: _onSpeechResult);
        loggy.info('Listening started.');
      } else {
        loggy.warning('Microphone or storage permission denied.');
      }
    } catch (e) {
      loggy.error('Error starting listening: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      recognizedText = result.recognizedWords;
    }
  }

  Future<String> stopListening({required String id}) async {
    loggy.info('Stopping listening...');
    try {
      // Dừng AudioRecorder trước
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
        await _audioRecorder.dispose(); // Giải phóng tài nguyên
      }

      // Dừng SpeechToText sau
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      isFinished = true;

      if (_recordedFilePath != null) {
        final audioMessage = AudioMessage(
          id: id,
          filePath: _recordedFilePath!,
        );
        try {
          await HiveRepository().saveAudioMessage(audioMessage: audioMessage);
          loggy.info('Audio message saved successfully.');
        } catch (e) {
          loggy.error('Error saving audio message: $e');
        }
      }

      return recognizedText ?? '';
    } catch (e) {
      loggy.error('Error stopping listening: $e');
      return '';
    }
  }

  Future<void> playAudio() async {
    loggy.info('Playing audio...');
    if (_recordedFilePath != null) {
      try {
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      } catch (e) {
        loggy.error('Error playing audio: $e');
      }
    }
  }
}
