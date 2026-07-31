import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_models.dart';
import '../providers/messaging_providers.dart';

/// Chat list: search, active people strip, all chats.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pushAndMaybeRefresh(String routeName) async {
    final Object? added = await context.pushNamed<Object?>(routeName);
    // A contact was added — the inbox's contact-backed list is stale.
    if (added != null) ref.invalidate(chatsProvider);
  }

  Future<void> _openAddContactSheet() async {
    await showAppBottomSheet<void>(
      context,
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: const Text('My pairing code'),
            subtitle: const Text('Show a QR code for someone to scan'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.pushNamed(AppRoutes.myQr);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: const Text('Scan a code'),
            subtitle: const Text("Scan a contact's pairing code"),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pushAndMaybeRefresh(AppRoutes.scanQr);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('Add by number'),
            subtitle: const Text('Find a contact by their phone number'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pushAndMaybeRefresh(AppRoutes.addByNumber);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Add contact',
            onPressed: _openAddContactSheet,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: chatsAsync.when(
              loading: () => const AppLoading(),
              error: (_, __) =>
                  AppStatusView.error(title: l10n.errorGenericTitle),
              data: (List<ChatSummary> chats) {
                if (chats.isEmpty) {
                  return AppStatusView.empty(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'No paired contacts yet',
                    message: 'Scan a QR code, share yours, or search by '
                        'phone number to start a chat.',
                    actionLabel: 'Add a contact',
                    onAction: _openAddContactSheet,
                  );
                }

                final String query = _search.text.trim().toLowerCase();
                final List<ChatSummary> filtered = query.isEmpty
                    ? chats
                    : chats
                        .where((c) =>
                            c.name.toLowerCase().contains(query))
                        .toList();
                final List<ChatSummary> active =
                    chats.where((c) => c.online).toList();

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    AppTextField(
                      controller: _search,
                      hint: l10n.chatsSearchHint,
                      prefixIcon: Icons.search_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (active.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            l10n.chatsActivePeople('${active.length}'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: active.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, int i) => AppAvatar(
                            name: active[i].name,
                            size: 44,
                            online: true,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.chatsAll,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.sm),
                    for (final ChatSummary chat in filtered)
                      _ChatTile(chat: chat),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () => context.pushNamed(
        AppRoutes.conversation,
        pathParameters: {'id': chat.id},
        extra: chat.name,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            AppAvatar(name: chat.name, online: chat.online),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chat.name, style: theme.textTheme.titleMedium),
                      if (chat.ageLabel.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '•  ${chat.ageLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
