import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Vault contents. Real encrypted media storage
/// (infrastructure/media + crypto) doesn't exist yet, so this is a
/// genuine empty state rather than fabricated gallery tiles —
/// showing fake photos/dates here would be indistinguishable from
/// real vault contents to a user, which is worse than showing
/// nothing.
class VaultGalleryScreen extends StatelessWidget {
  const VaultGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileVault)),
      body: SafeArea(
        child: AppStatusView.empty(
          icon: Icons.lock_outline_rounded,
          title: l10n.vaultEmptyTitle,
          message: l10n.vaultEmptyMessage,
        ),
      ),
    );
  }
}
