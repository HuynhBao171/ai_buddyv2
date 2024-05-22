import 'package:hive/hive.dart';

part 'audio_message.g.dart';

@HiveType(typeId: 1)
class AudioMessage extends HiveObject {
  AudioMessage({
    required this.id,
    required this.filePath,
  });
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? filePath;
}
