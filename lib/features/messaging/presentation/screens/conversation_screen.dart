import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../infrastructure/media/media_providers.dart';
import '../../../../infrastructure/media/voice_player.dart';
import '../../../../infrastructure/media/voice_recorder.dart';
import '../../../../infrastructure/storage/contact_directory_store.dart';
import '../../../../infrastructure/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../voice/presentation/controllers/call_controller.dart';
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
  ChatMessage? _replyTarget;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _replyPreview {
    final ChatMessage? target = _replyTarget;
    if (target == null) return null;
    return target.isVoiceNote ? '🎤 Voice note' : target.text;
  }

  void _setReplyTarget(ChatMessage message) =>
      setState(() => _replyTarget = message);

  void _cancelReply() => setState(() => _replyTarget = null);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final String text = _input.text;
    if (text.trim().isEmpty) return;
    final String? reply = _replyPreview;
    _input.clear();
    setState(() => _replyTarget = null);
    await ref
        .read(conversationControllerProvider(widget.chatId).notifier)
        .send(text, replyToPreview: reply);
    _scrollToBottom();
  }

  Future<void> _startCall() async {
    final ContactDirectoryStore directory =
        ref.read(contactDirectoryStoreProvider);
    final DirectoryContact? contact =
        await directory.byDisplayName(widget.peerName);
    if (contact == null) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        "Can't call ${widget.peerName} yet — pair with them first "
        '(no way to look up their mailbox_id without it).',
        kind: AppSnackbarKind.error,
      );
      return;
    }
    await ref.read(callControllerProvider.notifier).startOutgoingCall(
          peerMailboxId: contact.mailboxId,
          peerName: widget.peerName,
        );
    if (!mounted) return;
    context.pushNamed(AppRoutes.call);
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
            // No presence system exists (see ChatSummary.online's own
            // doc comment) — no online dot, no fabricated "last seen"
            // timestamp, just the name.
            AppAvatar(name: widget.peerName, size: 34),
            const SizedBox(width: AppSpacing.xs),
            Text(widget.peerName, style: theme.textTheme.titleMedium),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _startCall,
              icon: const Icon(Icons.call_outlined, size: 20)),
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
                      itemBuilder: (_, int i) => _MessageBubble(
                        message: messages[i],
                        onReply: _setReplyTarget,
                      ),
                    ),
                  ),
                ),
                _Composer(
                  controller: _input,
                  onSend: _send,
                  replyPreview: _replyPreview,
                  onCancelReply: _cancelReply,
                  onVoiceNote: (String path, Duration duration) async {
                    final String? reply = _replyPreview;
                    setState(() => _replyTarget = null);
                    await ref
                        .read(conversationControllerProvider(widget.chatId)
                            .notifier)
                        .sendVoiceNote(path, duration, replyToPreview: reply);
                    _scrollToBottom();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A static, deterministic bar pattern standing in for a real
/// amplitude waveform (none is captured at record time — see
/// VoiceRecorder's doc comment) — same look every rebuild for a given
/// message, and doubles as a scrub bar via [onSeek].
class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({
    required this.seed,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
    required this.onSeek,
  });

  final int seed;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final ValueChanged<double> onSeek;

  static const int _barCount = 24;

  List<double> _heights() {
    final math.Random rnd = math.Random(seed);
    return List<double>.generate(_barCount, (_) => 4 + rnd.nextDouble() * 14);
  }

  @override
  Widget build(BuildContext context) {
    final List<double> heights = _heights();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        void handle(Offset local) {
          final double fraction =
              (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onSeek(fraction);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) => handle(d.localPosition),
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              handle(d.localPosition),
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < _barCount; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    child: Container(
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: (i / _barCount) <= progress
                            ? playedColor
                            : unplayedColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends ConsumerStatefulWidget {
  const _MessageBubble({required this.message, required this.onReply});

  final ChatMessage message;
  final ValueChanged<ChatMessage> onReply;

  @override
  ConsumerState<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<_MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _playing = false;
  Duration _position = Duration.zero;
  StreamSubscription<PlayerState>? _sub;
  StreamSubscription<Duration>? _posSub;

  double _dragDx = 0;
  static const double _replyThreshold = 56;
  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _sub?.cancel();
    _posSub?.cancel();
    _snapBack.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final VoicePlayer player = ref.read(voicePlayerProvider);
    final String? path = widget.message.audioPath;
    if (path == null) return;
    if (_playing) {
      await player.pause();
      _posSub?.cancel();
      if (mounted) setState(() => _playing = false);
      return;
    }
    _sub?.cancel();
    _sub = player.onStateChanged.listen((PlayerState s) {
      if (s == PlayerState.completed && mounted) {
        _posSub?.cancel();
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    _posSub?.cancel();
    _posSub = player.onPositionChanged.listen((Duration pos) {
      if (mounted) setState(() => _position = pos);
    });
    await player.play(path);
    if (mounted) setState(() => _playing = true);
  }

  Future<void> _onWaveformSeek(double fraction) async {
    if (!_playing) {
      await _togglePlay();
      return;
    }
    final Duration? total = widget.message.audioDuration;
    if (total == null) return;
    final VoicePlayer player = ref.read(voicePlayerProvider);
    final Duration target = total * fraction;
    await player.seek(target);
    if (mounted) setState(() => _position = target);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragDx = (_dragDx + details.delta.dx).clamp(0.0, 80.0));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragDx > _replyThreshold) widget.onReply(widget.message);
    final Animation<double> anim = Tween<double>(begin: _dragDx, end: 0)
        .animate(CurvedAnimation(parent: _snapBack, curve: Curves.easeOut));
    void listener() => setState(() => _dragDx = anim.value);
    anim.addListener(listener);
    _snapBack.forward(from: 0).whenComplete(() => anim.removeListener(listener));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ChatMessage message = widget.message;
    final bool outgoing = message.direction == MessageDirection.outgoing;

    // Outgoing: light periwinkle with dark text (per design).
    final Color bg =
        outgoing ? const Color(0xFFB9BAF6) : theme.colorScheme.surface;
    final Color fg =
        outgoing ? AppColors.backgroundDark : theme.colorScheme.onSurface;
    final Color meta = outgoing
        ? AppColors.backgroundDark.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant;

    final Duration? total = message.audioDuration;
    final double progress = (total != null && total.inMilliseconds > 0)
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: (_dragDx / _replyThreshold).clamp(0.0, 1.0),
                  child: Icon(Icons.reply_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragDx, 0),
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
                        if (message.isReply)
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.xxs),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: fg.withValues(alpha: 0.5),
                                    width: 2),
                              ),
                            ),
                            child: Text(
                              message.replyToPreview!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: fg.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (message.isVoiceNote)
                          Row(
                            children: [
                              InkWell(
                                onTap: _togglePlay,
                                borderRadius: BorderRadius.circular(20),
                                child: Icon(
                                  _playing
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  size: 32,
                                  color: fg,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: _VoiceWaveform(
                                  seed: message.id.hashCode,
                                  progress: progress,
                                  playedColor: fg,
                                  unplayedColor: fg.withValues(alpha: 0.3),
                                  onSeek: _onWaveformSeek,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _playing
                                    ? '${_durationLabel(_position)} / '
                                        '${_durationLabel(total)}'
                                    : _durationLabel(total),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: fg),
                              ),
                            ],
                          )
                        else
                          Text(message.text,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: fg)),
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
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(Duration? d) {
    if (d == null) return '0:00';
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onVoiceNote,
    required this.replyPreview,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(String path, Duration duration) onVoiceNote;
  final String? replyPreview;
  final VoidCallback onCancelReply;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer>
    with SingleTickerProviderStateMixin {
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  double _cancelDragDx = 0;
  Timer? _timer;
  StreamSubscription<double>? _ampSub;

  static const double _cancelThreshold = -80;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final VoiceRecorder recorder = ref.read(voiceRecorderProvider);
    if (!await recorder.hasPermission()) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        'Microphone permission is needed to record a voice note.',
        kind: AppSnackbarKind.error,
      );
      return;
    }
    await recorder.start();
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
      _cancelDragDx = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _ampSub = recorder.onAmplitudeChanged.listen((double level) {
      if (mounted) setState(() => _level = level);
    });
  }

  Future<void> _stopAndSend() async {
    final VoiceRecorder recorder = ref.read(voiceRecorderProvider);
    _timer?.cancel();
    await _ampSub?.cancel();
    final ({String path, Duration duration})? result = await recorder.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    if (result != null) widget.onVoiceNote(result.path, result.duration);
  }

  Future<void> _cancelRecording() async {
    final VoiceRecorder recorder = ref.read(voiceRecorderProvider);
    _timer?.cancel();
    await _ampSub?.cancel();
    await recorder.cancel();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _cancelDragDx = 0;
    });
  }

  void _onCancelDragUpdate(DragUpdateDetails details) {
    setState(() {
      _cancelDragDx =
          (_cancelDragDx + details.delta.dx).clamp(_cancelThreshold * 1.4, 0);
    });
  }

  void _onCancelDragEnd(DragEndDetails details) {
    if (_cancelDragDx <= _cancelThreshold) {
      _cancelRecording();
    } else {
      setState(() => _cancelDragDx = 0);
    }
  }

  String _timerLabel() {
    final int m = _elapsed.inMinutes;
    final int s = _elapsed.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

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
        border: Border.all(
          color: _recording ? AppColors.danger : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyPreview != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      widget.replyPreview!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onCancelReply,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          if (_recording)
            GestureDetector(
              onHorizontalDragUpdate: _onCancelDragUpdate,
              onHorizontalDragEnd: _onCancelDragEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _pulse,
                      child: const SizedBox(
                        width: 10,
                        height: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: AppColors.danger, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(_timerLabel(),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.danger)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Opacity(
                        opacity: (1 +
                                _cancelDragDx / (_cancelThreshold.abs() * 1.4))
                            .clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_left_rounded,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            Text('Slide to cancel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Container(
                        width: 6 + _level * 14,
                        height: 6 + _level * 14,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: _stopAndSend,
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.send_rounded,
                          size: 22, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
            )
          else
            TextField(
              controller: widget.controller,
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
          if (!_recording)
            Row(
              children: [
                Icon(Icons.emoji_emotions_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.attach_file_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: _startRecording,
                  borderRadius: BorderRadius.circular(16),
                  child: Icon(Icons.mic_rounded,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onSend,
                  icon: Text(l10n.commonSend,
                      style: theme.textTheme.labelLarge),
                  label: const Icon(Icons.send_rounded, size: 16),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
