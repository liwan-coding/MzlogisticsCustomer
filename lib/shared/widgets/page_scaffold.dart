import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import 'app_header.dart';
import 'hero_title_scope.dart';
import 'page_scroll.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.showBack,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool? showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scope = HeroTitleScope.maybeOf(context);
    if (context.isDesktop && scope != null) {
      final data = HeroTitleData(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showBack: showBack,
        onBack: onBack,
      );
      final titles = scope.controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        titles.publish(data);
      });
      final page = PageScrollView(child: body);
      if (floatingActionButton == null) return page;
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: floatingActionButton,
        body: page,
      );
    }

    if (context.isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        floatingActionButton: floatingActionButton,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentWidth(
              padding: const EdgeInsets.fromLTRB(40, 4, 40, 0),
              child: PageHeading(
                title: title,
                subtitle: subtitle,
                actions: actions,
                showBack: showBack,
                onBack: onBack,
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showBack: showBack,
        onBack: onBack,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack,
    this.onBack,
    this.onHero = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool? showBack;
  final VoidCallback? onBack;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final back = showBack ?? context.canPop();
    final text = Theme.of(context).textTheme;
    final titleColor = onHero ? Colors.white : AppColors.ink;
    final subtitleColor = onHero ? const Color(0xFFE4EAF2) : AppColors.muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (back)
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const BackButtonIcon(),
            color: titleColor,
            onPressed: onBack ?? () => popToParent(context),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: subtitleColor),
                ),
              ],
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: 12),
          IconTheme(
            data: IconThemeData(color: titleColor),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
              child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ),
          ),
        ],
      ],
    );
  }
}

class DesktopPair extends StatelessWidget {
  const DesktopPair({
    super.key,
    required this.primary,
    required this.secondary,
    this.gap = 16,
    this.splitAt = 760,
  });

  final Widget primary;
  final Widget secondary;
  final double gap;
  final double splitAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth < splitAt) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              SizedBox(height: gap),
              secondary,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: primary),
            SizedBox(width: gap),
            Expanded(flex: 5, child: secondary),
          ],
        );
      },
    );
  }
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? context.contentMaxWidth;
    final insets = padding ?? context.contentPadding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final raw = constraints.maxWidth - insets.horizontal;
        final available = raw < 0 ? 0.0 : raw;
        final width = available < cap ? available : cap;
        final bounded = constraints.maxHeight.isFinite;
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(left: insets.left, right: insets.right),
            child: SizedBox(
              width: width,
              height: bounded ? constraints.maxHeight : null,
              child: Padding(
                padding: EdgeInsets.only(top: insets.top, bottom: insets.bottom),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
