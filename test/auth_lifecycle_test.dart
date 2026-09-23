import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/presentation/state/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AuthState authState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    authState = AuthState(storageService: storageService);
    await authState.initialize();
  });

  group('Authentication & Key Lifecycle Audit Tests', () {
    test('Fresh install starts in uninitialized state', () {
      expect(authState.isUninitialized, isTrue);
      expect(authState.isLocked, isFalse);
      expect(authState.isUnlocked, isFalse);
      expect(authState.activeKey, isNull);
    });

    test('Master password setup derives key and transitions to unlocked state', () async {
      final key = await authState.setupMasterPassword(
        password: 'MasterPassword#2026',
        displayName: 'Amratansh',
      );

      expect(key, isNotNull);
      expect(authState.isUnlocked, isTrue);
      expect(authState.activeKey, isNotNull);
      expect(authState.userProfile.displayName, 'Amratansh');

      // Check stored hash & salt exist in storage
      final storedHash = await storageService.getMasterHash();
      final storedSalt = await storageService.getMasterSalt();
      expect(storedHash, isNotNull);
      expect(storedSalt, isNotNull);
      expect(storedSalt!.length, 16);
    });

    test('Locking clears active key and transitions to locked state', () async {
      await authState.setupMasterPassword(password: 'Password123!');
      expect(authState.isUnlocked, isTrue);
      expect(authState.activeKey, isNotNull);

      authState.lock();
      expect(authState.isLocked, isTrue);
      expect(authState.isUnlocked, isFalse);
      expect(authState.activeKey, isNull); // Key wiped from memory
    });

    test('Unlocking with correct master password succeeds and updates last login', () async {
      await authState.setupMasterPassword(password: 'CorrectPassword123!');
      authState.lock();

      final key = await authState.unlockWithPassword('CorrectPassword123!');
      expect(authState.isUnlocked, isTrue);
      expect(key, isNotNull);
      expect(authState.userProfile.lastLoginAt, isNotNull);
    });

    test('Unlocking with incorrect master password throws and leaves vault locked', () async {
      await authState.setupMasterPassword(password: 'CorrectPassword123!');
      authState.lock();

      expect(
        () async => await authState.unlockWithPassword('WrongPassword!'),
        throwsA(isA<Exception>()),
      );

      expect(authState.isLocked, isTrue);
      expect(authState.activeKey, isNull);
    });

    test('Changing master password re-derives key and updates verifier hash', () async {
      await authState.setupMasterPassword(password: 'OldPassword123!');
      final oldHash = await storageService.getMasterHash();

      final newKey = await authState.changeMasterPassword(
        oldPassword: 'OldPassword123!',
        newPassword: 'NewStrongPassword#2026',
      );

      expect(newKey, isNotNull);
      final newHash = await storageService.getMasterHash();
      expect(newHash, isNot(equals(oldHash)));

      // Lock and verify unlock with new password
      authState.lock();
      final reUnlockedKey = await authState.unlockWithPassword('NewStrongPassword#2026');
      expect(reUnlockedKey, isNotNull);
      expect(authState.isUnlocked, isTrue);
    });
  });
}
