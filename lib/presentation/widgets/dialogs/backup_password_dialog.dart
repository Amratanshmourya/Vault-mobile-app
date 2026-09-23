import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../common/custom_text_field.dart';

class BackupPasswordDialog extends StatefulWidget {
  final String title;
  final String description;
  final String actionLabel;
  final bool isConfirmRequired;

  const BackupPasswordDialog({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.isConfirmRequired = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String actionLabel,
    bool isConfirmRequired = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => BackupPasswordDialog(
        title: title,
        description: description,
        actionLabel: actionLabel,
        isConfirmRequired: isConfirmRequired,
      ),
    );
  }

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isConfirmRequired &&
        _passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title, style: AppTypography.titleMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Backup Password',
                hintText: 'Enter strong password',
                isPassword: true,
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (widget.isConfirmRequired) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _confirmController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter backup password',
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please confirm password';
                    }
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
