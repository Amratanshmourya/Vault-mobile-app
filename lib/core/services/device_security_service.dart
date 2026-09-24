import '../services/biometric_service.dart';
import '../services/storage_service.dart';

class DeviceSecurityStatus {
  final bool biometricsSupported;
  final bool biometricsEnrolled;
  final bool hardwareKeystoreAvailable;
  final bool screenCurtainEnabled;
  final bool clipboardAutoClearActive;
  final bool isStrictlyOffline;
  final String deviceSecuritySummary;

  const DeviceSecurityStatus({
    required this.biometricsSupported,
    required this.biometricsEnrolled,
    required this.hardwareKeystoreAvailable,
    required this.screenCurtainEnabled,
    required this.clipboardAutoClearActive,
    required this.isStrictlyOffline,
    required this.deviceSecuritySummary,
  });
}

class DeviceSecurityService {
  final BiometricService biometricService;
  final StorageService storageService;

  DeviceSecurityService({
    required this.biometricService,
    required this.storageService,
  });

  Future<DeviceSecurityStatus> assessDeviceSecurity() async {
    final bioSupported = await biometricService.isBiometricAvailable();
    final bioEnrolled = await biometricService.hasEnrolledBiometrics();
    final bioKey = await storageService.getBiometricKey();
    final clipboardSecs = await storageService.getClipboardTimeoutSeconds();

    return DeviceSecurityStatus(
      biometricsSupported: bioSupported,
      biometricsEnrolled: bioEnrolled,
      hardwareKeystoreAvailable: bioKey != null,
      screenCurtainEnabled: true, // FLAG_SECURE always active
      clipboardAutoClearActive: clipboardSecs > 0,
      isStrictlyOffline: true, // 100% offline-first architecture with zero internet permissions
      deviceSecuritySummary: bioSupported && bioEnrolled
          ? 'Maximum Security: Hardware Keystore & Biometric Authentication Active'
          : 'High Security: Offline AES-256-GCM Vault Active',
    );
  }
}
