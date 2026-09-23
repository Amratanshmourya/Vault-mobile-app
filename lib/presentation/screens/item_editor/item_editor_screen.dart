import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/crypto/password_generator.dart';
import '../../../core/crypto/password_strength.dart';
import '../../../core/crypto/totp_service.dart';
import '../../../core/services/encrypted_file_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/encrypted_file_attachment.dart';
import '../../../data/models/vault_item.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/security/strength_indicator_bar.dart';

class ItemEditorScreen extends StatefulWidget {
  final VaultItemType? initialType;
  final VaultItem? initialItem;

  const ItemEditorScreen({
    super.key,
    this.initialType,
    this.initialItem,
  });

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final EncryptedFileService _fileService = EncryptedFileService();

  late VaultItemType _itemType;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _folderController;
  late final TextEditingController _tagInputController;

  // Login / Password
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _websiteController;
  late final TextEditingController _totpSecretController;

  // Card
  late final TextEditingController _cardholderController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;
  late final TextEditingController _cvvController;
  late final TextEditingController _pinController;

  // Identity
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dobController;

  // Note
  late final TextEditingController _noteContentController;

  // License
  late final TextEditingController _licenseKeyController;
  late final TextEditingController _licensedToController;
  late final TextEditingController _licenseExpiryController;

  // Recovery codes
  final List<RecoveryCodeEntry> _recoveryCodes = [];

  // Encrypted Attachments
  final List<EncryptedFileAttachment> _attachments = [];

  // Tags
  final List<String> _tags = [];

  final List<CustomField> _customFields = [];
  bool _isFavorite = false;
  PasswordStrengthResult _strength = const PasswordStrengthResult(
    score: 0,
    level: PasswordStrengthLevel.veryWeak,
    warnings: [],
    suggestions: [],
    entropyBits: 0,
  );

  bool _isSaving = false;
  bool _isAttachingFile = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _itemType = item?.type ?? widget.initialType ?? VaultItemType.login;

    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _folderController = TextEditingController(text: item?.folder ?? '');
    _tagInputController = TextEditingController();

    _usernameController = TextEditingController(text: item?.username ?? '');
    _passwordController = TextEditingController(text: item?.password ?? '');
    _websiteController = TextEditingController(text: item?.website ?? '');
    _totpSecretController = TextEditingController(text: item?.totpSecret ?? '');

    _cardholderController = TextEditingController(text: item?.cardholderName ?? '');
    _cardNumberController = TextEditingController(text: item?.cardNumber ?? '');
    _expiryMonthController = TextEditingController(text: item?.expiryMonth ?? '');
    _expiryYearController = TextEditingController(text: item?.expiryYear ?? '');
    _cvvController = TextEditingController(text: item?.cvv ?? '');
    _pinController = TextEditingController(text: item?.pin ?? '');

    _fullNameController = TextEditingController(text: item?.fullName ?? '');
    _emailController = TextEditingController(text: item?.email ?? '');
    _phoneController = TextEditingController(text: item?.phone ?? '');
    _addressController = TextEditingController(text: item?.address ?? '');
    _dobController = TextEditingController(text: item?.dateOfBirth ?? '');

    _noteContentController = TextEditingController(text: item?.noteContent ?? '');

    _licenseKeyController = TextEditingController(text: item?.licenseKey ?? '');
    _licensedToController = TextEditingController(text: item?.licensedTo ?? '');
    _licenseExpiryController = TextEditingController(text: item?.licenseExpiry ?? '');

