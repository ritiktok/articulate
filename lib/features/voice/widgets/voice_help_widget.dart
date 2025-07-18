import 'package:flutter/material.dart';

class VoiceHelpDialog extends StatelessWidget {
  const VoiceHelpDialog({super.key});

  String getQuickStartGuide() {
    return '''
Quick Start Guide:

1. Tap the microphone button to start voice control
2. Speak your command clearly
3. The app will process your command and provide feedback
4. Try these commands:
   • "Switch to red brush"
   • "Draw a circle"
   • "Make stroke thicker"
   • "Suggest something"
   • "Undo"
''';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Voice Commands',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getQuickStartGuide(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Try these commands:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'Switch to red brush',
                      'Draw a circle',
                      'Make stroke thicker',
                      'Suggest something',
                      'Undo',
                    ].map(
                      (cmd) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $cmd'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
