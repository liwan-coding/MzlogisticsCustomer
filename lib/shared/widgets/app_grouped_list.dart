import 'package:flutter/material.dart';

import 'app_appear.dart';
import 'page_scroll.dart';

class AppGroupedListView<T> extends StatelessWidget {
  const AppGroupedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
    this.header,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function()? onRefresh;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return PageList(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      onRefresh: onRefresh,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 12),
        ],
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                AppAppear(index: index, child: itemBuilder(context, items[index])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppTableCard extends StatelessWidget {
  const AppTableCard({
    super.key,
    required this.child,
    this.onRefresh,
    this.header,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return PageList(
      physics: const AlwaysScrollableScrollPhysics(),
      onRefresh: onRefresh,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 16),
        ],
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
