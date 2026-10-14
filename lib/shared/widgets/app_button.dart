import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final spinnerColor = switch (variant) {
      AppButtonVariant.primary => AppColors.onAccent,
      AppButtonVariant.danger => AppColors.white,
      AppButtonVariant.secondary || AppButtonVariant.ghost => AppColors.navy,
    };
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
          )
        else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        if (!loading) Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
