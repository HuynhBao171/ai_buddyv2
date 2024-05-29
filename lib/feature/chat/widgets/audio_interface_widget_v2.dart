import 'dart:async';
import 'dart:io';

import 'package:ai_buddy/core/config/type_of_message.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/extension/widget.dart';
import 'package:ai_buddy/core/services/camera_service.dart';
import 'package:ai_buddy/core/services/deepgram_service.dart';
import 'package:ai_buddy/core/services/recording_service.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/chat/widgets/voice_record_bottom_sheet.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:ai_buddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:voice_message_package/voice_message_package.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:uuid/uuid.dart';

class AudioInterfaceWidgetV2 extends ConsumerStatefulWidget {
  const AudioInterfaceWidgetV2({
    required this.messages,
    required this.chatBot,
    required this.color,
    required this.imagePath,
    required this.recordingService,
    required this.cameraService,
    required this.deepgramService,
    super.key,
  });

  final List<types.Message> messages;
  final ChatBot chatBot;
  final Color color;
  final String imagePath;
  final RecordingService recordingService;
  final CameraService cameraService;
  final DeepgramService deepgramService;

  @override
  ConsumerState<AudioInterfaceWidgetV2> createState() =>
      _AudioInterfaceWidgetV2State();
}

class _AudioInterfaceWidgetV2State extends ConsumerState<AudioInterfaceWidgetV2>
    with UiLoggy {
  final uuid = const Uuid();
  String recognizedText = '';
  String? audioId;
  String? imagePath;
  List<String?> imagePaths = [];
  bool isDone = false;

  @override
  void initState() {
    super.initState();
    widget.cameraService.initialize();
  }

  @override
  void dispose() {
    widget.cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Chat(
            customBottomWidget: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: !isDone
                      ? null
                      : () async {
                          loggy.info('Delete button pressed - ID: $audioId');

                          await widget.recordingService
                              .deleteAudio(id: audioId!);
                          setState(() {
                            audioId = null;
                            isDone = false;
                            recognizedText = '';
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: Icon(
                    Icons.delete,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
                IconButton(
                  onPressed: !isDone
                      ? null
                      : () async {
                          loggy.info('Replay button pressed - ID: $audioId');
                          await widget.recordingService.playAudio();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: Icon(
                    Icons.replay,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      audioId = uuid.v4();
                      imagePath = '';
                    });
                    await Future.wait([
                      widget.cameraService.takePicture().then((paths) {
                        setState(() {
                          imagePath = paths;
                        });
                        loggy.info('Images captured: $imagePath');
                      }),
                      showModalBottomSheet<void>(
                        backgroundColor: context.colorScheme.onBackground,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 10,
                          ),
                          child: VoiceRecordBottomSheet(
                            recordingService: widget.recordingService,
                            color: widget.color,
                            audioId: audioId!,
                            onDone: (recText) {
                              setState(() {
                                isDone = true;
                                recognizedText = recText;
                              });
                            },
                            deepgramService: widget.deepgramService,
                          ),
                        ),
                      ),
                    ]);

                    loggy.info('Listen button pressed - ID: $audioId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color.withOpacity(0.9),
                    minimumSize: const Size(80, 80),
                  ),
                  icon: Icon(
                    size: 40,
                    Icons.mic,
                    color: context.colorScheme.surface,
                  ),
                ),
                IconButton(
                  onPressed: !isDone
                      ? null
                      : () {
                          if (imagePath != null) {
                            showDialog<AlertDialog>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: SingleChildScrollView(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(imagePath!),
                                      ),
                                    ).paddingAll(8),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Close'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: Icon(
                    Icons.image,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
                IconButton(
                  onPressed: !isDone
                      ? null
                      : () {
                          loggy.info('Send button pressed - $recognizedText');

                          if (isDone) {
                            // Kiểm tra audioId
                            if (audioId != null) {
                              // Chuyển đổi audio thành text
                              ref
                                  .watch(deepgramServiceProviver)
                                  .convertAudioToText(audioId!)
                                  .then((audioText) {
                                ref
                                    .watch(messageListProvider.notifier)
                                    .handleSendPressed(
                                      text:
                                          liveTranscriptionStream.stream.value,
                                      imageFilePath: imagePath,
                                      audioId: audioId,
                                    );
                              });
                            } else {
                              // Gửi text hoặc text với image
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No audio to send.'),
                                ),
                              );
                            }
                            setState(() {
                              isDone = false;
                            });
                          } else {
                            loggy.warning(
                              'Record is not finished yet.',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You need to press "Done" before pressing "Send"',
                                ),
                              ),
                            );
                          }
                          setState(() {
                            isDone = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: Icon(
                    Icons.send,
                    color: context.colorScheme.outlineVariant,
                  ).paddingLeft(4),
                ),
              ],
            ).paddingBottom(8),
            messages: widget.messages,
            audioMessageBuilder: (audioMessage, {required messageWidth}) {
              final isMine = audioMessage.author.id == TypeOfMessage.user;
              return VoiceMessageView(
                backgroundColor:
                    isMine ? widget.color : context.colorScheme.onSurface,
                controller: VoiceController(
                  audioSrc: audioMessage.uri,
                  maxDuration: audioMessage.duration,
                  onComplete: () {
                    // Logic khi audio phát xong
                    loggy.info('Audio message playback completed.');
                  },
                  onPause: () {
                    // Logic khi audio bị tạm dừng
                    loggy.info('Audio message playback paused.');
                  },
                  onPlaying: () {
                    // Logic khi audio đang phát
                    loggy.info('Audio message playback started.');
                  },
                  isFile: true,
                ),
              );
            },
            user: const types.User(id: TypeOfMessage.user),
            showUserAvatars: true,
            avatarBuilder: (user) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: widget.color,
                radius: 19,
                child: Image.asset(
                  widget.imagePath,
                  color: context.colorScheme.surface,
                ).paddingAll(8),
              ),
            ),
            // Các tùy chỉnh giao diện khác của Chat widget
            theme: DefaultChatTheme(
              backgroundColor: Colors.transparent,
              primaryColor: context.colorScheme.onSurface,
              secondaryColor: widget.color,
              receivedMessageBodyTextStyle: TextStyle(
                color: context.colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              sentMessageBodyTextStyle: TextStyle(
                color: context.colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              dateDividerTextStyle: TextStyle(
                color: context.colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.333,
              ),
            ),
            onSendPressed: (PartialText) {},
            // Loại bỏ inputBuilder
          ),
        ),
      ],
    );
  }
}
