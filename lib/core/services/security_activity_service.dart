import 'package:uuid/uuid.dart';
import '../../data/models/security_event.dart';
import 'storage_service.dart';

class SecurityActivityService {
  final StorageService storageService;
  static const int maxStoredEvents = 100;

  SecurityActivityService({required this.storageService});

  /// Records a non-sensitive security audit event locally
  Future<void> recordEvent({
    required SecurityEventType type,
    required String description,
  }) async {
    final event = SecurityEvent(
      id: const Uuid().v4(),
      type: type,
      description: description,
      timestamp: DateTime.now(),
    );

    final events = await getEvents();
    final updated = List<SecurityEvent>.from(events)..insert(0, event);

    if (updated.length > maxStoredEvents) {
      updated.removeRange(maxStoredEvents, updated.length);
    }

    await storageService.saveSecurityEvents(updated);
  }

  /// Retrieves list of all recorded security events
  Future<List<SecurityEvent>> getEvents() async {
    return await storageService.getSecurityEvents();
  }

  /// Clears all security activity logs
  Future<void> clearEvents() async {
    await storageService.saveSecurityEvents([]);
  }
}
