import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/vault_item.dart';
import '../../data/models/folder.dart';
import '../services/storage_service.dart';

class EmergencyKitService {
  final StorageService storageService;

  EmergencyKitService({required this.storageService});

  /// Generates human-readable, printable Emergency Recovery Kit document
  Future<String> generateEmergencyKitContent({
    required String vaultName,
    required List<VaultItem> items,
    required List<Folder> folders,
    String? masterPasswordHint,
  }) async {
    final salt = await storageService.getMasterSalt();
    final saltFingerprint = salt != null ? sha256.convert(salt).toString().substring(0, 16).toUpperCase() : 'UNKNOWN';
    final profile = await storageService.getUserProfile();
    final date = DateTime.now().toUtc().toIso8601String().split('T').first;

    return '''# 🛡️ VAULT EMERGENCY RECOVERY KIT
**Confidential Security Document — Store in a Secure Physical Location**

---

### 1. VAULT IDENTIFIERS
* **Owner:** ${profile.displayName}
* **Vault Name:** $vaultName
* **Generated On:** $date (UTC)
* **Cryptographic Salt Fingerprint:** `$saltFingerprint`
* **Total Items Stored:** ${items.length} (${items.where((i) => !i.isDeleted).length} Active)
* **Folders:** ${folders.map((f) => f.name).join(', ')}

---

### 2. MASTER PASSWORD ACCESS
${masterPasswordHint != null && masterPasswordHint.isNotEmpty ? '* **Master Password Hint:** $masterPasswordHint' : '* **Master Password Hint:** No hint recorded'}
* **Master Password:** ________________________________________________

> ⚠️ **CRITICAL WARNING:** Vault uses zero-knowledge AES-256-GCM encryption with PBKDF2-HMAC-SHA256 (100,000 rounds).
> There are **NO backdoors, NO cloud recovery servers, and NO customer support resets**.
> Without your Master Password and encrypted `.vault` backup file, your encrypted data cannot be decrypted by anyone.

---

### 3. RECOVERY INSTRUCTIONS
1. **Install Vault App** on your target device (Android/iOS).
2. If restoring an existing backup:
   - On the Onboarding / Setup screen, select **"Restore from Encrypted Backup"**.
   - Select your `.vault` backup file.
   - Enter your Master Password used when the backup was created.
3. If setting up a fresh device:
   - Create your master password.
   - Go to **Settings > Security & Backups > Restore Vault**.
4. Verify all items and folders match your cryptographic inventory above.

---
*Generated completely offline by Vault v3.0 on-device cryptographic engine.*
''';
  }

  /// Exports the Emergency Kit file and triggers native share sheet
  Future<void> shareEmergencyKit({
    required String vaultName,
    required List<VaultItem> items,
    required List<Folder> folders,
    String? masterPasswordHint,
  }) async {
    final content = await generateEmergencyKitContent(
      vaultName: vaultName,
      items: items,
      folders: folders,
      masterPasswordHint: masterPasswordHint,
    );

    final tempDir = await getTemporaryDirectory();
    final sanitizedName = vaultName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final file = File('${tempDir.path}/Vault_Emergency_Kit_$sanitizedName.md');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Vault Emergency Recovery Kit - $vaultName',
    );
  }
}
