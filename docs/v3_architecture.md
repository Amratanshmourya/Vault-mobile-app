# Vault V3 — Master Implementation & Architecture Blueprint

## 1. Executive Summary & Vision
Vault V3 elevates the application into a mature, production-grade, 100% offline personal security vault. It introduces:
1. **Passkey Credentials**: WebAuthn/FIDO2 metadata, relying party tracking, biometric-ready representation, and seamless integration.
2. **Multiple Independent Vaults**: Encrypted partitions (e.g. Personal, Work, Shared/Family), independent key derivation, isolated storage prefixes, and seamless switching.
3. **Custom Fields 2.0**: Typed custom fields (Text, Secret, URL, Email, Username, Password, Number, Date, Multiline, Boolean) with rich field-specific actions.
4. **Advanced Autofill Engine**: Exact origin matching, subdomain hierarchy, multi-account picker, anti-phishing origin verification, and passkey support.
5. **Advanced Password Generator**: Diceware wordlist passphrases, presets (High Security, Memorable, PIN, No Ambiguous), and entropy measurement.
6. **Smart Collections**: Query-driven dynamic views (Passkeys, Favorites, Reused, Weak, Old >180d, Missing 2FA, Secure Files, Trash).
7. **Vault Integrity & Maintenance Engine**: Cryptographic verification, orphaned attachment pruning, missing attachment detection, database health repair.
8. **Storage Dashboard**: Real-time breakdown of local footprint (JSON DB, Encrypted Blobs, Backups, Cache) with one-tap optimization.
9. **Device Security Diagnostics**: Comprehensive hardware and OS security posture audit.
10. **Advanced Emergency Kit**: Locally generated, self-contained, printable/savable recovery document with cryptographic fingerprint.

---

## 2. Cryptographic & Multi-Vault Architecture

```mermaid
flowchart TD
    MP[User Master Password] --> KDF[PBKDF2-HMAC-SHA256 (100k rounds)]
    Salt[Per-Vault Salt (32 bytes CSPRNG)] --> KDF
    KDF --> MEK[Vault Master Encryption Key (256-bit)]
    
    MEK --> GCM[AES-256-GCM Authenticated Encryption]
    
    subgraph MultiVault Isolation
        VD[Vault Descriptor Registry]
        V1[Vault 1: Personal (vault_items_default)]
        V2[Vault 2: Work (vault_items_work)]
        V3[Vault 3: Family (vault_items_family)]
    end
    
    GCM --> V1
    GCM --> V2
    GCM --> V3
```

---

## 3. Core Data Model Expansions

### A. Passkey Credential Model (`PasskeyCredential`)
- `id`: UUID v4
- `rpId`: Relying Party Identifier (e.g., `github.com`, `apple.com`)
- `rpName`: Relying Party Human Name (e.g., `GitHub`, `Apple ID`)
- `userName`: User name / login identifier
- `userHandle`: Raw user handle (base64 / hex string)
- `credentialId`: Unique credential identifier (base64)
- `algorithm`: Public key algorithm (`ES256`, `RS256`, `Ed25519`)
- `authenticatorAttachment`: `platform` | `cross-platform`
- `transports`: List of supported transports (`internal`, `usb`, `nfc`, `ble`, `hybrid`)
- `createdAt`: Creation timestamp
- `lastUsedAt`: Last authentication timestamp
- `backupEligible`: Boolean flag for multi-device sync eligibility
- `backupState`: Boolean flag indicating synced state

### B. Custom Field 2.0 (`CustomField`)
- `id`: UUID v4
- `label`: Custom field display label
- `value`: Stored string representation
- `type`: `text` | `secret` | `url` | `email` | `username` | `password` | `number` | `date` | `multiline` | `boolean`
- `isConcealed`: Backward-compatible boolean flag for concealed state

### C. Multiple Vault Descriptor (`VaultDescriptor`)
- `id`: UUID v4
- `name`: Vault name (e.g., "Personal", "Work", "Vault 2")
- `icon`: Material icon code / emoji identifier
- `colorHex`: Hex color code for UI customization
- `isDefault`: Boolean
- `createdAt`: Creation timestamp
- `updatedAt`: Last updated timestamp
- `itemCount`: Cached item counter
- `sizeBytes`: Cached storage footprint

---

## 4. Phase-by-Phase Execution Schedule

- **Phase 1**: Architecture & Data Migration (Schema expansion, backwards compatibility).
- **Phase 2**: Passkeys (Data models, serializers, editor/detail UI, test suite).
- **Phase 3**: Custom Fields 2.0 (Type enum, field pickers, dedicated actions, rendering).
- **Phase 4**: Advanced Password Generator (Diceware word list, preset selector, entropy).
- **Phase 5**: Multiple Independent Vaults (`VaultDescriptor`, `VaultRepository` multi-vault support, Vault Switcher UI).
- **Phase 6**: Advanced Autofill & Domain Normalizer (Multi-account suggestions, passkey flags).
- **Phase 7**: Advanced Security Center (Zero-Knowledge reuse detector, age alerts, passkey opportunity finder).
- **Phase 8**: Smart Collections (Query engine and dynamic filter chips).
- **Phase 9**: Vault Integrity, Maintenance & Storage Dashboard (`VaultMaintenanceService`, health repair, size breakdown).
- **Phase 10**: Device Security Diagnostics & Emergency Kit (Offline audit, Emergency kit export).
- **Phase 11**: Verification & Integration (Full test pass, 0 lint warnings, APK build verification).
