import 'dart:io';

import 'package:ai_buddy/core/config/type_of_message.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/extension/widget.dart';
import 'package:ai_buddy/core/services/camera_service.dart';
import 'package:ai_buddy/core/services/listening_service.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:uuid/uuid.dart';

class AudioInterfaceWidget extends ConsumerStatefulWidget with UiLoggy {
  const AudioInterfaceWidget({
    required this.messages,
    required this.chatBot,
    required this.color,
    required this.imagePath,
    required this.listeningService,
    required this.cameraService,
    super.key,
  });

  final List<types.Message> messages;
  final ChatBot chatBot;
  final Color color;
  final String imagePath;
  final ListeningService listeningService;
  final CameraService cameraService;

  @override
  ConsumerState<AudioInterfaceWidget> createState() =>
      _AudioInterfaceWidgetState();
}

class _AudioInterfaceWidgetState extends ConsumerState<AudioInterfaceWidget> {
  final uuid = const Uuid();
  String recognizedText = '';
  String? audioId;
  List<String?> imagePaths = [];
  bool isListening = false;
  bool isDone = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Chat(
            customBottomWidget: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isListening
                      ? null
                      : () async {
                          setState(() {
                            audioId = uuid.v4();
                            isListening = true;
                            imagePaths = [];
                          });
                          imagePaths.addAll(await widget.cameraService
                              .takeMultiplePictures());
                          widget.loggy.info('Image captured: ${imagePaths[1]}');

                          widget.loggy
                              .info('Listen button pressed - ID: $audioId');
                          await widget.listeningService.initSpeech();
                          await widget.listeningService.startListening();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color.withOpacity(0.9),
                    minimumSize: const Size(80, 50),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: context.colorScheme.surface,
                  ),
                ),
                ElevatedButton(
                  onPressed: !isListening
                      ? null
                      : () async {
                          setState(() {
                            isListening = false;
                            isDone = true;
                          });
                          widget.loggy
                              .info('Done button pressed - ID: $audioId');
                          recognizedText =
                              await widget.listeningService.stopListening(
                            id: audioId!,
                          );
                          widget.loggy.info('Recognized text: $recognizedText');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color.withOpacity(0.9),
                    minimumSize: const Size(80, 50),
                  ),
                  child: Icon(
                    Icons.done,
                    color: context.colorScheme.surface,
                  ),
                ),
                ElevatedButton(
                  onPressed: !isDone
                      ? null
                      : () async {
                          widget.loggy
                              .info('Play back button pressed - ID: $audioId');
                          await widget.listeningService.playAudio();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color.withOpacity(0.9),
                    minimumSize: const Size(80, 50),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: context.colorScheme.surface,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (imagePaths.isNotEmpty) {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: SingleChildScrollView(
                              child: Column(
                                children: imagePaths
                                    .map(
                                      (imagePath) => imagePath != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.file(
                                                  File(imagePath),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    )
                                    .toList(),
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
                          widget.loggy.info('Send button pressed');
                          if (widget.listeningService.isFinished) {
                            ref
                                .watch(messageListProvider.notifier)
                                .handleSendPressed(
                                  text:
                                      widget.listeningService.recognizedText ??
                                          '',
                                );
                            setState(() {
                              isDone = false;
                            });
                          } else {
                            widget.loggy.warning(
                              'Speech recognition is not finished yet.',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You need to press "Done" before pressing "Send"',
                                ),
                              ),
                            );
                          }
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
