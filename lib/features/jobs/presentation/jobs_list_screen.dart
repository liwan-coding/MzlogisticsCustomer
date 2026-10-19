import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/models/pagination_meta.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/app_filters.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../data/job_model.dart';
import 'job_providers.dart';
import 'widgets/job_card.dart';

enum _JobFilter { all, pending, active, completed }

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  final _search = TextEditingController();
  _JobFilter _filter = _JobFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(jobsProvider);
    await ref.read(jobsProvider.future);
  }

  List<TransportJob> _visible(List<TransportJob> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((job) {
      if (!_matches(job.status, _filter)) return false;
      return matchesSearch(query, [
        job.reference,
        job.provider?.name,
        job.provider?.nameAr,
        job.shipment?.cargoType,
        job.shipment?.reference,
        job.shipment?.pickupCity,
        job.shipment?.deliveryCity,
      ]);
    }).toList();
  }

  List<AppFilterOption<_JobFilter>> _options(I18nBundle i18n, List<TransportJob> items) {
    int count(_JobFilter filter) => items.where((job) => _matches(job.status, filter)).length;
    return [
      AppFilterOption(
        value: _JobFilter.all,
        label: i18n.t('common.filterAll'),
        icon: Icons.apps_rounded,
        count: count(_JobFilter.all),
      ),
      AppFilterOption(
        value: _JobFilter.pending,
        label: i18n.status('pending_dispatch'),
        icon: Icons.hourglass_top_rounded,
        count: count(_JobFilter.pending),
      ),
      AppFilterOption(
        value: _JobFilter.active,
        label: i18n.status('in_progress'),
        icon: Icons.local_shipping_outlined,
        count: count(_JobFilter.active),
      ),
      AppFilterOption(
        value: _JobFilter.completed,
        label: i18n.status('completed'),
        icon: Icons.verified_outlined,
        count: count(_JobFilter.completed),
      ),
    ];
  }

  void _clear() {
    setState(() {
      _filter = _JobFilter.all;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final value = ref.watch(jobsProvider);

    return PageScrollView(
      child: AsyncBody<PagedResult<TransportJob>>(
      value: value,
      i18n: i18n,
      onRetry: () => ref.invalidate(jobsProvider),
      onRefresh: _refresh,
      isEmpty: (data) => data.items.isEmpty,
      emptyTitle: i18n.t('job.empty'),
      emptyMessage: i18n.t('job.hint'),
      emptyIcon: Icons.assignment_outlined,
      builder: (page) {
        final visible = _visible(page.items);
        final columns = context.isDesktop ? (context.isWide ? 3 : 2) : 1;
        final count = (visible.length / columns).ceil();
        return ContentWidth(
          padding: context.contentPadding,
          child: PageList(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppListToolbar<_JobFilter>(
                i18n: i18n,
                search: _search,
                searchHint: i18n.t('job.searchHint'),
                onSearchChanged: () => setState(() {}),
                options: _options(i18n, page.items),
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                AppFilterEmpty(i18n: i18n, onClear: _clear)
              else
                for (var index = 0; index < count; index++)
                  Padding(
                    padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
                    child: EqualCardRow(
                      gap: 12,
                      children: [
                        for (var column = 0; column < columns; column++)
                          () {
                            final itemIndex = index * columns + column;
                            if (itemIndex >= visible.length) return const SizedBox.shrink();
                            return _Appear(
                              index: itemIndex,
                              child: JobCard(i18n: i18n, job: visible[itemIndex]),
                            );
                          }(),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
      ),
    );
  }
}

class _Appear extends StatelessWidget {
  const _Appear({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppAppear(index: index, child: child);
  }
}

bool _matches(String? status, _JobFilter filter) {
  return switch (filter) {
    _JobFilter.all => true,
    _JobFilter.pending => status == 'pending_dispatch',
    _JobFilter.active => status == 'in_progress',
    _JobFilter.completed => status == 'completed',
  };
}
