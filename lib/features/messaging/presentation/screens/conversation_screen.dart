import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_models.dart';
import '../controllers/conversation_controller.dart';

/// One-to-one conversation: message list + dual-layer composer.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    required this.chatId,
    required this.peerName,
    super.key,
  });

  final String chatId;
  final String peerName;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref
        .read(conversationControllerProvider(widget.chatId).notifier)
        .send(text);
    // Keep newest message visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final messagesAsync =
        ref.watch(conversationControllerProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(name: widget.peerName, size: 34, online: true),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName,
                    style: theme.textTheme.titleMedium),
                Text(
                  '15m ago',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined, size: 20)),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.videocam_outlined, size: 22)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Column(
              children: [
                Expanded(
                  child: messagesAsync.when(
                    loading: () => const AppLoading(),
                    error: (_, __) => AppStatusView.error(
                        title: l10n.errorGenericTitle),
                    data: (List<ChatMessage> messages) =>
                        ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length,
                      itemBuilder: (_, int i) =>
                          _MessageBubble(message: messages[i]),
                    ),
                  ),
                ),
                _Composer(
                  controller: _input,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool outgoing = message.direction == MessageDirection.outgoing;

    // Outgoing: light periwinkle with dark text (per design).
    final Color bg =
        outgoing ? const Color(0xFFB9BAF6) : theme.colorScheme.surface;
    final Color fg =
        outgoing ? AppColors.backgroundDark : theme.colorScheme.onSurface;
    final Color meta = outgoing
        ? AppColors.backgroundDark.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.mdAll,
              border: outgoing
                  ? const Border(
                      right: BorderSide(
                          color: AppColors.primaryDeep, width: 3),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: fg)),
                const SizedBox(height: AppSpacing.xxs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    message.timestampLabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: meta, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (message.encrypted)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_rounded,
                  size: 10, color: AppColors.info),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.composerVisibleLabel,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.composerEncryptedHint,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
          ),
          Row(
            children: [
              Icon(Icons.emoji_emotions_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.attach_file_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const Spacer(),
              TextButton.icon(
                onPressed: onSend,
                icon: Text(l10n.commonSend,
                    style: theme.textTheme.labelLarge),
                label:
                    const Icon(Icons.send_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
