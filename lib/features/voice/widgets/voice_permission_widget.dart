import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../cubit/voice_cubit.dart';
import '../cubit/voice_state.dart';

class VoicePermissionWidget extends StatefulWidget {
  const VoicePermissionWidget({super.key});

  @override
  State<VoicePermissionWidget> createState() => _VoicePermissionWidgetState();
}

class _VoicePermissionWidgetState extends State<VoicePermissionWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceCubit, VoiceState>(
      builder: (context, state) {
        if (state.hasPermission || !state.showPermissionOverlay) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mic, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Microphone Permission Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<VoiceCubit>().hidePermissionOverlay();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ??
                    'Voice commands require microphone access to work properly.',
                style: TextStyle(color: Colors.grey.shade700),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final voiceCubit = context.read<VoiceCubit>();
                        final status = await Permission.microphone.status;
                        if (status.isPermanentlyDenied) {
                          await AppSettings.openAppSettings();
                          await Future.delayed(const Duration(seconds: 1));
                          await voiceCubit.refreshPermissionStatus();
                        } else {
                          await voiceCubit.requestPermissions();
                        }
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Grant Permission'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await AppSettings.openAppSettings();
                    },
                    icon: const Icon(Icons.settings_applications),
                    tooltip: 'Open Settings',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
