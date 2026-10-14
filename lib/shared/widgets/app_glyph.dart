import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppGlyphTone { navy, neon, muted, success, danger, inverse }

class AppGlyph extends StatelessWidget {
  const AppGlyph({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize,
    this.tone = AppGlyphTone.navy,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final AppGlyphTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppGlyphTone.navy => (AppColors.navySoft, AppColors.orange),
      AppGlyphTone.neon => (AppColors.successSoft, AppColors.success),
      AppGlyphTone.muted => (AppColors.mist, AppColors.muted),
      AppGlyphTone.success => (AppColors.successSoft, AppColors.success),
      AppGlyphTone.danger => (AppColors.dangerSoft, AppColors.danger),
      AppGlyphTone.inverse => (AppColors.navy, AppColors.white),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: tone == AppGlyphTone.neon
            ? Border.all(color: AppColors.success.withValues(alpha: 0.28))
            : null,
      ),
      child: Icon(icon, color: colors.$2, size: iconSize ?? size * 0.48),
    );
  }
}
