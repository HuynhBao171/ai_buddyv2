import 'dart:async';
import 'dart:io';

import 'package:ai_buddy/core/config/type_of_message.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/extension/widget.dart';
import 'package:ai_buddy/core/services/camera_service.dart';
import 'package:ai_buddy/core/services/recording_service.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/chat/widgets/voice_record_bottom_sheet.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:uuid/uuid.dart';

class AudioInterfaceWidgetV2 extends ConsumerStatefulWidget with UiLoggy {
  const AudioInterfaceWidgetV2({
    required this.messages,
    required this.chatBot,
    required this.color,
    required this.imagePath,
    required this.recordingService,
    required this.cameraService,
    super.key,
  });

  final List<types.Message> messages;
  final ChatBot chatBot;
  final Color color;
  final String imagePath;
  final RecordingService recordingService;
  final CameraService cameraService;

  @override
  ConsumerState<AudioInterfaceWidgetV2> createState() =>
      _AudioInterfaceWidgetV2State();
}

class _AudioInterfaceWidgetV2State
    extends ConsumerState<AudioInterfaceWidgetV2> {
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
                          widget.loggy
                              .info('Delete button pressed - ID: $audioId');

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
                          widget.loggy
                              .info('Replay button pressed - ID: $audioId');
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
                        widget.loggy.info('Images captured: $imagePath');
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
                          ),
                        ),
                      ),
                    ]);

                    widget.loggy.info('Listen button pressed - ID: $audioId');
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          File(imagePath!),
                                        ),
                                      ),
                                    ),
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
                          widget.loggy
                              .info('Send button pressed - $recognizedText');

                          if (isDone) {
                            ref
                                .watch(messageListProvider.notifier)
                                .handleSendPressed(
                                  text: 'đây là gì ?',
                                  imageFilePath: imagePath,
                                  audioId: audioId,
                                );
                            setState(() {
                              isDone = false;
                            });
                          } else {
                            widget.loggy.warning(
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
            user: const types.User(id: TypeOfMessage.user),
            showUserAvatars: true,
            avatarBuilder: (user) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: widget.color,
                radius: 19,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    widget.imagePath,
                    color: context.colorScheme.surface,
                  ),
                ),
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
