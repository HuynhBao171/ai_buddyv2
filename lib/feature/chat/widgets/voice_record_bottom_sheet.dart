import 'dart:async';

import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/extension/widget.dart';
import 'package:ai_buddy/core/services/listening_service.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class VoiceRecordBottomSheet extends StatefulWidget {
  const VoiceRecordBottomSheet({
    required this.listeningService,
    required this.color,
    required this.audioId,
    required this.onDone,
    super.key,
  });

  final ListeningService listeningService;
  final Color color;
  final String audioId;
  final void Function(String recognizedText) onDone;

  @override
  State<VoiceRecordBottomSheet> createState() => _VoiceRecordBottomSheetState();
}

class _VoiceRecordBottomSheetState extends State<VoiceRecordBottomSheet> {
  bool isListening = false;
  String recognizedText = '';
  int _millSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 50,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 8),
            ).paddingBottom(16),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  child: isListening
                      ? Column(
                          children: [
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: const Color.fromARGB(255, 74, 74, 254),
                              size: 60,
                            ).paddingBottom(10),
                            Text(
                                '${(_millSeconds / 1000.0).toStringAsFixed(1)} s'),
                          ],
                        )
                      : const SizedBox(),
                ).paddingBottom(30),
                GestureDetector(
                  onLongPressStart: (details) {
                    setState(() {
                      isListening = true;
                      _millSeconds = 0;
                      widget.listeningService.startListening();
                    });

                    // Start the timer
                    _timer = Timer.periodic(const Duration(milliseconds: 100),
                        (timer) {
                      setState(() {
                        _millSeconds += 100;
                      });
                    });
                  },
                  onLongPressEnd: (details) async {
                    setState(() {
                      isListening = false;
                      _timer?.cancel();
                    });

                    recognizedText =
                        await widget.listeningService.stopListening(
                      id: widget.audioId,
                    );

                    // Gọi callback onDone với recognizedText
                    widget.onDone(recognizedText);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 500));
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? widget.color.withOpacity(0.9)
                          : widget.color.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: context.colorScheme.surface,
                        size: 40,
                      ),
                    ),
                  ),
                ).paddingBottom(10),
                Text(
                  'Hold to record',
                  style: context.textTheme.bodyLarge!.copyWith(
                    fontSize: 18,
                  ),
                ),
              ],
            ).paddingBottom(16),
          ],
        ),
      ),
    );
  }
}
