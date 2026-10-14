import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/pagination_meta.dart';
import '../../../shared/widgets/app_filters.dart';
import '../../../shared/widgets/app_grouped_list.dart';
import '../../../shared/widgets/app_list_card.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';
import 'notification_providers.dart';

enum _NotificationFilter { all, unread, read }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _search = TextEditingController();
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  List<AppNotification> _visible(List<AppNotification> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((item) {
      if (!_matches(item, _filter)) return false;
      return matchesSearch(query, [item.title, item.body, item.type]);
    }).toList();
  }

  List<AppFilterOption<_NotificationFilter>> _options(
    I18nBundle i18n,
    List<AppNotification> items,
  ) {
    int count(_NotificationFilter filter) => items.where((item) => _matches(item, filter)).length;
    return [
      AppFilterOption(
        value: _NotificationFilter.all,
        label: i18n.t('common.filterAll'),
        icon: Icons.apps_rounded,
        count: count(_NotificationFilter.all),
      ),
      AppFilterOption(
        value: _NotificationFilter.unread,
        label: i18n.t('notification.unread'),
        icon: Icons.mark_email_unread_outlined,
        count: count(_NotificationFilter.unread),
      ),
      AppFilterOption(
        value: _NotificationFilter.read,
        label: i18n.t('notification.read'),
        icon: Icons.mark_email_read_outlined,
        count: count(_NotificationFilter.read),
      ),
    ];
  }

  void _clear() {
    setState(() {
      _filter = _NotificationFilter.all;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final value = ref.watch(notificationsProvider);

    return PageScaffold(
      title: i18n.t('notification.title'),
      showBack: true,
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(notificationRepositoryProvider).markAllRead();
            ref.invalidate(notificationsProvider);
          },
          child: Text(i18n.t('notification.markAll')),
        ),
      ],
      body: ContentWidth(
        child: AsyncBody<PagedResult<AppNotification>>(
          value: value,
          i18n: i18n,
          onRetry: () => ref.invalidate(notificationsProvider),
          onRefresh: _refresh,
          isEmpty: (data) => data.items.isEmpty,
          emptyTitle: i18n.t('notification.empty'),
          emptyIcon: Icons.notifications_none,
          builder: (page) {
            final visible = _visible(page.items);
            final toolbar = AppListToolbar<_NotificationFilter>(
              i18n: i18n,
              search: _search,
              searchHint: i18n.t('notification.searchHint'),
              onSearchChanged: () => setState(() {}),
              options: _options(i18n, page.items),
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            );

            if (visible.isEmpty) {
              return PageList(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  toolbar,
                  const SizedBox(height: 24),
                  AppFilterEmpty(i18n: i18n, onClear: _clear),
                ],
              );
            }

            return AppGroupedListView<AppNotification>(
              header: toolbar,
              padding: EdgeInsets.zero,
              items: visible,
              itemBuilder: (context, item) {
                return AppListCard(
                  embedded: true,
                  highlighted: item.isUnread,
                  title: item.title ?? i18n.t('notification.title'),
                  subtitle: item.body,
                  meta: formatDateTime(item.createdAt, locale: i18n.locale.languageCode),
                  showChevron: false,
                  trailing: item.isUnread
                      ? IconButton(
                          tooltip: i18n.t('notification.markRead'),
                          onPressed: () async {
                            await ref.read(notificationRepositoryProvider).markRead(item.id);
                            ref.invalidate(notificationsProvider);
                          },
                          icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.navy),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

bool _matches(AppNotification item, _NotificationFilter filter) {
  return switch (filter) {
    _NotificationFilter.all => true,
    _NotificationFilter.unread => item.isUnread,
    _NotificationFilter.read => !item.isUnread,
  };
}
