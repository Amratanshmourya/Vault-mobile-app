import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';

class AutoLockService with WidgetsBindingObserver {
  final StorageService storageService;
  final VoidCallback onLockTriggered;
  DateTime? _lastBackgroundTime;
  Timer? _inactivityTimer;

  AutoLockService({
    required this.storageService,
    required this.onLockTriggered,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  void recordUserActivity() {
    _resetInactivityTimer();
  }

  Future<void> _resetInactivityTimer() async {
    _inactivityTimer?.cancel();
    final seconds = await storageService.getAutoLockSeconds();
    if (seconds > 0) {
      _inactivityTimer = Timer(Duration(seconds: seconds), () {
        onLockTriggered();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastBackgroundTime = DateTime.now();
      storageService.getAutoLockSeconds().then((seconds) {
        if (seconds == 0) {
          onLockTriggered();
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        final elapsedSeconds = DateTime.now().difference(_lastBackgroundTime!).inSeconds;
        _checkBackgroundLock(elapsedSeconds);
        _lastBackgroundTime = null;
      }
      _resetInactivityTimer();
    }
  }

  Future<void> _checkBackgroundLock(int elapsedSeconds) async {
    final configuredSeconds = await storageService.getAutoLockSeconds();
    if (configuredSeconds == 0) {
      // Immediately
      onLockTriggered();
    } else if (configuredSeconds > 0 && elapsedSeconds >= configuredSeconds) {
      onLockTriggered();
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
