import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/call_session.dart';
import '../controllers/call_controller.dart';

/// Shows the current call (dial-out, connecting, or active). Pop it
/// when [CallController]'s state clears or the call ends.
///
/// Honest about a real limitation: speaker/video/mute are visual
/// only. There is no audio or video engine in this build — see the
/// doc comment on [CallController]. Rather than hide that, the
/// active-call state says so plainly, matching this app's "truth
/// over comfort" design principle for connection state.
class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CallSession? call = ref.watch(callControllerProvider);

    if (call == null) {
      // State cleared elsewhere (e.g. after tapping Close) — leave.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final bool ended = call.phase == CallPhase.ended || call.phase == CallPhase.failed;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              AppAvatar(name: call.peerName, size: 96),
              const SizedBox(height: AppSpacing.md),
              Text(call.peerName, style: theme.textTheme.headlineSmall),
              if (call.phase == CallPhase.active) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'End-to-end encrypted',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                call.statusMessage ?? _phaseLabel(call.phase),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: call.phase == CallPhase.failed
                      ? AppColors.danger
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (call.phase == CallPhase.active) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Speaker',
                      onTap: () {}, // visual only — no audio engine
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _RoundIconButton(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      onTap: () {}, // visual only — no video engine
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _RoundIconButton(
                      icon: Icons.mic_off_rounded,
                      label: 'Mute',
                      onTap: () {}, // visual only — no audio engine
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppButton(
                label: ended ? 'Close' : 'End call',
                variant: AppButtonVariant.danger,
                pill: true,
                onPressed: () {
                  if (ended) {
                    ref.read(callControllerProvider.notifier).clear();
                  } else {
                    ref.read(callControllerProvider.notifier).hangUp();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseLabel(CallPhase phase) => switch (phase) {
        CallPhase.dialing => 'Calling…',
        CallPhase.ringingIncoming => 'Incoming call',
        CallPhase.connecting => 'Connecting…',
        CallPhase.active => 'Connected',
        CallPhase.ended => 'Call ended',
        CallPhase.failed => 'Call failed',
      };
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
