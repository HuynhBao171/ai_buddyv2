// ignore_for_file: use_build_context_synchronously

import 'package:ai_buddy/core/config/assets_constants.dart';
import 'package:ai_buddy/core/config/type_of_bot.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/extension/widget.dart';
import 'package:ai_buddy/core/navigation/route.dart';
import 'package:ai_buddy/core/util/secure_storage.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:ai_buddy/feature/home/provider/chat_bot_provider.dart';
import 'package:ai_buddy/feature/home/widgets/widgets.dart';
import 'package:ai_buddy/feature/welcome/widgets/api_key_bottom_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:uuid/uuid.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final uuid = const Uuid();

  bool _isBuildingChatBot = false;
  String currentState = '';

  @override
  void initState() {
    super.initState();
    ref.read(chatBotListProvider.notifier).fetchChatBots();
  }

  Widget _buildLoadingIndicator(String currentState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitDoubleBounce(
            color: context.colorScheme.onSurface,
          ).paddingBottom(8),
          Text(currentState, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showAllHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final chatBotsList = ref.watch(chatBotListProvider);
            return Column(
              children: [
                Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      itemCount: chatBotsList.length,
                      itemBuilder: (context, index) {
                        final chatBot = chatBotsList[index];
                        final imagePath = chatBot.typeOfBot == TypeOfBot.pdf
                            ? AssetConstants.pdfLogo
                            : chatBot.typeOfBot == TypeOfBot.image
                                ? AssetConstants.imageLogo
                                : chatBot.typeOfBot == TypeOfBot.text
                                    ? AssetConstants.textLogo
                                    : AssetConstants.audioLogo;
                        final tileColor = chatBot.typeOfBot == TypeOfBot.pdf
                            ? context.colorScheme.primary
                            : chatBot.typeOfBot == TypeOfBot.text
                                ? context.colorScheme.secondary
                                : chatBot.typeOfBot == TypeOfBot.image
                                    ? context.colorScheme.tertiary
                                    : const Color(0xFFF5A11A);
                        return HistoryItem(
                          imagePath: imagePath,
                          label: chatBot.title,
                          color: tileColor,
                          chatBot: chatBot,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBotsList = ref.watch(chatBotListProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isBuildingChatBot
          ? _buildLoadingIndicator(currentState)
          : SafeArea(
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
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(
                              width: 60,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.25),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Personal AI Buddy',
                                    style: TextStyle(
                                      color: context.colorScheme.surface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ).paddingRight(4),
                                  Image.asset(
                                    AssetConstants.aiStarLogo,
                                    scale: 23,
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              maxRadius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(
                                  CupertinoIcons.settings,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () async {
                                  final apiKey =
                                      await SecureStorage().getApiKey();
                                  final TextEditingController apiKeyController =
                                      TextEditingController(text: apiKey);
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) {
                                      return APIKeyBottomSheet(
                                        apiKeyController: apiKeyController,
                                        isCalledFromHomePage: true,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'How may I help\nyou today?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(fontSize: 32),
                            ),
                          ),
                        ).paddingBottom(32),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CardButton(
                                    title: 'Talk with AI',
                                    color: const Color(0xFFF5A11A),
                                    imagePath: AssetConstants.audioLogo,
                                    isMainButton: true,
                                    onPressed: () {
                                      final chatBot = ChatBot(
                                        messagesList: [],
                                        id: uuid.v4(),
                                        title: '',
                                        typeOfBot: TypeOfBot.audio,
                                      );
                                      ref
                                          .read(chatBotListProvider.notifier)
                                          .saveChatBot(chatBot);
                                      ref
                                          .read(messageListProvider.notifier)
                                          .updateChatBot(chatBot);
                                      AppRoute.chat.push(context);
                                    },
                                  ).paddingBottom(8),
                                  CardButton(
                                    title: 'Chat with PDF',
                                    color: context.colorScheme.primary,
                                    imagePath: AssetConstants.pdfLogo,
                                    isMainButton: false,
                                    onPressed: () async {
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf'],
                                      );
                                      if (result != null) {
                                        final filePath =
                                            result.files.single.path;
                                        setState(() {
                                          _isBuildingChatBot = true;
                                          currentState = 'Extracting data';
                                        });

                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 100),
                                        );

                                        final textChunks = await ref
                                            .read(chatBotListProvider.notifier)
                                            .getChunksFromPDF(filePath!);

                                        setState(() {
                                          currentState = 'Building chatBot';
                                        });

                                        final embeddingsMap = await ref
                                            .read(chatBotListProvider.notifier)
                                            .batchEmbedChunks(textChunks);

                                        final chatBot = ChatBot(
                                          messagesList: [],
                                          id: uuid.v4(),
                                          title: '',
                                          typeOfBot: TypeOfBot.pdf,
                                          attachmentPath: filePath,
                                          embeddings: embeddingsMap,
                                        );

                                        await ref
                                            .read(chatBotListProvider.notifier)
                                            .saveChatBot(chatBot);
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .updateChatBot(chatBot);

                                        AppRoute.chat.push(context);
                                        setState(() {
                                          _isBuildingChatBot = false;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ).paddingRight(8),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CardButton(
                                    title: 'Chat with AI',
                                    color: context.colorScheme.secondary,
                                    imagePath: AssetConstants.textLogo,
                                    isMainButton: false,
                                    onPressed: () {
                                      final chatBot = ChatBot(
                                        messagesList: [],
                                        id: uuid.v4(),
                                        title: '',
                                        typeOfBot: TypeOfBot.text,
                                      );
                                      ref
                                          .read(chatBotListProvider.notifier)
                                          .saveChatBot(chatBot);
                                      ref
                                          .read(messageListProvider.notifier)
                                          .updateChatBot(chatBot);
                                      AppRoute.chat.push(context);
                                    },
                                  ).paddingBottom(8),
                                  CardButton(
                                    title: 'Ask Image',
                                    color: context.colorScheme.tertiary,
                                    imagePath: AssetConstants.imageLogo,
                                    isMainButton: true,
                                    onPressed: () async {
                                      final pickedFile = await ref
                                          .read(chatBotListProvider.notifier)
                                          .attachImageFilePath();
                                      if (pickedFile != null) {
                                        final chatBot = ChatBot(
                                          messagesList: [],
                                          id: uuid.v4(),
                                          title: '',
                                          typeOfBot: TypeOfBot.image,
                                          attachmentPath: pickedFile,
                                        );
                                        await ref
                                            .read(chatBotListProvider.notifier)
                                            .saveChatBot(chatBot);
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .updateChatBot(chatBot);
                                        AppRoute.chat.push(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).paddingBottom(32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'History',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.95),
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showAllHistory(context),
                                    child: Text(
                                      'See all',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ).paddingBottom(16),
                            if (chatBotsList.isEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No chats yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.95),
                                        ),
                                  ).paddingRight(23),
                                  const Icon(CupertinoIcons.cube_box),
                                ],
                              ).paddingTop(56)
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: chatBotsList.length > 3
                                    ? 3
                                    : chatBotsList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final chatBot = chatBotsList[index];
                                  final imagePath = chatBot.typeOfBot ==
                                          TypeOfBot.pdf
                                      ? AssetConstants.pdfLogo
                                      : chatBot.typeOfBot == TypeOfBot.image
                                          ? AssetConstants.imageLogo
                                          : chatBot.typeOfBot == TypeOfBot.text
                                              ? AssetConstants.textLogo
                                              : AssetConstants.audioLogo;
                                  final tileColor = chatBot.typeOfBot ==
                                          TypeOfBot.pdf
                                      ? context.colorScheme.primary
                                      : chatBot.typeOfBot == TypeOfBot.text
                                          ? context.colorScheme.secondary
                                          : chatBot.typeOfBot == TypeOfBot.image
                                              ? context.colorScheme.tertiary
                                              : const Color(0xFFF5A11A);
                                  return HistoryItem(
                                    label: chatBot.title,
                                    imagePath: imagePath,
                                    color: tileColor,
                                    chatBot: chatBot,
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
