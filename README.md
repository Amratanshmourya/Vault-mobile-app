# 🛡️ Vault — Premium Offline Personal Security Vault (V3)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Security](https://img.shields.io/badge/Encryption-AES--256--GCM-success?style=for-the-badge&logo=lock)
![KDF](https://img.shields.io/badge/KDF-PBKDF2--100k-blueviolet?style=for-the-badge)
![Privacy](https://img.shields.io/badge/Offline-100%25%20No%20Tracking-brightgreen?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-60%2F60%20Passing-brightgreen?style=for-the-badge)

<br/>

**A modern, polished, privacy-first personal security vault built with Flutter.**  
*Zero network permissions. Zero accounts. Zero cloud dependencies. Zero telemetry.*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Core Privacy & Security Guarantees](#-core-privacy--security-guarantees)
- [What's New in Vault V3](#-whats-new-in-vault-v3)
- [Key Features](#-key-features)
  - [1. Passkeys & WebAuthn Credentials](#1-passkeys--webauthn-credentials)
  - [2. Multiple Independent Vaults](#2-multiple-independent-vaults)
  - [3. Custom Fields 2.0](#3-custom-fields-20)
  - [4. Advanced Password & Diceware Generator](#4-advanced-password--diceware-generator)
  - [5. Smart Collections](#5-smart-collections)
  - [6. Local Security Audit Center](#6-local-security-audit-center)
  - [7. Vault Maintenance & Integrity Diagnostics](#7-vault-maintenance--integrity-diagnostics)
  - [8. Offline Emergency Recovery Kit](#8-offline-emergency-recovery-kit)
  - [9. RFC 6238 TOTP Authenticator](#9-rfc-6238-totp-authenticator)
  - [10. Encrypted File Attachments & Secure Viewer](#10-encrypted-file-attachments--secure-viewer)
  - [11. Verified Backups & Restore Diff Preview](#11-verified-backups--restore-diff-preview)
  - [12. Hardware-Backed Biometrics & Privacy Protection](#12-hardware-backed-biometrics--privacy-protection)
- [Cryptographic Specifications](#-cryptographic-specifications)
- [Project Architecture](#-project-architecture)
- [Getting Started](#-getting-started)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [License](#-license)

---

## 🔒 Overview

**Vault** is an offline-first mobile personal security application designed to provide consumer-grade visual polish, airtight cryptography, and complete sovereign ownership over confidential data.

Unlike conventional password managers that rely on remote synchronization, user accounts, and telemetry, **Vault never connects to the internet**. All encryption, key derivation, search indexing, security auditing, and TOTP computations execute **100% on-device**.

---

## 🛡️ Core Privacy & Security Guarantees

| Invariant | Guarantee |
| :--- | :--- |
| **Zero Network Calls** | No HTTP/HTTPS clients, no remote configuration, no crash reporters. |
| **No Accounts / No Telemetry** | No email sign-up, no phone verification, zero analytics, zero trackers. |
| **Authenticated Encryption** | **AES-256-GCM** authenticated cipher protecting all vault data, files, and backups against tampering. |
| **Hardened Key Derivation** | **PBKDF2-HMAC-SHA256 (100,000 rounds)** with a 16-byte cryptographically secure random salt. |
| **Hardware-Backed Biometrics** | Biometric unlock keys stored in encrypted hardware-backed keystore (`FlutterSecureStorage`). |
| **Memory Isolation** | Decrypted data and encryption keys are strictly zeroed out / cleared on lock and screen disposal. |

---

## 🚀 What's New in Vault V3

* 🔑 **Passkeys / FIDO2 Credentials**: WebAuthn metadata, relying party tracking, public key discovery, and passkey upgrade scanner.
* 🛡️ **Multiple Independent Vaults**: Isolated partitions for Personal, Work, Family, or Crypto with instant switching and individual encryption keys.
* 🏷️ **Custom Fields 2.0**: Typed custom fields (Text, Secret, URL, Email, Username, Password, Number, Date, Multiline, Boolean) with rich inline actions.
* 🎲 **Advanced Generator & Diceware**: 1Password-style preset profiles (High Security, Memorable Diceware, Numeric PIN, Custom) and Shannon entropy calculation.
* 🗂️ **Smart Collections**: Query-driven dynamic views (Passkeys, Favorites, Weak, Reused, Old, Missing 2FA, Files, Trash).
* 🩺 **Vault Integrity & Maintenance**: On-device storage breakdown, integrity diagnostics, and orphan attachment pruning.
* 📄 **Emergency Recovery Kit**: Offline printable/savable physical recovery sheet with cryptographic salt fingerprint.

---

## ✨ Key Features

### 1. Passkeys & WebAuthn Credentials
* Store and manage FIDO2/WebAuthn passkeys alongside or independently of login credentials.
* Tracks Relying Party (`RP ID`), User Handle / Username, Credential ID (base64url/hex), Algorithm (ES256, RS256, Ed25519), and Authenticator Attachment (`platform` or `cross-platform`).
* Security Center automatically scans your saved logins for known services that support passkeys and recommends one-tap upgrades.

### 2. Multiple Independent Vaults
* Organize credentials across distinct, isolated partitions (e.g. *Personal*, *Work*, *Finance*, *Family*).
* Fast **Vault Switcher Bottom Sheet** to transition contexts instantly.
* Default primary vault protection to prevent accidental loss.

### 3. Custom Fields 2.0
* Expand any credential with 10 specialized field types:
  * 📝 `Text`, 🔒 `Secret / Hidden`, 🔗 `URL`, ✉️ `Email`, 👤 `Username`, 🔑 `Password`, 🔢 `Number`, 📅 `Date`, 📄 `Multiline`, 🔘 `Boolean`.
* One-tap copy, reveal toggle, URL launcher, and full backward compatibility with legacy custom fields.

### 4. Advanced Password & Diceware Generator
* **Preset Profiles**:
  * **High Security**: 32-character high-entropy alphanumeric + symbols.
  * **Memorable Diceware**: Multi-word passphrases with custom separators and capitalization.
  * **Numeric PIN**: 4 to 12 digit cryptographically secure codes.
  * **No Ambiguous**: Eliminates easily confused characters (`l`, `1`, `I`, `O`, `0`).
* **Real-time Entropy Evaluator**: Shannon entropy calculation with live bits-of-security and strength rating.

### 5. Smart Collections
* Rapidly filter your vault items via dynamic query chips on the home screen:
  * 🔑 *Passkeys*, ⭐ *Favorites*, ⚠️ *Weak*, 🔁 *Reused*, ⏳ *Old (>180d)*, 🛡️ *Missing 2FA*, 📎 *Files*, 🗑️ *Trash*.

### 6. Local Security Audit Center
* **Vault Health Score**: 0–100 rating evaluated entirely on-device.
* **Zero-Knowledge Password Reuse Detection**: Detects duplicate passwords across accounts without exposing plaintext.
* **Password Age Tracking**: Flags credentials older than 180 days for scheduled rotation.
* **Missing 2FA Identification**: Pinpoints high-value logins missing TOTP protection.
* **Passkey Upgrade Opportunities**: Identifies top services ready for passkey transition.

### 7. Vault Maintenance & Integrity Diagnostics
* Storage breakdown visualizing space allocated to SQLite/Prefs, Encrypted File Attachments, Backups, and Cache.
* Integrity scanner detecting missing blobs and unreferenced orphaned files.
* Safe one-tap pruning of orphaned attachments.

### 8. Offline Emergency Recovery Kit
* Generates a clean, physical recovery markdown sheet containing vault identifiers, creation date, salt fingerprint, and instructions.
* Share or save locally to export a physical copy for a safe deposit box or emergency contact.

### 9. RFC 6238 TOTP Authenticator
* Pure offline implementation of **RFC 6238 standard TOTP**.
* Real-time animated circular countdown timer (30-second standard step).
* Automatic parsing of standard `otpauth://` URIs and QR code links.

### 10. Encrypted File Attachments & Secure Viewer
* Local files are encrypted with AES-256-GCM into isolated storage.
* **On-Demand Memory Decryption**: Files decrypt straight into memory without writing temporary plaintext files to disk.
* **In-Memory Viewer**: Instant preview for images (`JPG`, `PNG`, `WEBP`) and text documents (`TXT`, `JSON`, `MD`, `CSV`).

### 11. Verified Backups & Restore Diff Preview
* **Pre-Export Cryptographic Verification**: Automatically verifies the backup payload before saving/sharing.
* **Restore Diff Comparison**: Inspects `.vault` backup files before restoring (Added, Modified, Removed, Unchanged).

### 12. Hardware-Backed Biometrics & Privacy Protection
* **Biometric Unlock**: Fingerprint and Face Unlock support via Android `BiometricPrompt` (`FlutterFragmentActivity`).
* **Inactivity Auto-Lock**: Configurable lock timeout (*Immediately, 1m, 5m, 15m, 30m, Never*).
* **Clipboard Auto-Clear**: Automatically wipes copied passwords from memory and clipboard after *15s, 30s, or 60s*.
* **Privacy Shield**: Blurs app contents in the recent tasks/app switcher.
* **Theme System**: Light, Dark, and true pitch black **AMOLED** theme.

---

## 🔐 Cryptographic Specifications

```
Master Password ─────► PBKDF2-HMAC-SHA256 (100,000 iterations) ─────► Master Key (256-bit)
                             ▲
                             │ 16-byte CSPRNG Salt

Vault Data JSON ─────► AES-256-GCM (Authenticated Encryption) ─────► Encrypted Payload
                             ▲
                             │ 96-bit Unique Nonce + 128-bit MAC Tag
```

* **Key Derivation (KDF)**: PBKDF2 with HMAC-SHA256, 100,000 iterations, 16-byte CSPRNG salt.
* **Cipher**: AES-256-GCM authenticated cipher (`cryptography` package).
* **MAC / Authentication Tag**: 128-bit tag ensuring authenticity and fail-closed tamper detection.
* **TOTP Algorithm**: HMAC-SHA1 dynamic truncation (RFC 6238 / RFC 4226).
* **Random Source**: Platform CSPRNG via Dart `Random.secure()`.

---

## 📁 Project Architecture

```
lib/
├── core/
│   ├── constants/       # App constants, sort options, crypto parameters
│   ├── crypto/          # AES-GCM, PBKDF2, TOTP engine, generator, strength evaluator
│   ├── services/        # Storage, backup, auto-lock, clipboard, encrypted files, autofill, maintenance, emergency kit
│   └── theme/           # App colors, typography, theme definitions, AMOLED provider
├── data/
│   ├── models/          # VaultItem, PasskeyCredential, VaultDescriptor, SmartCollection, Folder, EncryptedFileAttachment
│   └── repositories/    # Multi-vault encrypted repository, in-memory search, bulk operations
└── presentation/
    ├── screens/         # Home, Search, Generator, Security Dashboard, Settings, Viewer, Maintenance
    ├── state/           # AuthState, VaultState, SecurityDashboardState
    └── widgets/         # Reusable UI cards, custom inputs, dialogs, badges, strength bar, switcher
```

---

## 🛠️ Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+)
* [Android Studio / Xcode](https://docs.flutter.dev/get-started/install) for mobile emulator/device testing.

### Installation & Build

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Amratanshmourya/Vault-mobile-app.git
   cd Vault
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run automated analysis:**
   ```bash
   flutter analyze
   ```

4. **Run all automated test suites:**
   ```bash
   flutter test
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

6. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Testing & Quality Assurance

Vault maintains 16 comprehensive test suites with **60 passing automated tests**:

* `test/crypto_test.dart` — PBKDF2 key derivation, AES-GCM encryption/decryption, password generation, strength entropy.
* `test/auth_lifecycle_test.dart` — First-run onboarding, master password change, biometric hardware key binding, auto-lock.
* `test/v2_totp_test.dart` — RFC 6238 token computation, time steps, otpauth URI parser.
* `test/v2_autofill_domain_test.dart` — Domain normalization, subdomain matching, anti-phishing defense.
* `test/v2_backup_diff_test.dart` — Cryptographic backup verification, tamper detection, restore diff computation.
* `test/v2_search_filters_tags_test.dart` — Tag indexing, multi-attribute filter combinations, sorting, bulk actions.
* `test/v2_encrypted_file_test.dart` — File attachment encryption metadata, size threshold validation.
* `test/v3_passkey_test.dart` — Passkey FIDO2/WebAuthn models, credential attributes, autofill domain matching.
* `test/v3_custom_fields_test.dart` — Custom Fields 2.0 serialization, types, and legacy backward compatibility.
* `test/v3_generator_presets_test.dart` — Presets (High Security, Diceware, PIN), Shannon entropy.
* `test/v3_multi_vault_test.dart` — Multi-vault creation, storage isolation, switching, default deletion guard.
* `test/v3_security_audit_test.dart` — Zero-Knowledge SHA-256 reuse clustering, passkey opportunity scanner.
* `test/v3_maintenance_test.dart` — Storage breakdown calculation, Emergency Recovery Kit generation.
* `test/vault_repository_test.dart` — CRUD operations, 1,000-item search scale performance (<50ms), memory isolation.
* `test/widget_test.dart` — Onboarding and UI rendering tests.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
