import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/pagination_meta.dart';
import '../../../shared/widgets/app_filters.dart';
import '../../../shared/widgets/app_grouped_list.dart';
import '../../../shared/widgets/app_list_card.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/bank_account.dart';
import '../data/payment_model.dart';
import '../data/transfer_pending_args.dart';
import 'payment_providers.dart';

enum _PaymentFilter { all, pending, paid, failed }

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _search = TextEditingController();
  _PaymentFilter _filter = _PaymentFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(paymentsProvider);
    await ref.read(paymentsProvider.future);
  }

  List<Payment> _visible(List<Payment> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((payment) {
      if (!_matches(payment.status, _filter)) return false;
      return matchesSearch(query, [
        payment.reference,
        payment.method,
        payment.gateway,
        payment.gatewayReference,
      ]);
    }).toList();
  }

  List<AppFilterOption<_PaymentFilter>> _options(I18nBundle i18n, List<Payment> items) {
    int count(_PaymentFilter filter) => items.where((item) => _matches(item.status, filter)).length;
    return [
      AppFilterOption(
        value: _PaymentFilter.all,
        label: i18n.t('common.filterAll'),
        icon: Icons.apps_rounded,
        count: count(_PaymentFilter.all),
      ),
      AppFilterOption(
        value: _PaymentFilter.pending,
        label: i18n.status('pending'),
        icon: Icons.hourglass_empty_rounded,
        count: count(_PaymentFilter.pending),
      ),
      AppFilterOption(
        value: _PaymentFilter.paid,
        label: i18n.status('paid'),
        icon: Icons.check_circle_outline,
        count: count(_PaymentFilter.paid),
      ),
      AppFilterOption(
        value: _PaymentFilter.failed,
        label: i18n.status('failed'),
        icon: Icons.error_outline,
        count: count(_PaymentFilter.failed),
      ),
    ];
  }

  void _clear() {
    setState(() {
      _filter = _PaymentFilter.all;
      _search.clear();
    });
  }

  Future<void> _openReceipt(Payment payment) async {
    await context.push(
      '/payments/transfer',
      extra: TransferPendingArgs(
        paymentId: payment.id,
        reference: payment.reference ?? '',
        bankAccount: const BankAccount(),
        receiptUploaded: payment.hasReceipt,
      ),
    );
    if (!mounted) return;
    ref.invalidate(paymentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final value = ref.watch(paymentsProvider);

    return PageScrollView(
      child: AsyncBody<PagedResult<Payment>>(
      value: value,
      i18n: i18n,
      onRetry: () => ref.invalidate(paymentsProvider),
      onRefresh: _refresh,
      isEmpty: (data) => data.items.isEmpty,
      emptyTitle: i18n.t('payment.empty'),
      emptyIcon: Icons.payments_outlined,
      builder: (page) {
        final visible = _visible(page.items);
        final wide = context.isDesktop;
        final toolbar = _PaymentsToolbar(
          wide: wide,
          i18n: i18n,
          search: _search,
          onSearchChanged: () => setState(() {}),
          options: _options(i18n, page.items),
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
                AppFilterEmpty(i18n: i18n, onClear: _clear),
              ],
            ),
          );
        }

        if (wide) {
          return ContentWidth(
            child: PageList(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                toolbar,
                const SizedBox(height: 16),
                _PaymentsLedger(
                  i18n: i18n,
                  payments: visible,
                  onUpload: _openReceipt,
                ),
              ],
            ),
          );
        }

        return AppGroupedListView<Payment>(
          header: toolbar,
          padding: context.contentPadding,
          items: visible,
          itemBuilder: (context, payment) {
            return AppListCard(
              embedded: true,
              title: payment.reference ?? i18n.t('payment.title'),
              subtitle: _methodLabel(i18n, payment.method),
              subtitleWidget: payment.canUploadReceipt
                  ? _ReceiptAction(
                      method: _methodLabel(i18n, payment.method),
                      label: i18n.t(payment.hasReceipt ? 'payment.changeReceipt' : 'payment.uploadReceipt'),
                    )
                  : null,
              meta: formatAmount(payment.amount, currency: payment.currency ?? 'OMR'),
              trailing: StatusBadge(status: payment.status ?? '', label: i18n.status(payment.status)),
              onTap: payment.canUploadReceipt ? () => _openReceipt(payment) : null,
            );
          },
        );
      },
      ),
    );
  }
}

