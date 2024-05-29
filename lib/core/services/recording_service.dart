import 'dart:async';
import 'dart:io';

import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/feature/hive/model/audio_message/audio_message.dart';
import 'package:ai_buddy/feature/hive/repository/hive_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingService with ServiceLoggy {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool isFinished = false;
  String _recordedFilePath = '';

  final HiveRepository _hiveRepository = HiveRepository();

  Future<void> startRecording() async {
    loggy.info('Starting recording...');
    try {
      if (!(await Permission.microphone.request().isGranted)) {
        loggy.warning('Microphone permission denied.');
      } else if (!(await Permission.storage.request().isGranted)) {
        loggy.warning('Storage permission denied.');
      } else {
        // Start recording
        final tempDir = await getTemporaryDirectory();
        _recordedFilePath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
        await _audioRecorder.start(
          const RecordConfig(),
          path: _recordedFilePath,
        );
        loggy.info('Recording started.');
      }
    } catch (e) {
      loggy.error('Error starting recording: $e');
    }
  }

  Future<void> stopRecording({required String id}) async {
    loggy.info('Stopping recording...');
    try {
      if (await _audioRecorder.isRecording()) {
        loggy.info('Stopping audio recording...');
        await _audioRecorder.stop();
        loggy.info('Audio recording stopped.');
      }
      isFinished = true;

      loggy.info('Saving audio message $id .. $_recordedFilePath');
      final file = File(_recordedFilePath);
      final sizeInBytes = file.lengthSync();

      Duration? duration;
      try {
        await _audioPlayer.play(DeviceFileSource(
          _recordedFilePath,
          mimeType: 'audio/aac',
        ));
        duration = await _audioPlayer.getDuration();
      } catch (e) {
        loggy.error('Error loading or getting duration: $e');
        duration = Duration.zero;
      }

      loggy.info('duration: $duration');
      final audioMessage = AudioMessage(
        id: id,
        filePath: _recordedFilePath,
        duration: duration ?? Duration.zero,
        size: sizeInBytes,
      );
      loggy
        ..info('duration: $duration')
        ..info('Audio message created: $audioMessage');
      try {
        await _hiveRepository.saveAudioMessage(audioMessage: audioMessage);
        loggy.info('Audio message saved successfully.');
      } catch (e) {
        loggy.error('Error saving audio message: $e');
      }
    } catch (e) {
      loggy.error('Error stopping recording: $e');
    }
  }

  Future<void> playAudio() async {
    loggy.info('Playing audio...');
    try {
      await _audioPlayer.play(DeviceFileSource(
        _recordedFilePath,
        mimeType: 'audio/aac',
      ));
    } catch (e) {
      loggy.error('Error playing audio: $e');
    }
  }

  Future<void> deleteAudio({required String id}) async {
    loggy.info('Deleting audio message with ID: $id');
    try {
      await _hiveRepository.deleteAudioMessage(id: id);
      loggy.info('Audio message deleted successfully.');
    } catch (e) {
      loggy.error('Error deleting audio message: $e');
    }
  }

  Future<AudioMessage> getAudio({required String id}) async {
    loggy.info('Getting audio message with ID: $id');
    try {
      final AudioMessage audioMessage =
          await _hiveRepository.getAudioMessage(id: id);
      loggy.info('Audio message retrieved successfully.');
      return audioMessage;
    } catch (e) {
      loggy.error('Error retrieving audio message: $e');
      rethrow;
    }
  }
}
