import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../infrastructure/notifications/notification_providers.dart';
import '../l10n/app_localizations.dart';
import '../app/di.dart';
import '../features/messaging/presentation/controllers/conversation_controller.dart';
import '../features/messaging/presentation/providers/messaging_providers.dart';
import 'router.dart';

/// Tab shell hosting Home / Chats / Map / Profile branches with the
/// raised SOS action. IndexedStack keeps tab state alive without
/// rebuilding on switch.
///
/// This mounts exactly once per authenticated session (the router
/// only reaches this shell after login/signup), and is the hook point
/// for starting the live-message pipeline: connect the push socket,
/// start NotificationRouter listening for hints, and do one initial
/// pull in case anything arrived while the app was closed. Previously
/// nothing in the app ever called any of these — the push
/// socket/notification router existed but were never started.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _pollTimer;
  StreamSubscription<String>? _fcmTokenRefreshSub;
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;

  @override
  void initState() {
    super.initState();
    _startLiveMessaging();
    _startFcm();
  }

  Future<void> _startLiveMessaging() async {
    try {
      await ref.read(pushSocketProvider).connect();
    } catch (_) {
      // No live push (offline, WS_BASE_URL unset, etc.) — the
      // periodic poll below still gets messages through, just not
      // instantly on arrival.
    }
    ref.read(notificationRouterProvider).start();
    await _pullAndRefresh();

    // A push hint triggers an immediate pull (via NotificationRouter),
    // but pulling/decrypting/storing a message doesn't by itself tell
    // Riverpod that ChatsScreen's/ConversationScreen's data is stale —
    // MessageStore is a plain sqflite database, not something these
    // providers watch. Poll-and-invalidate on a short timer is the
    // simplest fix that covers both "the push socket never fires
    // because it's not connected" and "a message arrived while a
    // conversation screen was already open."
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pullAndRefresh(),
    );
  }

  /// Registers this device for background push. Genuinely optional —
  /// skipped entirely when Firebase isn't configured for this build
  /// (see firebaseReadyProvider's doc comment) — the app must work
  /// identically either way, same as the try/catch around
  /// pushSocketProvider.connect() above.
  Future<void> _startFcm() async {
    if (!ref.read(firebaseReadyProvider)) return;
    try {
      await ref.read(notificationServiceProvider).requestPermission();
      final fcm = ref.read(fcmServiceProvider);
      await fcm.init();
      await fcm.registerToken();
      _fcmTokenRefreshSub = fcm.onTokenRefresh.listen((_) => fcm.registerToken());
      _fcmForegroundSub = fcm.listenForegroundMessages((RemoteMessage message) {
        final notifications = ref.read(notificationServiceProvider);
        switch (message.data['type']) {
          case 'event':
            unawaited(notifications.showNewMessage());
          case 'call_signal':
            if (message.data['kind'] == 'offer') {
              unawaited(notifications.showIncomingCall());
            }
        }
      });
    } catch (_) {
      // FCM setup failed (permission denied, no token available,
      // etc.) — the live-socket/poll path above still covers this
      // device while it's in the foreground.
    }
  }

  Future<void> _pullAndRefresh() async {
    try {
      await ref.read(messageSyncCoordinatorProvider).pullAndProcess();
    } catch (_) {
      return; // offline/transient — next tick retries
    }
    if (!mounted) return;
    ref.invalidate(chatsProvider);
    ref.invalidate(conversationControllerProvider);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(notificationRouterProvider).stop();
    unawaited(ref.read(pushSocketProvider).disconnect());
    unawaited(_fcmTokenRefreshSub?.cancel());
    unawaited(_fcmForegroundSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        items: [
          AppBottomNavItem(
              icon: Icons.home_outlined, label: l10n.navHome),
          AppBottomNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: l10n.navChats),
          AppBottomNavItem(icon: Icons.map_outlined, label: l10n.navMap),
          AppBottomNavItem(
              icon: Icons.person_outline_rounded, label: l10n.navProfile),
        ],
        sosLabel: l10n.navSos,
        onSos: () => context.pushNamed(AppRoutes.sos),
        onTap: (int index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}
