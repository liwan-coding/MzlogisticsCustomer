import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/section_paths.dart';
import '../../core/theme/app_colors.dart';

void popToParent(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(sectionFallback(GoRouterState.of(context).uri.path));
}

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool? showBack;
  final VoidCallback? onBack;

  static const double _toolbar = 64;
  static const double _toolbarWithSubtitle = 78;

  double get _toolbarHeight => subtitle == null ? _toolbar : _toolbarWithSubtitle;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final back = showBack ?? context.canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: AppColors.surface,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _toolbarHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 48) return const SizedBox.expand();
                  return Row(
                    children: [
                      if (back)
                        IconButton(
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          icon: const BackButtonIcon(),
                          color: AppColors.ink,
                          onPressed: onBack ?? () => popToParent(context),
                        )
                      else
                        const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.46),
                        child: IconTheme(
                          data: const IconThemeData(color: AppColors.ink),
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [...?actions, const SizedBox(width: 4)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
