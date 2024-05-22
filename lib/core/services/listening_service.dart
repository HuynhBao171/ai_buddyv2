import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ListeningService {
  final SpeechToText _speechToText = SpeechToText();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _speechEnabled = false;
  bool isFinished = false;
  String? _recordedFilePath;
  String? recognizedText;

  Future<void> initSpeech() async {
    isFinished = false;
    _speechEnabled = await _speechToText.initialize();
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      return;
    }

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
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      recognizedText = result.recognizedWords;
    }
  }

  Future<String> stopListening({required String id}) async {
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

    // ... (phần lưu AudioMessage vào Hive giữ nguyên)

    return recognizedText ?? '';
  }

  Future<void> playAudio() async {
    if (_recordedFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }
}
