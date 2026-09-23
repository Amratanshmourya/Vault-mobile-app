import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/encrypted_file_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/encrypted_file_attachment.dart';
import '../../state/auth_state.dart';
import '../../widgets/common/vault_card.dart';

class SecureFileViewerScreen extends StatefulWidget {
  final EncryptedFileAttachment attachment;
  final VoidCallback? onDelete;

  const SecureFileViewerScreen({
    super.key,
    required this.attachment,
    this.onDelete,
  });

  @override
  State<SecureFileViewerScreen> createState() => _SecureFileViewerScreenState();
}

class _SecureFileViewerScreenState extends State<SecureFileViewerScreen> {
  final EncryptedFileService _fileService = EncryptedFileService();
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _decryptFile();
  }

  @override
  void dispose() {
    // Secure memory hygiene: zero out sensitive decrypted memory
    if (_decryptedBytes != null) {
      _decryptedBytes!.fillRange(0, _decryptedBytes!.length, 0);
      _decryptedBytes = null;
    }
    super.dispose();
  }

  Future<void> _decryptFile() async {
    final authState = context.read<AuthState>();
    final activeKey = authState.activeKey;

    if (activeKey == null) {
      setState(() {
        _errorMessage = 'Vault is locked. Decryption key unavailable.';
        _isLoading = false;
      });
      return;
    }

    try {
      final bytes = await _fileService.decryptAttachmentInMemory(
        attachment: widget.attachment,
        secretKey: activeKey,
      );
      if (mounted) {
        setState(() {
          _decryptedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Decryption failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool get _isImage {
    final mime = widget.attachment.mimeType.toLowerCase();
    return mime.startsWith('image/') ||
        widget.attachment.fileName.endsWith('.png') ||
        widget.attachment.fileName.endsWith('.jpg') ||
        widget.attachment.fileName.endsWith('.jpeg') ||
        widget.attachment.fileName.endsWith('.webp') ||
        widget.attachment.fileName.endsWith('.gif');
  }

  bool get _isText {
    final mime = widget.attachment.mimeType.toLowerCase();
    return mime.startsWith('text/') ||
        widget.attachment.fileName.endsWith('.txt') ||
        widget.attachment.fileName.endsWith('.json') ||
        widget.attachment.fileName.endsWith('.md') ||
        widget.attachment.fileName.endsWith('.csv');
  }

  Future<void> _shareFile() async {
    if (_decryptedBytes == null) return;
    try {
      final xFile = XFile.fromData(
        _decryptedBytes!,
        name: widget.attachment.fileName,
        mimeType: widget.attachment.mimeType,
      );
      await Share.shareXFiles([xFile], text: 'Exported from Vault (Secure File)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attachment.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_decryptedBytes != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Export File',
              onPressed: _shareFile,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Decrypting attachment in-memory...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Preview Card
                        VaultCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_isImage && _decryptedBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _decryptedBytes!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image_rounded, size: 64),
                                    ),
                                  ),
                                )
                              else if (_isText && _decryptedBytes != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    utf8.decode(_decryptedBytes!, allowMalformed: true),
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded, size: 64, color: AppColors.primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.attachment.fileName,
                                      style: AppTypography.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.attachment.formattedSize,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: theme.colorScheme.onSurface.withAlpha(140),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Security & File Information
                        Text(
                          'SECURITY & METADATA',
                          style: AppTypography.titleSmall.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(140),
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        VaultCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              _buildMetadataRow('Encryption', 'AES-256-GCM authenticated'),
                              const Divider(height: 16),
                              _buildMetadataRow('Storage', 'Encrypted local filesystem'),
                              const Divider(height: 16),
                              _buildMetadataRow('File Size', widget.attachment.formattedSize),
                              const Divider(height: 16),
                              _buildMetadataRow('MIME Type', widget.attachment.mimeType),
                              const Divider(height: 16),
                              _buildMetadataRow(
                                'Added On',
                                '${widget.attachment.createdAt.day}/${widget.attachment.createdAt.month}/${widget.attachment.createdAt.year}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(160),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
