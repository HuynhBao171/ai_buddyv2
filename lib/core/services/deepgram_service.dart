import 'dart:async';
import 'dart:io';

import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/core/services/recording_service.dart';
import 'package:ai_buddy/main.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

Map<String, dynamic> baseParams = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
  'encoding': 'aac',
};

final apiKey = dotenv.get('DEEPGRAM_API_KEY');
Deepgram deepgram = Deepgram(apiKey, baseQueryParams: baseParams);

final recordingServiceProviver =
    Provider<RecordingService>((ref) => RecordingService());

final deepgramServiceProviver = Provider<DeepgramService>(
  (ref) =>
      DeepgramService(recordingService: ref.watch(recordingServiceProviver)),
);

class DeepgramService with ServiceLoggy {
  DeepgramService({required this.recordingService});
  final RecordingService recordingService;
  DeepgramLiveTranscriber? _liveTranscriber;

  Future<String> _convertAudioToText(String audioId) async {
    loggy.info('DeepgramService: Converting audio to text...');
    final audioMessage = await recordingService.getAudio(id: audioId);
    loggy.info('DeepgramService: Audio file path: ${audioMessage.filePath}');
    try {
      final response = await deepgram.transcribeFromFile(
        File(audioMessage.filePath),
      );
      loggy
        ..info('DeepgramService: Audio to text conversion successful.')
        ..info('DeepgramService: Transcript: ${response.transcript}');
      return response.transcript;
    } catch (e) {
      loggy.error('DeepgramService: Error converting audio to text: $e');
      rethrow;
    }
  }

  Future<Uint8List> _convertTextToAudio(String text) async {
    loggy
      ..info('DeepgramService: Converting text to audio...')
      ..info('DeepgramService: Text: $text');
    final Deepgram deepgramTTS = Deepgram(apiKey, baseQueryParams: {
      'model': 'aura-asteria-en',
      'encoding': 'linear16',
      'container': 'wav',
    });
    try {
      final res = await deepgramTTS.speakFromText(text);
      loggy.info('DeepgramService: Text to audio conversion successful.');
      return res.data;
    } catch (e) {
      loggy.error('DeepgramService: Error converting text to audio: $e');
      rethrow;
    }
  }

  // Hàm chuyển đổi file audio thành text
  Future<String> convertAudioToText(String audioId) async {
    loggy.info('DeepgramService: Starting audio to text conversion...');
    try {
      final transcript = await _convertAudioToText(audioId);
      loggy.info('DeepgramService: Audio to text conversion completed.');
      return transcript;
    } catch (e) {
      loggy.error('DeepgramService: Error during audio to text conversion: $e');
      rethrow;
    }
  }

  // Hàm chuyển đổi text thành file audio
  Future<String> convertTextToAudio(String text) async {
    loggy.info('DeepgramService: Starting text to audio conversion...');
    try {
      final bytes = await _convertTextToAudio(text);
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(path).writeAsBytes(bytes);
      loggy
        ..info('DeepgramService: Audio file saved to: $path')
        ..info('DeepgramService: Text to audio conversion completed.');
      return path;
    } catch (e) {
      loggy.error('DeepgramService: Error during text to audio conversion: $e');
      rethrow;
    }
  }

  // Bắt đầu live transcription

  Future<void> startLiveTranscription(
      {required Stream<List<int>> audioStream}) async {
    loggy.info('DeepgramService: Starting live transcription...');

    // Làm mới stream mỗi khi startLiveTranscription được gọi
    await liveTranscriptionStream.sink.close();

    try {
      final liveParams = {
        'detect_language': false,
        'language': 'en',
        'encoding': 'linear16',
        'sample_rate': 16000,
      };
      _liveTranscriber =
          deepgram.createLiveTranscriber(audioStream, queryParams: liveParams);
      await _liveTranscriber!.start();

      _liveTranscriber!.stream.listen((res) {
        loggy.info('DeepgramService: Live Transcript: ${res.transcript}');

        // Thêm transcript vào stream
        liveTranscriptionStream.sink.add(res.transcript);
      });
      loggy.info('DeepgramService: Live transcription started.');
    } catch (e) {
      loggy.error('DeepgramService: Error starting live transcription: $e');
      rethrow;
    }
  }

  // Dừng live transcription
  Future<void> stopLiveTranscription() async {
    loggy.info('DeepgramService: Stopping live transcription...');
    try {
      await _liveTranscriber?.close();
      loggy.info('DeepgramService: Live transcription stopped.');
    } catch (e) {
      loggy.error('DeepgramService: Error stopping live transcription: $e');
      rethrow;
    }
  }
}
