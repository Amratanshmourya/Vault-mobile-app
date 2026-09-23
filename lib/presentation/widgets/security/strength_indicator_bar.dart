import 'package:flutter/material.dart';
import '../../../core/crypto/password_strength.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StrengthIndicatorBar extends StatelessWidget {
  final PasswordStrengthResult strength;
  final bool showSuggestions;

  const StrengthIndicatorBar({
    super.key,
    required this.strength,
    this.showSuggestions = true,
  });

  Color _getColor() {
    switch (strength.level) {
      case PasswordStrengthLevel.veryWeak:
        return AppColors.danger;
      case PasswordStrengthLevel.weak:
        return AppColors.danger.withAlpha(200);
      case PasswordStrengthLevel.fair:
        return AppColors.warning;
      case PasswordStrengthLevel.strong:
        return AppColors.secondary;
      case PasswordStrengthLevel.veryStrong:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strength: ${strength.level.label}',
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(strength.score * 100).toInt()}%',
              style: AppTypography.caption.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength.level.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        if (showSuggestions && (strength.warnings.isNotEmpty || strength.suggestions.isNotEmpty)) ...[
          const SizedBox(height: 8),
          ...strength.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      w,
                      style: AppTypography.caption.copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...strength.suggestions.take(1).map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 13, color: theme.colorScheme.onSurface.withAlpha(150)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s,
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
