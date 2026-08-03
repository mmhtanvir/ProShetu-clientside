import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../infrastructure/storage/contact_directory_store.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

/// WhatsApp/Telegram-style "add by phone number": searches
/// /v1/sms/lookup for an account registered under the given number
/// (only accounts that shared a display name at signup are
/// findable), then saves the result to [ContactDirectoryStore] — the
/// same store QR pairing writes to.
class AddByNumberScreen extends ConsumerStatefulWidget {
  const AddByNumberScreen({super.key});

  @override
  ConsumerState<AddByNumberScreen> createState() => _AddByNumberScreenState();
}

class _AddByNumberScreenState extends ConsumerState<AddByNumberScreen> {
  String _phone = '';
  bool _loading = false;
  String? _error;
  ({
    String mailboxId,
    String displayName,
    String ed25519Pub,
    String x25519Pub,
  })? _result;

  Future<void> _search() async {
    final String phone = _phone.trim();
    if (phone.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final Result<
        Failure,
        ({
          String mailboxId,
          String displayName,
          String ed25519Pub,
          String x25519Pub,
        })> res = await ref.read(smsVerifyClientProvider).lookupByPhone(phone);
    if (!mounted) return;
    switch (res) {
      case Ok<
          Failure,
          ({
            String mailboxId,
            String displayName,
            String ed25519Pub,
            String x25519Pub,
          })>(:final value):
        setState(() {
          _loading = false;
          _result = value;
        });
      case Err<
          Failure,
          ({
            String mailboxId,
            String displayName,
            String ed25519Pub,
            String x25519Pub,
          })>(:final value):
        setState(() {
          _loading = false;
          _error = value.message;
        });
    }
  }

  Future<void> _addContact() async {
    final ({
      String mailboxId,
      String displayName,
      String ed25519Pub,
      String x25519Pub,
    })? result = _result;
    if (result == null) return;
    await ref.read(contactDirectoryStoreProvider).add(
          DirectoryContact(
            displayName: result.displayName,
            mailboxId: result.mailboxId,
            ed25519Pub: result.ed25519Pub,
            x25519Pub: result.x25519Pub,
          ),
        );
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Added ${result.displayName}.',
      kind: AppSnackbarKind.success,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add by number')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  "Search for a contact's phone number to add them — "
                  'only accounts that shared a name at signup are '
                  'findable this way.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPhoneField(
                  label: 'Phone number',
                  hint: '555 0100',
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) => _phone = value,
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Search',
                  isLoading: _loading,
                  onPressed: _search,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.danger),
                  ),
                if (_result != null)
                  AppCard(
                    child: Row(
                      children: [
                        AppAvatar(name: _result!.displayName),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _result!.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        AppButton(
                          label: 'Add',
                          expanded: false,
                          onPressed: _addContact,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
