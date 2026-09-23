# 🛡️ Vault — Premium Offline Personal Security Vault

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Security](https://img.shields.io/badge/Encryption-AES--256--GCM-success?style=for-the-badge&logo=lock)
![KDF](https://img.shields.io/badge/KDF-PBKDF2--100k-blueviolet?style=for-the-badge)
![Privacy](https://img.shields.io/badge/Offline-100%25%20No%20Tracking-brightgreen?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange?style=for-the-badge)

<br/>

**A modern, polished, privacy-first personal security vault built with Flutter.**  
*Zero network permissions. Zero accounts. Zero cloud dependencies. Zero telemetry.*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Core Privacy & Security Guarantees](#-core-privacy--security-guarantees)
- [Key Features](#-key-features)
  - [1. Expanded 8 Vault Categories](#1-expanded-8-vault-categories)
  - [2. RFC 6238 TOTP Authenticator](#2-rfc-6238-totp-authenticator)
  - [3. Encrypted File Attachments & Secure Viewer](#3-encrypted-file-attachments--secure-viewer)
  - [4. Tags, Smart Filters & Bulk Actions](#4-tags-smart-filters--bulk-actions)
  - [5. Password & Passphrase Generator](#5-password--passphrase-generator)
  - [6. Local Security Audit Center](#6-local-security-audit-center)
  - [7. Verified Backups & Restore Diff Preview](#7-verified-backups--restore-diff-preview)
  - [8. Hardware-Backed Biometrics & Privacy Protection](#8-hardware-backed-biometrics--privacy-protection)
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

## ✨ Key Features

### 1. Expanded 8 Vault Categories
Store and organize diverse confidential credentials with specialized fields:
* 🔑 **Logins**: Username, password, website URL, TOTP 2FA secret, custom fields, and password version history.
* 🔐 **Standalone Passwords**: Wi-Fi passkeys, server credentials, access tokens.
* 💳 **Payment Cards**: Cardholder name, masked number preview (`•••• 1234`), expiration, encrypted CVV, and PIN.
* 🪪 **Identities & Passports**: Full name, passport/ID numbers, email, phone, physical address, birth date.
* 📝 **Secure Notes**: Encrypted confidential memos and markdown documents.
* 📎 **Encrypted Files**: Photos, PDFs, and documents encrypted at rest with AES-256-GCM (up to 25 MB per file).
* 🛡️ **Recovery Codes**: Interactive checklist for 2FA emergency backup codes with one-tap copy and used/remaining counters.
* 📜 **Software Licenses**: Product keys, licensed name, and expiration/validity dates.

### 2. RFC 6238 TOTP Authenticator
* Pure offline implementation of **RFC 6238 standard TOTP**.
* Real-time animated circular countdown timer (30-second standard step).
* Automatic parsing of standard `otpauth://` URIs and QR code links.
* Dynamic Base32 decoder and dynamic truncation.

### 3. Encrypted File Attachments & Secure Viewer
* Local files are encrypted with AES-256-GCM into isolated storage.
* **On-Demand Memory Decryption**: Files decrypt straight into memory without writing temporary plaintext files to disk.
* **In-Memory Viewer**: Instant preview for images (`JPG`, `PNG`, `WEBP`) and text documents (`TXT`, `JSON`, `MD`, `CSV`).

### 4. Tags, Smart Filters & Bulk Actions
* **Tagging System**: Add and manage custom `#tags` across all items.
* **Smart Filter Bottom Sheet**: Multi-attribute filtering by category, folder, tags, favorites, and TOTP status.
* **Fast Sorting**: Sort by Name (A–Z / Z–A), Recently Updated, Date Created, Most Used, and Password Strength.
* **Multi-Select Bulk Operations**: Long-press items to bulk move to folders, bulk add/remove tags, bulk favorite, or bulk delete.

### 5. Password & Passphrase Generator
* **Random Mode**: Configurable length (8–48 chars), uppercase, lowercase, numbers, symbols, and ambiguous character filtering.
* **Diceware Passphrase Mode**: Memorable, cryptographically strong word sequences with custom separators, capitalization, and numbers.
* **Real-time Entropy Evaluator**: Live strength indicator calculating Shannon entropy, pattern checks, repetition, and sequence penalties.

### 6. Local Security Audit Center
* **Vault Health Score**: 0–100 rating evaluated entirely on-device.
* **Zero-Knowledge Password Reuse Detection**: Detects duplicate passwords across accounts without exposing plaintext.
* **Password Age Tracking**: Flags credentials older than 90 days for review.
* **Missing 2FA Identification**: Pinpoints high-value logins missing TOTP protection.
* **Security Activity Audit Log**: On-device chronological timeline recording vault unlocks, item modifications, and backups.

### 7. Verified Backups & Restore Diff Preview
* **Pre-Export Cryptographic Verification**: Automatically verifies the backup payload before saving/sharing.
* **Restore Diff Comparison**: Inspects `.vault` backup files before restoring, giving an exact preview of:
  * ➕ **New items to add (+X)**
  * 🔄 **Items to modify (~Y)**
  * ➖ **Items to remove (-Z)**
  * ✔️ **Identical items (=W)**
* **Standalone Backup Verifier**: Verify integrity and inspect contents of any `.vault` file without affecting your active vault.

### 8. Hardware-Backed Biometrics & Privacy Protection
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
│   ├── services/        # Storage, backup, auto-lock, clipboard, encrypted files, autofill
│   └── theme/           # App colors, typography, theme definitions, AMOLED provider
├── data/
│   ├── models/          # VaultItem, Folder, EncryptedFileAttachment, SecurityEvent, DiffResult
│   └── repositories/    # Encrypted vault repository, in-memory search, bulk operations
└── presentation/
    ├── screens/         # Home, Search, Generator, Security Dashboard, Settings, Viewer
    ├── state/           # AuthState, VaultState, SecurityDashboardState
    └── widgets/         # Reusable UI cards, custom inputs, dialogs, badges, strength bar
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

Vault maintains comprehensive test suites covering all cryptographic operations, security flows, and search algorithms:

* `test/crypto_test.dart` — PBKDF2 key derivation, AES-GCM encryption/decryption, password generation, strength entropy.
* `test/auth_lifecycle_test.dart` — First-run onboarding, master password change, biometric hardware key binding, auto-lock.
* `test/v2_totp_test.dart` — RFC 6238 token computation, time steps, otpauth URI parser.
* `test/v2_autofill_domain_test.dart` — Domain normalization, subdomain matching, anti-phishing defense.
* `test/v2_backup_diff_test.dart` — Cryptographic backup verification, tamper detection, restore diff computation.
* `test/v2_search_filters_tags_test.dart` — Tag indexing, multi-attribute filter combinations, sorting, bulk actions.
* `test/v2_encrypted_file_test.dart` — File attachment encryption metadata, size threshold validation.
* `test/vault_repository_test.dart` — CRUD operations, 1,000-item search scale performance (<50ms), memory isolation.
* `test/widget_test.dart` — Onboarding and UI rendering tests.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
