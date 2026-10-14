import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Desktop pages insert this band as the first block of the page scroll.
class PageHeroScope extends InheritedWidget {
  const PageHeroScope({
    required this.band,
    required this.inline,
    required super.child,
  });

  final WidgetBuilder band;

  /// When false the host already placed the band above a filling child.
  final bool inline;

  static PageHeroScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageHeroScope>();
  }

  @override
  bool updateShouldNotify(PageHeroScope oldWidget) => inline != oldWidget.inline;
}

class PageScrollMark extends InheritedWidget {
  const PageScrollMark({required super.child});

  static PageScrollMark? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageScrollMark>();
  }

  @override
  bool updateShouldNotify(PageScrollMark oldWidget) => false;
}

class PageRefresh extends InheritedWidget {
  const PageRefresh({required this.report, required super.child});

  final void Function(Future<void> Function()? refresh) report;

  static PageRefresh? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageRefresh>();
  }

  @override
  bool updateShouldNotify(PageRefresh oldWidget) => false;
}

/// One vertical scroll for the hero and the page body.
///
/// Nested routes reuse the outer scroll instead of opening another viewport.
class PageScrollView extends StatefulWidget {
  const PageScrollView({super.key, required this.child});

  final Widget child;

  @override
  State<PageScrollView> createState() => _PageScrollViewState();
}

class _PageScrollViewState extends State<PageScrollView> {
  Future<void> Function()? _refresh;

  void _report(Future<void> Function()? refresh) {
    _refresh = refresh;
  }

  @override
  Widget build(BuildContext context) {
    final hero = PageHeroScope.maybeOf(context);
    if (hero == null || !hero.inline || PageScrollMark.maybeOf(context) != null) {
      return widget.child;
    }

    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: hero.band(context)),
        SliverToBoxAdapter(child: widget.child),
      ],
    );

    return PageRefresh(
      report: _report,
      child: PageScrollMark(
        child: RefreshIndicator(
          color: AppColors.navy,
          notificationPredicate: (notification) {
            return _refresh != null && defaultScrollNotificationPredicate(notification);
          },
          onRefresh: () => _refresh?.call() ?? Future<void>.value(),
          child: scroll,
        ),
      ),
    );
  }
}

/// List on a bounded page, plain column when the page itself is the scroll.
class PageList extends StatelessWidget {
  const PageList({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.onRefresh,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final onPage = PageScrollMark.maybeOf(context) != null;
    if (onPage && onRefresh != null) {
      PageRefresh.maybeOf(context)?.report(onRefresh);
    }
    if (onPage) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    final list = ListView(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: onRefresh!,
      child: list,
    );
  }
}