    if (item != null) {
      _isFavorite = item.isFavorite;
      _tags.addAll(item.tags);
      _recoveryCodes.addAll(item.recoveryCodes);
      _attachments.addAll(item.attachments);
      _customFields.addAll(item.customFields);
      if (item.password != null) {
        _strength = PasswordStrength.evaluate(item.password!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _folderController.dispose();
    _tagInputController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _totpSecretController.dispose();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _noteContentController.dispose();
    _licenseKeyController.dispose();
    _licensedToController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generated = PasswordGenerator.generatePassword(
      const PasswordGeneratorOptions(length: 18),
    );
    _passwordController.text = generated;
    setState(() {
      _strength = PasswordStrength.evaluate(generated);
    });
  }

  void _parseOtpAuthUri(String input) {
    if (input.trim().startsWith('otpauth://')) {
      final parsed = TotpService.parseOtpAuthUri(input.trim());
      if (parsed != null) {
        setState(() {
          _totpSecretController.text = parsed.secret;
          if (_titleController.text.trim().isEmpty && parsed.issuer != null) {
            _titleController.text = parsed.issuer!;
          }
          if (_usernameController.text.trim().isEmpty && parsed.accountName != null) {
            _usernameController.text = parsed.accountName!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parsed TOTP secret successfully!')),
        );
      }
    }
  }

  void _addTag() {
    final raw = _tagInputController.text.trim().replaceFirst(RegExp(r'^#'), '');
    if (raw.isNotEmpty && !_tags.contains(raw)) {
      setState(() {
        _tags.add(raw);
        _tagInputController.clear();
      });
    }
  }

  Future<void> _pickAndAttachFile() async {
    final authState = context.read<AuthState>();
    final activeKey = authState.activeKey;
    if (activeKey == null) return;

    try {
      setState(() => _isAttachingFile = true);
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('Unable to read file data.');
        }

        final attachment = await _fileService.encryptAndSaveFile(
          fileBytes: bytes,
          fileName: file.name,
          secretKey: activeKey,
        );

        setState(() {
          _attachments.add(attachment);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attached "${file.name}" securely')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File attachment error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAttachingFile = false);
      }
    }
  }

  void _addRecoveryCodesDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Recovery Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste one or multiple codes (one code per line).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'ABCD-1234\nEFGH-5678\nIJKL-9012',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final lines = text.split('\n');
                setState(() {
                  for (final line in lines) {
                    final clean = line.trim();
                    if (clean.isNotEmpty) {
                      _recoveryCodes.add(RecoveryCodeEntry(code: clean));
                    }
                  }
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Codes'),
          ),
        ],
      ),
    );
  }

  void _addCustomField() {
    showDialog(
      context: context,
      builder: (ctx) {
        final labelCtrl = TextEditingController();
        final valCtrl = TextEditingController();
        bool isConcealed = false;

        return StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            title: const Text('Add Custom Field'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: labelCtrl, label: 'Field Name', hintText: 'e.g. Security Answer'),
                const SizedBox(height: 12),
                CustomTextField(controller: valCtrl, label: 'Value', hintText: 'Field content'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Conceal value (Sensitive)'),
                  value: isConcealed,
                  onChanged: (val) => setDlgState(() => isConcealed = val ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (labelCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _customFields.add(CustomField(
                        label: labelCtrl.text.trim(),
                        value: valCtrl.text.trim(),
                        isConcealed: isConcealed,
                      ));
                    });
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      final activeKey = authState.activeKey;

      if (activeKey == null) {
        throw Exception('Vault key not available.');
      }

      final existing = widget.initialItem;
      List<PasswordHistoryEntry> history = existing?.passwordHistory ?? [];

      // If password changed, append to history
      final newPassword = _passwordController.text.trim();
      DateTime? passwordUpdatedAt = existing?.passwordUpdatedAt;
      if (newPassword.isNotEmpty) {
        if (existing == null || existing.password != newPassword) {
          passwordUpdatedAt = DateTime.now();
        }
      }

      if (existing != null &&
          existing.password != null &&
          existing.password!.isNotEmpty &&
          newPassword.isNotEmpty &&
          existing.password != newPassword) {
        history = [
          ...history,
          PasswordHistoryEntry(password: existing.password!, recordedAt: DateTime.now()),
        ];
      }

      final updatedItem = VaultItem(
        id: existing?.id,
        type: _itemType,
        title: _titleController.text.trim(),
        folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(),
        isFavorite: _isFavorite,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        password: newPassword.isEmpty ? null : newPassword,
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        totpSecret: _totpSecretController.text.trim().isEmpty ? null : _totpSecretController.text.trim(),
        passwordUpdatedAt: passwordUpdatedAt,
        passwordHistory: history,
        cardholderName: _cardholderController.text.trim().isEmpty ? null : _cardholderController.text.trim(),
        cardNumber: _cardNumberController.text.trim().isEmpty ? null : _cardNumberController.text.trim(),
        expiryMonth: _expiryMonthController.text.trim().isEmpty ? null : _expiryMonthController.text.trim(),
        expiryYear: _expiryYearController.text.trim().isEmpty ? null : _expiryYearController.text.trim(),
        cvv: _cvvController.text.trim().isEmpty ? null : _cvvController.text.trim(),
        pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        noteContent: _noteContentController.text.trim().isEmpty ? null : _noteContentController.text.trim(),
        licenseKey: _licenseKeyController.text.trim().isEmpty ? null : _licenseKeyController.text.trim(),
        licensedTo: _licensedToController.text.trim().isEmpty ? null : _licensedToController.text.trim(),
        licenseExpiry: _licenseExpiryController.text.trim().isEmpty ? null : _licenseExpiryController.text.trim(),
        recoveryCodes: _recoveryCodes,
        attachments: _attachments,
        customFields: _customFields,
        createdAt: existing?.createdAt,
        lastUsedAt: existing?.lastUsedAt,
      );

      if (existing != null) {
        await vaultState.updateItem(updatedItem, activeKey);
      } else {
        await vaultState.addItem(updatedItem, activeKey);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit ${_itemType.label}' : 'New ${_itemType.label}'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? AppColors.warning : null,
            ),
            tooltip: 'Favorite',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hintText: 'e.g. GitHub, Netflix, Chase Card',
                autofocus: !isEditing,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Login / Password Fields
              if (_itemType == VaultItemType.login || _itemType == VaultItemType.password) ...[
                if (_itemType == VaultItemType.login) ...[
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Username / Email',
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                  const SizedBox(height: 14),
                ],
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter password',
                  isPassword: true,
                  isMonospace: true,
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Generate secure password',
                    onPressed: _generatePassword,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _strength = PasswordStrength.evaluate(val);
                    });
                  },
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  StrengthIndicatorBar(strength: _strength),
                ],
                if (_itemType == VaultItemType.login) ...[
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _websiteController,
                    label: 'Website / URL',
                    hintText: 'https://github.com',
                    keyboardType: TextInputType.url,
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _totpSecretController,
                    label: 'Authenticator Key (TOTP Secret or otpauth://)',
                    hintText: 'Base32 secret (e.g. JBSWY3DPEHPK3PXP)',
                    isMonospace: true,
                    prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                    onChanged: _parseOtpAuthUri,
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        if (!TotpService.isValidSecret(val)) {
                          return 'Invalid Base32 secret format';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
              ],

              // Card Fields
              if (_itemType == VaultItemType.card) ...[
                CustomTextField(
                  controller: _cardholderController,
                  label: 'Cardholder Name',
                  hintText: 'Cardholder Name',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _cardNumberController,
                  label: 'Card Number',
                  hintText: '•••• •••• •••• ••••',
                  keyboardType: TextInputType.number,
                  isMonospace: true,
                  prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _expiryMonthController,
                        label: 'Exp Month (MM)',
                        hintText: '09',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _expiryYearController,
                        label: 'Exp Year (YY/YYYY)',
                        hintText: '2028',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cvvController,
                        label: 'CVV / CVC',
                        hintText: '123',
                        isPassword: true,
                        isMonospace: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _pinController,
                        label: 'PIN',
                        hintText: '••••',
                        isPassword: true,
                        isMonospace: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Identity Fields
              if (_itemType == VaultItemType.identity) ...[
                CustomTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hintText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hintText: '+1 (555) 000-0000',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _addressController,
                  label: 'Physical Address',
                  hintText: 'Street, City, State, ZIP',
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                const SizedBox(height: 14),
              ],

              // Secure Note Content
              if (_itemType == VaultItemType.note) ...[
                CustomTextField(
                  controller: _noteContentController,
                  label: 'Secure Note Content',
                  hintText: 'Encrypted notes, memos, instructions...',
                  maxLines: 8,
                ),
                const SizedBox(height: 14),
              ],

              // Software License Fields
              if (_itemType == VaultItemType.license) ...[
                CustomTextField(
                  controller: _licenseKeyController,
                  label: 'License / Product Key',
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                  isMonospace: true,
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _licensedToController,
                  label: 'Licensed To',
                  hintText: 'Name / Organization',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _licenseExpiryController,
                  label: 'License Expiration / Validity',
                  hintText: 'e.g. Lifetime / 2027-12-31',
                  prefixIcon: const Icon(Icons.event_outlined, size: 20),
                ),
                const SizedBox(height: 14),
              ],

              // Recovery Codes Checklist Builder
              if (_itemType == VaultItemType.recoveryCode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recovery Codes (${_recoveryCodes.length})', style: AppTypography.titleSmall),
                    TextButton.icon(
                      onPressed: _addRecoveryCodesDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Codes'),
                    ),
                  ],
                ),
                if (_recoveryCodes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._recoveryCodes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final code = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: VaultCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                code.code,
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                              onPressed: () {
                                setState(() => _recoveryCodes.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 14),
              ],

              // Encrypted File Attachments Section (Any item can also have attachments)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Encrypted Attachments (${_attachments.length})', style: AppTypography.titleSmall),
                  TextButton.icon(
                    onPressed: _isAttachingFile ? null : _pickAndAttachFile,
                    icon: _isAttachingFile
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Attach File'),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._attachments.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final att = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VaultCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(att.fileName, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                                Text(
                                  att.formattedSize,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            onPressed: () {
                              setState(() => _attachments.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 14),

              // Tags Section
              Text('Tags', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add tag (e.g. Work, Finance)',
                        prefixText: '#',
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),

              // Folder selection
              CustomTextField(
                controller: _folderController,
                label: 'Folder',
                hintText: 'e.g. Work, Personal, Finance',
                prefixIcon: const Icon(Icons.folder_outlined, size: 20),
              ),
              const SizedBox(height: 14),

              // General Notes
              CustomTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hintText: 'Optional private details',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Custom Fields Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Custom Fields', style: AppTypography.titleSmall),
                  TextButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Field'),
                  ),
                ],
              ),
              if (_customFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._customFields.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final field = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VaultCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.label,
                                  style: AppTypography.caption.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  field.isConcealed ? '••••••••' : field.value,
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            onPressed: () {
                              setState(() {
                                _customFields.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
