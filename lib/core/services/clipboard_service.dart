import 'dart:async';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class ClipboardService {
  final StorageService storageService;
  Timer? _clearTimer;
  String? _lastCopiedText;

  ClipboardService({required this.storageService});

  /// Copies text to clipboard and schedules auto-clear timer based on settings
  Future<String> copyWithAutoClear({
    required String text,
    String itemLabel = 'Item',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    _lastCopiedText = text;

    _clearTimer?.cancel();

    final timeoutSeconds = await storageService.getClipboardTimeoutSeconds();
    if (timeoutSeconds > 0) {
      _clearTimer = Timer(Duration(seconds: timeoutSeconds), () async {
        try {
          final current = await Clipboard.getData(Clipboard.kTextPlain);
          if (current?.text == _lastCopiedText) {
            await Clipboard.setData(const ClipboardData(text: ''));
          }
        } catch (_) {
        } finally {
          _lastCopiedText = null;
        }
      });
      return '$itemLabel copied. Clipboard clears in $timeoutSeconds seconds.';
    } else {
      return '$itemLabel copied to clipboard.';
    }
  }

  /// Manually clears clipboard immediately and clears internal memory reference
  Future<void> clearImmediately() async {
    _clearTimer?.cancel();
    _lastCopiedText = null;
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}
  }

  void dispose() {
    _clearTimer?.cancel();
    _lastCopiedText = null;
  }
}
