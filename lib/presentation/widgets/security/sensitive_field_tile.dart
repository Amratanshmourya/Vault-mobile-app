import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../common/vault_card.dart';

class SensitiveFieldTile extends StatefulWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final bool isMonospace;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenUrl;
  final Widget? trailing;

  const SensitiveFieldTile({
    super.key,
    required this.label,
    required this.value,
    this.isSensitive = false,
    this.isMonospace = false,
    this.onCopy,
    this.onOpenUrl,
    this.trailing,
  });

  @override
  State<SensitiveFieldTile> createState() => _SensitiveFieldTileState();
}

class _SensitiveFieldTileState extends State<SensitiveFieldTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHidden = widget.isSensitive && !_revealed;

    final displayText = isHidden
        ? '•' * (widget.value.length > 20 ? 20 : widget.value.length.clamp(8, 20))
        : widget.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: VaultCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: AppTypography.caption.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    displayText,
                    style: (widget.isMonospace || widget.isSensitive)
                        ? AppTypography.monospace.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          )
                        : AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                  ),
                ],
              ),
            ),
            if (widget.isSensitive) ...[
              IconButton(
                icon: Icon(
                  _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
                tooltip: _revealed ? 'Hide' : 'Reveal',
                onPressed: () {
                  setState(() {
                    _revealed = !_revealed;
                  });
                },
              ),
            ],
            if (widget.onOpenUrl != null) ...[
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                tooltip: 'Open link',
                color: theme.colorScheme.primary,
                onPressed: widget.onOpenUrl,
              ),
            ],
            if (widget.onCopy != null) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy',
                color: theme.colorScheme.onSurface.withAlpha(160),
                onPressed: widget.onCopy,
              ),
            ],
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
