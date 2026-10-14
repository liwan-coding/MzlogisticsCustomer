import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n_controller.dart';
import '../../core/theme/app_colors.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';
import 'page_scroll.dart';

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.i18n,
    required this.builder,
    this.onRetry,
    this.onRefresh,
    this.isEmpty,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
  });

  final AsyncValue<T> value;
  final I18nBundle i18n;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final bool Function(T data)? isEmpty;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    final content = value.when(
      loading: () => LoadingState(label: i18n.t('common.loading')),
      error: (error, _) => ErrorState(
        i18n: i18n,
        error: error,
        onRetry: onRetry,
      ),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return EmptyState(
            title: emptyTitle ?? i18n.t('common.empty'),
            message: emptyMessage,
            icon: emptyIcon,
            action: emptyAction,
          );
        }
        return builder(data);
      },
    );

    if (PageScrollMark.maybeOf(context) != null) {
      if (onRefresh != null && !value.isLoading) {
        PageRefresh.maybeOf(context)?.report(onRefresh);
      }
      return content;
    }

    if (onRefresh == null || value.isLoading) return content;

    final scrollable = value.hasValue && !(isEmpty?.call(value.requireValue) ?? false);
    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: onRefresh!,
      child: scrollable
          ? content
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: content,
                ),
              ],
            ),
    );
  }
}
