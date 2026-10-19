import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/models/pagination_meta.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_filters.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../data/shipment_model.dart';
import 'shipment_providers.dart';
import 'widgets/shipment_card.dart';

enum _ShipmentFilter { all, draft, published, awarded, closed }

class ShipmentsListScreen extends ConsumerStatefulWidget {
  const ShipmentsListScreen({super.key});

  @override
  ConsumerState<ShipmentsListScreen> createState() => _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends ConsumerState<ShipmentsListScreen> {
  final _search = TextEditingController();
  _ShipmentFilter _filter = _ShipmentFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(shipmentsProvider);
    await ref.read(shipmentsProvider.future);
  }

  List<ShipmentRequest> _visible(List<ShipmentRequest> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((item) {
      if (!_matchesFilter(item.status, _filter)) return false;
      return matchesSearch(query, [
        item.reference,
        item.cargoType,
        item.pickupCity,
        item.deliveryCity,
        item.pickupAddress,
        item.deliveryAddress,
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final value = ref.watch(shipmentsProvider);

    return PageScrollView(
      child: AsyncBody<PagedResult<ShipmentRequest>>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(shipmentsProvider),
        onRefresh: _refresh,
        isEmpty: (data) => data.items.isEmpty,
        emptyTitle: i18n.t('shipment.empty'),
        emptyMessage: i18n.t('home.emptyHint'),
        emptyIcon: Icons.inventory_2_outlined,
        emptyAction: AppButton(
          label: i18n.t('shipment.create'),
          icon: Icons.add_rounded,
          onPressed: () => context.push('/shipments/new'),
        ),
        builder: (page) {
          final visible = _visible(page.items);
          final columns = context.isDesktop ? (context.isWide ? 3 : 2) : 1;
          final count = visible.isEmpty ? 0 : (visible.length / columns).ceil();
          return ContentWidth(
            padding: context.contentPadding,
            child: PageList(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppButton(
                  label: i18n.t('shipment.create'),
                  icon: Icons.add_rounded,
                  expanded: context.isMobile,
                  onPressed: () => context.push('/shipments/new'),
                ),
                const SizedBox(height: 12),
                AppListToolbar<_ShipmentFilter>(
                  i18n: i18n,
                  search: _search,
                  searchHint: i18n.t('shipment.searchHint'),
                  onSearchChanged: () => setState(() {}),
                  options: [
                    AppFilterOption(
                      value: _ShipmentFilter.all,
                      label: i18n.t('common.filterAll'),
                      icon: Icons.apps_rounded,
                      count: page.items.length,
                    ),
                    AppFilterOption(
                      value: _ShipmentFilter.draft,
                      label: i18n.status('draft'),
                      icon: Icons.edit_note_rounded,
                      count: page.items.where((item) => _matchesFilter(item.status, _ShipmentFilter.draft)).length,
                    ),
                    AppFilterOption(
                      value: _ShipmentFilter.published,
                      label: i18n.status('published'),
                      icon: Icons.campaign_rounded,
                      count: page.items.where((item) => _matchesFilter(item.status, _ShipmentFilter.published)).length,
                    ),
                    AppFilterOption(
                      value: _ShipmentFilter.awarded,
                      label: i18n.status('awarded'),
                      icon: Icons.workspace_premium_rounded,
                      count: page.items.where((item) => _matchesFilter(item.status, _ShipmentFilter.awarded)).length,
                    ),
                    AppFilterOption(
                      value: _ShipmentFilter.closed,
                      label: i18n.t('common.filterClosed'),
                      icon: Icons.block_rounded,
                      count: page.items.where((item) => _matchesFilter(item.status, _ShipmentFilter.closed)).length,
                    ),
                  ],
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  AppFilterEmpty(
                    i18n: i18n,
                    onClear: () {
                      setState(() {
                        _filter = _ShipmentFilter.all;
                        _search.clear();
                      });
                    },
                  )
                else
                  for (var index = 0; index < count; index++)
                    Padding(
                      padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
                      child: EqualCardRow(
                        gap: 12,
                        children: [
                          for (var column = 0; column < columns; column++)
                            _shipmentCell(i18n, visible, index * columns + column),
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

  Widget _shipmentCell(I18nBundle i18n, List<ShipmentRequest> visible, int itemIndex) {
    if (itemIndex >= visible.length) return const SizedBox.shrink();
    return _Appear(
      index: itemIndex,
      child: ShipmentCard(i18n: i18n, shipment: visible[itemIndex]),
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

bool _matchesFilter(String? status, _ShipmentFilter filter) {
  return switch (filter) {
    _ShipmentFilter.all => true,
    _ShipmentFilter.draft => status == 'draft',
    _ShipmentFilter.published => status == 'published',
    _ShipmentFilter.awarded => status == 'awarded',
    _ShipmentFilter.closed => status == 'cancelled' || status == 'expired',
  };
}
