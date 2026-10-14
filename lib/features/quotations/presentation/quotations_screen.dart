import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/pagination_meta.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_filters.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_summary_card.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../shipments/data/shipment_model.dart';
import '../../shipments/presentation/shipment_providers.dart';
import '../data/quotation_model.dart';
import 'quotation_accept_flow.dart';
import 'quotation_providers.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

enum _QuotationFilter { all, submitted, accepted, closed }

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  final _search = TextEditingController();
  _QuotationFilter _filter = _QuotationFilter.all;
  bool _accepting = false;
  bool _leaving = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _comparisonClosed(
    ShipmentRequest? shipment,
    List<Quotation> quotations,
  ) {
    if (shipment != null && !shipment.canCompareQuotations) return true;
    final hasAccepted = quotations.any((quotation) => quotation.isAccepted);
    final hasSubmitted = quotations.any((quotation) => quotation.isSubmitted);
    return hasAccepted && !hasSubmitted;
  }

  void _leaveComparison() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/shipments/${widget.shipmentId}');
    });
  }

  Future<void> _accept(Quotation quotation) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await startQuotationAcceptance(
        context: context,
        ref: ref,
        quotation: quotation,
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  List<Quotation> _visible(List<Quotation> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((quotation) {
      if (!_matchesQuotation(quotation.status, _filter)) return false;
      return matchesSearch(query, [
        quotation.reference,
        quotation.provider?.name,
        quotation.provider?.nameAr,
        quotation.truckType,
        quotation.truckTypeLabel,
      ]);
    }).toList();
  }

  List<AppFilterOption<_QuotationFilter>> _quotationOptions(
    I18nBundle i18n,
    List<Quotation> items,
  ) {
    int count(_QuotationFilter filter) {
      return items
          .where((item) => _matchesQuotation(item.status, filter))
          .length;
    }

    return [
      AppFilterOption(
        value: _QuotationFilter.all,
        label: i18n.t('common.filterAll'),
        icon: Icons.apps_rounded,
        count: count(_QuotationFilter.all),
      ),
      AppFilterOption(
        value: _QuotationFilter.submitted,
        label: i18n.status('submitted'),
        icon: Icons.request_quote_outlined,
        count: count(_QuotationFilter.submitted),
      ),
      AppFilterOption(
        value: _QuotationFilter.accepted,
        label: i18n.status('accepted'),
        icon: Icons.check_circle_outline,
        count: count(_QuotationFilter.accepted),
      ),
      AppFilterOption(
        value: _QuotationFilter.closed,
        label: i18n.t('common.filterClosed'),
        icon: Icons.block_rounded,
        count: count(_QuotationFilter.closed),
      ),
    ];
  }

  bool _isBestPrice(List<Quotation> items, Quotation quotation) {
    final prices = items
        .map((item) => item.totalPrice)
        .whereType<double>()
        .toList();
    if (prices.isEmpty || quotation.totalPrice == null) return false;
    final lowest = prices.reduce((a, b) => a < b ? a : b);
    return quotation.totalPrice == lowest;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final shipmentValue = ref.watch(shipmentDetailProvider(widget.shipmentId));
    final value = ref.watch(quotationsByShipmentProvider(widget.shipmentId));
    final shipment = shipmentValue.asData?.value;
    final quotations = value.asData?.value.items ?? const <Quotation>[];

    if (_comparisonClosed(shipment, quotations)) {
      _leaveComparison();
      return PageScaffold(
        title: i18n.t('shipment.quoteAccepted'),
        showBack: true,
        body: LoadingState(label: i18n.t('common.loading')),
      );
    }

    return PageScaffold(
      title: i18n.t('quotation.compare'),
      showBack: true,
      body: AsyncBody<PagedResult<Quotation>>(
        value: value,
        i18n: i18n,
        onRetry: () =>
            ref.invalidate(quotationsByShipmentProvider(widget.shipmentId)),
        isEmpty: (data) => data.items.isEmpty,
        emptyTitle: i18n.t('quotation.empty'),
        emptyIcon: Icons.request_quote_outlined,
        builder: (page) {
          final items = page.items;
          if (_comparisonClosed(shipment, items)) {
            _leaveComparison();
            return LoadingState(label: i18n.t('common.loading'));
          }
          final visible = _visible(items);
          final toolbar = AppListToolbar<_QuotationFilter>(
            i18n: i18n,
            search: _search,
            searchHint: i18n.t('quotation.searchHint'),
            onSearchChanged: () => setState(() {}),
            options: _quotationOptions(i18n, items),
            selected: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          );

          if (visible.isEmpty) {
            return ContentWidth(
              child: PageList(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  toolbar,
                  const SizedBox(height: 24),
                  AppFilterEmpty(
                    i18n: i18n,
                    onClear: () => setState(() {
                      _filter = _QuotationFilter.all;
                      _search.clear();
                    }),
                  ),
                ],
              ),
            );
          }

          if (context.isDesktop) {
            return ContentWidth(
              child: PageList(
                children: [
                  toolbar,
                  const SizedBox(height: 16),
                  Text(
                    i18n.t('quotation.selectBest'),
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 16.0;
                      final columns = constraints.maxWidth >= 980 ? 3 : 2;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final quotation in visible)
                            SizedBox(
                              width: width,
                              child: _QuotationCard(
                                quotation: quotation,
                                i18n: i18n,
                                accepting: _accepting,
                                bestPrice: _isBestPrice(items, quotation),
                                onAccept: () => _accept(quotation),
                                onOpen: () =>
                                    context.push('/quotations/${quotation.id}'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return toolbar;
              final quotation = visible[index - 1];
              return _QuotationCard(
                quotation: quotation,
                i18n: i18n,
                accepting: _accepting,
                bestPrice: _isBestPrice(items, quotation),
                onAccept: () => _accept(quotation),
                onOpen: () => context.push('/quotations/${quotation.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

bool _showsTransportPrice(double? transport, double? total) {
  if (transport == null || total == null) {
    return false;
  }
  return (transport - total).abs() > 0.0005;
}

bool _matchesQuotation(String? status, _QuotationFilter filter) {
  return switch (filter) {
    _QuotationFilter.all => true,
    _QuotationFilter.submitted => status == 'submitted',
    _QuotationFilter.accepted => status == 'accepted',
    _QuotationFilter.closed => status == 'rejected' || status == 'withdrawn',
  };
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.quotation,
    required this.i18n,
    required this.accepting,
    required this.onAccept,
    this.onOpen,
    this.bestPrice = false,
  });

  final Quotation quotation;
  final I18nBundle i18n;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback? onOpen;
  final bool bestPrice;

  @override
  Widget build(BuildContext context) {
    final locale = i18n.locale.languageCode;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: bestPrice ? AppColors.amberSoft : AppColors.white,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: bestPrice ? AppColors.orange : AppColors.border,
              child: const SizedBox(height: 3),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quotation.provider?.displayName(locale) ??
                              quotation.reference ??
                              '—',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: StatusBadge(
                          status: quotation.status ?? '',
                          label: i18n.status(quotation.status),
                        ),
                      ),
                    ],
                  ),
                  if (bestPrice) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        i18n.t('quotation.bestPrice'),
                        style: const TextStyle(
                          color: AppColors.onNeon,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    formatAmount(
                      quotation.totalPrice,
                      currency: quotation.currency ?? 'OMR',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (quotation.pricePerTon != null || quotation.pricePerTrip != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      quotation.pricePerTon != null
                          ? '${i18n.t('quotation.pricePerTon')}: ${formatAmount(quotation.pricePerTon, currency: quotation.currency ?? 'OMR')}'
                          : '${i18n.t('quotation.pricePerTrip')}: ${formatAmount(quotation.pricePerTrip, currency: quotation.currency ?? 'OMR')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _line(
                    i18n.t('quotation.trucks'),
                    '${quotation.truckCount ?? '—'}',
                  ),
                  _line(
                    i18n.t('quotation.truckType'),
                    quotation.truckTypeLabel ?? quotation.truckType ?? '—',
                  ),
                  _line(
                    i18n.t('quotation.capacity'),
                    formatNumber(quotation.truckCapacityTons),
                  ),
                  _line(
                    i18n.t('quotation.trips'),
                    '${quotation.tripCount ?? '—'}',
                  ),
                  _line(
                    i18n.t('quotation.qtyPerTrip'),
                    formatNumber(quotation.quantityPerTrip),
                  ),
                  _line(
                    i18n.t('quotation.duration'),
                    '${quotation.durationDays ?? '—'}',
                  ),
                  _line(
                    i18n.t('quotation.transportStart'),
                    formatDate(quotation.transportStartDate, locale: locale),
                  ),
                  if (_showsTransportPrice(quotation.transportPrice, quotation.totalPrice))
                    _line(
                      i18n.t('quotation.transport'),
                      formatAmount(
                        quotation.transportPrice,
                        currency: quotation.currency ?? 'OMR',
                      ),
                    ),
                  _line(
                    i18n.t('quotation.extra'),
                    formatAmount(
                      quotation.additionalCosts,
                      currency: quotation.currency ?? 'OMR',
                    ),
                  ),
                  _line(
                    i18n.t('quotation.validUntil'),
                    formatDate(quotation.validUntil, locale: locale),
                  ),
                  if (quotation.conditions != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      quotation.conditions!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  if (quotation.canAccept) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: i18n.t('quotation.accept'),
                      expanded: true,
                      loading: accepting,
                      onPressed: accepting ? null : onAccept,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.quotationId});

  final int quotationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final value = ref.watch(quotationDetailProvider(quotationId));
    return PageScaffold(
      title: i18n.t('quotation.detail'),
      showBack: true,
      body: AsyncBody<Quotation>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(quotationDetailProvider(quotationId)),
        builder: (quotation) {
          final locale = i18n.locale.languageCode;
          final status = quotation.status ?? '';
          return ContentWidth(
            child: PageList(
              children: [
                AppAppear(
                  index: 0,
                  child: EntitySummaryCard(
                    title:
                        quotation.provider?.displayName(locale) ??
                        quotation.reference ??
                        i18n.t('quotation.detail'),
                    subtitle: quotation.reference,
                    icon: Icons.request_quote_rounded,
                    accent: AppColors.statusForeground(status)
                        .withValues(alpha: 0.85),
                    badge: StatusBadge(
                      status: status,
                      label: i18n.status(status),
                    ),
                    facts: [
                      if (quotation.pricePerTon != null)
                        EntityFact(
                          i18n.t('quotation.pricePerTon'),
                          formatAmount(
                            quotation.pricePerTon,
                            currency: quotation.currency ?? 'OMR',
                          ),
                          icon: Icons.scale_outlined,
                        )
                      else if (quotation.pricePerTrip != null)
                        EntityFact(
                          i18n.t('quotation.pricePerTrip'),
                          formatAmount(
                            quotation.pricePerTrip,
                            currency: quotation.currency ?? 'OMR',
                          ),
                          icon: Icons.route_outlined,
                        ),
                      EntityFact(
                        i18n.t('quotation.price'),
                        formatAmount(
                          quotation.totalPrice,
                          currency: quotation.currency ?? 'OMR',
                        ),
                        icon: Icons.payments_outlined,
                      ),
                      EntityFact(
                        i18n.t('quotation.trucks'),
                        '${quotation.truckCount ?? '—'}',
                        icon: Icons.local_shipping_outlined,
                      ),
                      EntityFact(
                        i18n.t('quotation.duration'),
                        '${quotation.durationDays ?? '—'}',
                        icon: Icons.schedule_outlined,
                      ),
                      EntityFact(
                        i18n.t('quotation.transportStart'),
                        formatDate(quotation.transportStartDate, locale: locale),
                        icon: Icons.event_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppAppear(
                  index: 1,
                  child: _QuotationCard(
                    quotation: quotation,
                    i18n: i18n,
                    accepting: false,
                    bestPrice: false,
                    onAccept: () => startQuotationAcceptance(
                      context: context,
                      ref: ref,
                      quotation: quotation,
                    ),
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
