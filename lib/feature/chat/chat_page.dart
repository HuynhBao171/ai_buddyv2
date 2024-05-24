import 'dart:io';

import 'package:ai_buddy/core/config/assets_constants.dart';
import 'package:ai_buddy/core/config/type_of_bot.dart';
import 'package:ai_buddy/core/config/type_of_message_user.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:ai_buddy/core/services/camera_service.dart';
import 'package:ai_buddy/core/services/recording_service.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/chat/widgets/audio_interface_widget.dart';
import 'package:ai_buddy/feature/chat/widgets/audio_interface_widget_v2.dart';
import 'package:ai_buddy/feature/chat/widgets/chat_interface_widget.dart';
import 'package:ai_buddy/feature/hive/model/audio_message/audio_message.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:ai_buddy/feature/home/provider/chat_bot_provider.dart';
import 'package:ai_buddy/feature/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final cameraServiceProviver = Provider<CameraService>((ref) => CameraService());

final recordingServiceProviver =
    Provider<RecordingService>((ref) => RecordingService());

class ChatPage extends ConsumerWidget with UiLoggy {
  const ChatPage({super.key});

  Future<List<types.Message>> _buildMessages(
      ChatBot chatBot, RecordingService recordingService) async {
    return (await Future.wait(chatBot.messagesList.map((msg) async {
      final typeOfMessage = msg['typeOfMessage'] as String;
      if (msg['typeOfMessageUser'] == TypeOfMessageUser.imageAndAudio) {
        //  loggy.info('Image and Audio');
        // final imagePath = msg['imagePath'] as String;
        // final file = File(imagePath);
        // final sizeInBytes = file.lengthSync();
        // return types.ImageMessage(
        // author: types.User(id: typeOfMessage),
        // createdAt: DateTime.parse(msg['createdAt'] as String)
        //     .millisecondsSinceEpoch,
        // id: msg['id'] as String,
        // name: '',
        // size: sizeInBytes,
        // uri: msg['imagePath'] as String,
        // );
        final audioId = msg['audioId'] as String;
        final AudioMessage audioMessage =
            await recordingService.getAudio(id: audioId);
        return types.AudioMessage(
          author: types.User(id: typeOfMessage),
          createdAt:
              DateTime.parse(msg['createdAt'] as String).millisecondsSinceEpoch,
          id: msg['id'] as String,
          name: '',
          size: audioMessage.size,
          uri: msg['audioPath'] as String,
          duration: audioMessage.duration,
        );
      }
      return types.TextMessage(
        author: types.User(id: typeOfMessage),
        createdAt:
            DateTime.parse(msg['createdAt'] as String).millisecondsSinceEpoch,
        id: msg['id'] as String,
        text: msg['text'] as String,
      );
    }).toList()))
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingService = ref.watch(recordingServiceProviver);

    final cameraService = ref.watch(cameraServiceProviver);

    final chatBot = ref.watch(messageListProvider);
    final color = chatBot.typeOfBot == TypeOfBot.pdf
        ? context.colorScheme.primary
        : chatBot.typeOfBot == TypeOfBot.text
            ? context.colorScheme.secondary
            : chatBot.typeOfBot == TypeOfBot.image
                ? context.colorScheme.tertiary
                : const Color(0xFFF5A11A);
    final imagePath = chatBot.typeOfBot == TypeOfBot.pdf
        ? AssetConstants.pdfLogo
        : chatBot.typeOfBot == TypeOfBot.image
            ? AssetConstants.imageLogo
            : chatBot.typeOfBot == TypeOfBot.text
                ? AssetConstants.textLogo
                : AssetConstants.audioLogo;
    final title = chatBot.typeOfBot == TypeOfBot.pdf
        ? 'PDF'
        : chatBot.typeOfBot == TypeOfBot.image
            ? 'Image'
            : chatBot.typeOfBot == TypeOfBot.text
                ? 'Text'
                : 'Audio';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: -300,
                top: -00,
                child: Container(
                  height: 500,
                  width: 600,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.5),
                        context.colorScheme.surface.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              CustomPaint(
                painter: BackgroundCurvesPainter(),
                size: Size.infinite,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: context.colorScheme.onSurface,
                          ),
                          onPressed: () {
                            ref
                                .read(chatBotListProvider.notifier)
                                .updateChatBotOnHomeScreen(chatBot);
                            context.pop();
                          },
                        ),
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          width: 120,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$title Buddy',
                              style: TextStyle(
                                color: context.colorScheme.surface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (chatBot.typeOfBot == TypeOfBot.image)
                          CircleAvatar(
                            maxRadius: 21,
                            backgroundImage: FileImage(
                              File(chatBot.attachmentPath!),
                            ),
                            child: TextButton(
                              onPressed: () {
                                showDialog<AlertDialog>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: SingleChildScrollView(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.file(
                                            File(chatBot.attachmentPath!),
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
                              },
                              child: const SizedBox.shrink(),
                            ),
                          )
                        else
                          const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    if (chatBot.typeOfBot == TypeOfBot.audio)
                      Expanded(
                        child: FutureBuilder<List<types.Message>>(
                          future: _buildMessages(chatBot,
                              recordingService), // Chờ Future hoàn thành
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return AudioInterfaceWidgetV2(
                                messages: snapshot.data!,
                                chatBot: chatBot,
                                color: color,
                                imagePath: imagePath,
                                recordingService: recordingService,
                                cameraService: cameraService,
                              );
                            } else if (snapshot.hasError) {
                              // Xử lý lỗi
                              return const Text('Error loading messages');
                            } else {
                              // Hiển thị progress indicator
                              return const CircularProgressIndicator();
                            }
                          },
                        ),
                      ),
                    // Expanded(
                    //   child: FutureBuilder<List<types.Message>>(
                    //     future: _buildMessages(
                    //         chatBot, listeningService), // Chờ Future hoàn thành
                    //     builder: (context, snapshot) {
                    //       if (snapshot.hasData) {
                    //         return ChatInterfaceWidget(
                    //           messages: snapshot.data!,
                    //           chatBot: chatBot,
                    //           color: color,
                    //           imagePath: imagePath,
                    //         );
                    //       } else if (snapshot.hasError) {
                    //         // Xử lý lỗi
                    //         return const Text('Error loading messages');
                    //       } else {
                    //         // Hiển thị progress indicator
                    //         return const CircularProgressIndicator();
                    //       }
                    //     },
                    //   ),
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// List<types.Message> _buildMessages(ChatBot chatBot, ListeningService listeningService)  {
//   return chatBot.messagesList
//       .map((msg) {
//         final typeOfMessage = msg['typeOfMessage'] as String;
//         if (msg['typeOfMessageUser'] == TypeOfMessageUser.imageAndAudio) {
//         //  loggy.info('Image and Audio');
//             // final imagePath = msg['imagePath'] as String;
//             // final file = File(imagePath);
//             // final sizeInBytes = file.lengthSync();
//             // return types.ImageMessage(
//             // author: types.User(id: typeOfMessage),
//             // createdAt: DateTime.parse(msg['createdAt'] as String)
//             //     .millisecondsSinceEpoch,
//             // id: msg['id'] as String,
//             // name: '',
//             // size: sizeInBytes,
//             // uri: msg['imagePath'] as String,
//             // );
//             final audioId = msg['audioId'] as String;
//             final AudioMessage audioMessage = await
//                 listeningService.getAudio(id: audioId);
//             return types.AudioMessage(
//               author: types.User(id: typeOfMessage),
//               createdAt: DateTime.parse(msg['createdAt'] as String)
//                   .millisecondsSinceEpoch,
//               id: msg['id'] as String,
//               name: '',
//               size: audioMessage.size,
//               uri: msg['audioPath'] as String,
//               duration: audioMessage.duration,
//             );
//         }
//         return types.TextMessage(
//           author: types.User(id: typeOfMessage),
//           createdAt:
//               DateTime.parse(msg['createdAt'] as String).millisecondsSinceEpoch,
//           id: msg['id'] as String,
//           text: msg['text'] as String,
//         );
//       })
//       .where((element) => element != null)
//       .toList()
//     ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
// }
