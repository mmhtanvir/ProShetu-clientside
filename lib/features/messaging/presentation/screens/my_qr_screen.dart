import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/messaging_providers.dart';

/// This device's own pairing code: a QR encoding {displayName,
/// mailboxId} — the exact shape [ScanQrScreen] decodes and hands to
/// ContactDirectoryStore.add(). Scanning this is how a peer learns
/// this device's mailbox_id without either side ever sharing a phone
/// number (apps/directory deliberately never links the two).
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<({String? name, String? mailboxId})> infoAsync =
        ref.watch(myPairingInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My pairing code')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: infoAsync.when(
                loading: () => const AppLoading(),
                error: (Object error, StackTrace __) => AppStatusView.error(
                  title: "Couldn't load your pairing code",
                  message: error.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(myPairingInfoProvider),
                ),
                data: (({String? name, String? mailboxId}) info) {
                  if (info.mailboxId == null) {
                    return const AppStatusView.error(
                      title: 'Not registered yet',
                      message:
                          "This device hasn't finished registering with the "
                          'server — sign up (or sign back in) before sharing '
                          'a pairing code.',
                    );
                  }
                  final String payload = jsonEncode(<String, String>{
                    'displayName': info.name ?? 'Unknown',
                    'mailboxId': info.mailboxId!,
                  });
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Let a contact scan this to pair with you',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: QrImageView(
                          data: payload,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(info.name ?? '', style: theme.textTheme.titleMedium),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
