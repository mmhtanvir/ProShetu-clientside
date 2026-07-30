import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/identity_doc_type.dart';
import '../controllers/identity_controller.dart';

/// Document capture with per-photo review.
///
/// One preview slot per required photo (NID: front + back; birth
/// certificate: one). Tapping a slot opens the native camera via
/// image_picker (lighter on RAM/battery than an embedded preview on
/// low-end devices); tapping a filled slot re-shoots it. Continue
/// appears only when every slot is filled, so the user reviews
/// everything before upload.
class IdentityCaptureScreen extends ConsumerWidget {
  const IdentityCaptureScreen({super.key});

  Future<void> _captureSlot(WidgetRef ref, int slot) async {
    final XFile? shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1800,
    );
    if (shot == null) return;
    ref.read(identityControllerProvider.notifier).setImage(slot, shot.path);
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final bool ok =
        await ref.read(identityControllerProvider.notifier).submit();
    if (ok && context.mounted) context.goNamed(AppRoutes.identitySuccess);
  }

  String _slotLabel(AppLocalizations l10n, IdentityDocType type, int slot) {
    if (type == IdentityDocType.birthCertificate) {
      return l10n.authCaptureDocumentLabel;
    }
    return slot == 0
        ? l10n.authCaptureFrontLabel
        : l10n.authCaptureBackLabel;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final IdentityState state = ref.watch(identityControllerProvider);
    final IdentityDocType type =
        state.docType ?? IdentityDocType.birthCertificate;

    final String title = switch (type) {
      IdentityDocType.nid => l10n.authNidOption,
      IdentityDocType.birthCertificate => l10n.authBirthCertOption,
    };
    final String caption = switch (type) {
      IdentityDocType.birthCertificate => l10n.authCaptureBirthCert,
      IdentityDocType.nid => (state.images.isNotEmpty &&
              state.images.first == null)
          ? l10n.authCaptureNidFront
          : l10n.authCaptureNidBack,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (int i = 0; i < state.images.length; i++) ...[
                  _CaptureSlot(
                    label: _slotLabel(l10n, type, i),
                    imagePath: state.images[i],
                    hintCapture: l10n.authCaptureTapToCapture,
                    hintChange: l10n.authCaptureTapToChange,
                    onTap: state.submitting
                        ? null
                        : () => _captureSlot(ref, i),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (!state.isComplete)
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.commonContinue,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: state.submitting,
                  onPressed: state.isComplete
                      ? () => _submit(context, ref)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labeled preview card: camera prompt when empty, the captured
/// photo with a "tap to change" affordance when filled.
class _CaptureSlot extends StatelessWidget {
  const _CaptureSlot({
    required this.label,
    required this.imagePath,
    required this.hintCapture,
    required this.hintChange,
    required this.onTap,
  });

  final String label;
  final String? imagePath;
  final String hintCapture;
  final String hintChange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool filled = imagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          button: true,
          label: '$label. ${filled ? hintChange : hintCapture}',
          child: Material(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: filled
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(imagePath!), fit: BoxFit.cover),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: const Color(0xB30A0A0C),
                              padding:
                                  const EdgeInsets.all(AppSpacing.xs),
                              child: Text(
                                hintChange,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimaryDark),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hintCapture,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
