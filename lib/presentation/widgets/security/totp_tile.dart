import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/crypto/totp_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/vault_card.dart';

class TotpTile extends StatefulWidget {
  final String secretBase32;
  final void Function(String code)? onCopy;

  const TotpTile({
    super.key,
    required this.secretBase32,
    this.onCopy,
  });

  @override
  State<TotpTile> createState() => _TotpTileState();
}

class _TotpTileState extends State<TotpTile> {
  Timer? _ticker;
  TotpResult? _currentResult;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  void _refresh() {
    final res = TotpService.generateCurrent(secretBase32: widget.secretBase32);
    if (mounted) {
      setState(() {
        _currentResult = res;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _currentResult;

    if (res == null) {
      return const SizedBox.shrink();
    }

    final isUrgent = res.remainingSeconds <= 5;
    final progressColor = isUrgent ? AppColors.danger : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: VaultCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'TWO-FACTOR CODE (TOTP)',
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Circular countdown ring
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: res.progress,
                        strokeWidth: 2.5,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Text(
                        '${res.remainingSeconds}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectableText(
                  res.formattedCode,
                  style: AppTypography.totpLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy 2FA code',
                  onPressed: () {
                    if (widget.onCopy != null) {
                      widget.onCopy!(res.code);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
