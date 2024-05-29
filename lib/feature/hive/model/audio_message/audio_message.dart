import 'package:hive/hive.dart';

part 'audio_message.g.dart';

@HiveType(typeId: 1)
class AudioMessage extends HiveObject {
  AudioMessage({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.size,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final Duration duration; 

  @HiveField(3)
  final int size; 
}
