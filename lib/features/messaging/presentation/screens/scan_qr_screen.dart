import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../infrastructure/storage/contact_directory_store.dart';
import '../../../../infrastructure/storage/storage_providers.dart';

/// Scans a peer's [MyQrScreen] code and saves them to
/// [ContactDirectoryStore] — the other half of QR pairing.
class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final String? raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;

    final DirectoryContact contact;
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      contact = DirectoryContact.fromJson(json);
    } catch (_) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        "That code isn't a valid pairing code.",
        kind: AppSnackbarKind.error,
      );
      return;
    }

    _handled = true;
    await _controller.stop();
    await ref.read(contactDirectoryStoreProvider).add(contact);
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Paired with ${contact.displayName}.',
      kind: AppSnackbarKind.success,
    );
    Navigator.of(context).pop(contact);
  }

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission was denied. Enable it in system '
            'settings to scan a pairing code.';
      case MobileScannerErrorCode.unsupported:
        return 'No camera is available on this device (simulators '
            "generally don't have one — try a physical device).";
      default:
        return "Couldn't start the camera: ${error.errorCode.message}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to pair')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            placeholderBuilder: (BuildContext context, Widget? child) =>
                const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorBuilder: (BuildContext context, MobileScannerException error,
                    Widget? child) =>
                ColoredBox(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _cameraErrorMessage(error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: Colors.black54,
              child: Text(
                "Point the camera at your contact's pairing code.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