class _PaymentsToolbar extends StatelessWidget {
  const _PaymentsToolbar({
    required this.wide,
    required this.i18n,
    required this.search,
    required this.onSearchChanged,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final bool wide;
  final I18nBundle i18n;
  final TextEditingController search;
  final VoidCallback onSearchChanged;
  final List<AppFilterOption<_PaymentFilter>> options;
  final _PaymentFilter selected;
  final ValueChanged<_PaymentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final field = AppSearchField(
      controller: search,
      i18n: i18n,
      hint: i18n.t('payment.searchHint'),
      onChanged: onSearchChanged,
    );
    final filters = AppFilterBar<_PaymentFilter>(
      options: options,
      selected: selected,
      onSelected: onSelected,
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: 12),
          filters,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 360, child: field),
        const SizedBox(width: 16),
        Flexible(child: filters),
      ],
    );
  }
}

class _PaymentsLedger extends StatelessWidget {
  const _PaymentsLedger({
    required this.i18n,
    required this.payments,
    required this.onUpload,
  });

  final I18nBundle i18n;
  final List<Payment> payments;
  final ValueChanged<Payment> onUpload;

  @override
  Widget build(BuildContext context) {
    final header = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        );
    final showAction = payments.any((payment) => payment.canUploadReceipt);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.surface,
            child: _LedgerLine(
              showAction: showAction,
              reference: Text(i18n.t('common.reference'), style: header),
              amount: Text(i18n.t('common.amount'), style: header),
              method: Text(i18n.t('common.method'), style: header),
              status: Text(i18n.t('common.status'), style: header),
              date: Text(i18n.t('payment.paidAt'), style: header),
            ),
          ),
          for (var index = 0; index < payments.length; index++) ...[
            const Divider(height: 1),
            _LedgerPaymentRow(
              i18n: i18n,
              payment: payments[index],
              showAction: showAction,
              onUpload: payments[index].canUploadReceipt ? () => onUpload(payments[index]) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerPaymentRow extends StatelessWidget {
  const _LedgerPaymentRow({
    required this.i18n,
    required this.payment,
    required this.showAction,
    required this.onUpload,
  });

  final I18nBundle i18n;
  final Payment payment;
  final bool showAction;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final method = _methodLabel(i18n, payment.method);
    final gateway = _gatewayNote(i18n, payment);
    final amount = formatAmount(payment.amount, currency: payment.currency ?? 'OMR');
    final when = formatDateTime(payment.paidAt, locale: i18n.locale.languageCode);
    final action = onUpload == null
        ? null
        : i18n.t(payment.hasReceipt ? 'payment.changeReceipt' : 'payment.uploadReceipt');

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onUpload,
        onHover: (_) {},
        mouseCursor: onUpload == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        hoverColor: AppColors.mist,
        child: _LedgerLine(
          showAction: showAction,
          reference: Text(
            payment.reference ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          amount: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          method: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                method,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              if (gateway != null) ...[
                const SizedBox(height: 2),
                Text(
                  gateway,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          status: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusBadge(status: payment.status ?? '', label: i18n.status(payment.status)),
          ),
          date: Text(
            when,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.35),
          ),
          action: action == null
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: onUpload,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: AlignmentDirectional.centerEnd,
                  ),
                  child: Text(action, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
        ),
      ),
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({
    required this.showAction,
    required this.reference,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.action,
  });

  final bool showAction;
  final Widget reference;
  final Widget amount;
  final Widget method;
  final Widget status;
  final Widget date;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 20, 14),
      child: Row(
        children: [
          Expanded(flex: 20, child: reference),
          Expanded(flex: 16, child: amount),
          Expanded(flex: 22, child: method),
          Expanded(flex: 16, child: status),
          Expanded(flex: 20, child: date),
          if (showAction)
            SizedBox(
              width: 148,
              child: Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ),
        ],
      ),
    );
  }
}

class _ReceiptAction extends StatelessWidget {
  const _ReceiptAction({required this.method, required this.label});

  final String? method;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (method != null && method!.isNotEmpty)
          Text(
            method!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.35),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: text.labelLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

String _methodLabel(I18nBundle i18n, String? method) {
  if (method == null || method.trim().isEmpty) return '—';
  final key = 'payment.method.$method';
  final label = i18n.t(key);
  if (label == key) return method.replaceAll('_', ' ');
  return label;
}

String? _gatewayNote(I18nBundle i18n, Payment payment) {
  final gateway = payment.gateway?.trim();
  if (gateway == null || gateway.isEmpty || gateway == payment.method) return null;
  final reference = payment.gatewayReference?.trim();
  final label = _methodLabel(i18n, gateway);
  if (reference == null || reference.isEmpty) return label;
  return '$label · $reference';
}

bool _matches(String? status, _PaymentFilter filter) {
  return switch (filter) {
    _PaymentFilter.all => true,
    _PaymentFilter.pending => status == 'pending' || status == 'processing',
    _PaymentFilter.paid => status == 'paid',
    _PaymentFilter.failed => status == 'failed' || status == 'refunded',
  };
}
