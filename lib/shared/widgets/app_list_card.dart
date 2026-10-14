import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.leading,
    this.onTap,
    this.highlighted = false,
    this.embedded = false,
    this.showChevron,
    this.subtitleWidget,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool embedded;
  final bool? showChevron;
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chevron = showChevron ?? onTap != null;
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 8),
                    subtitleWidget!,
                  ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                  if (meta != null && meta!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      meta!,
                      style: text.labelMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: trailing!,
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.navyMuted),
            ],
          ],
        ),
      ),
    );

    if (embedded) return row;

    return Card(
      color: highlighted ? AppColors.amberSoft : AppColors.white,
      clipBehavior: Clip.antiAlias,
      child: row,
    );
  }
}

class AppIconWell extends StatelessWidget {
  const AppIconWell({
    super.key,
    required this.icon,
    this.color = AppColors.navy,
    this.background = AppColors.mist,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
