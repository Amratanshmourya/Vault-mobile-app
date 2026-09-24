import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';

class CategoryBadge extends StatelessWidget {
  final VaultItemType type;
  final bool showLabel;

  const CategoryBadge({
    super.key,
    required this.type,
    this.showLabel = true,
  });

  Color _getColor() {
    switch (type) {
      case VaultItemType.login:
        return AppColors.categoryLogin;
      case VaultItemType.passkey:
        return Colors.deepPurpleAccent;
      case VaultItemType.password:
        return AppColors.categoryPassword;
      case VaultItemType.card:
        return AppColors.categoryCard;
      case VaultItemType.identity:
        return AppColors.categoryIdentity;
      case VaultItemType.note:
        return AppColors.categoryNote;
      case VaultItemType.file:
        return Colors.teal;
      case VaultItemType.recoveryCode:
        return Colors.indigo;
      case VaultItemType.license:
        return Colors.amber.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.icon, style: const TextStyle(fontSize: 12)),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              type.label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
