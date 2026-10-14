import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_glyph.dart';
import '../../../shared/widgets/app_list_card.dart';
import '../../../shared/widgets/app_progress.dart';
import '../../../shared/widgets/app_route_line.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_summary_card.dart';
import '../../../shared/widgets/info_row.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../payments/presentation/widgets/payment_terms_readout.dart';
import '../../invoices/presentation/invoice_payment_flow.dart';
import '../../trips/data/customer_trip_progress.dart';
import '../../trips/presentation/widgets/trip_status.dart';
import '../data/job_model.dart';
import 'job_providers.dart';
import 'widgets/job_card.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final value = ref.watch(jobDetailProvider(jobId));

    return PageScaffold(
      title: i18n.t('job.detail'),
      showBack: true,
      body: AsyncBody<TransportJob>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        onRefresh: () async {
          ref.invalidate(jobDetailProvider(jobId));
          await ref.read(jobDetailProvider(jobId).future);
        },
        builder: (job) {
          final locale = i18n.locale.languageCode;
          final status = job.status ?? '';
          final cargo = job.shipment?.cargoType?.trim();
          final reference = job.reference?.trim();
          final title = (cargo != null && cargo.isNotEmpty)
              ? cargo
              : (reference != null && reference.isNotEmpty)
                  ? reference
                  : i18n.t('job.detail');
          final from = job.shipment?.pickupCity ?? job.shipment?.pickupAddress;
          final to = job.shipment?.deliveryCity ?? job.shipment?.deliveryAddress;

          return ContentWidth(
            child: PageList(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DesktopPair(
                  primary: AppAppear(
                  index: 0,
                  child: EntitySummaryCard(
                    title: title,
                    subtitle: cargo != null && cargo.isNotEmpty ? reference : i18n.t('job.hint'),
                    icon: jobStatusIcon(status),
                    tone: jobStatusTone(status),
                    accent: AppColors.statusForeground(status).withValues(alpha: 0.85),
                    badge: StatusBadge(status: status, label: i18n.status(status)),
                    facts: [
                      EntityFact(
                        i18n.t('common.provider'),
                        job.provider?.displayName(locale) ?? '—',
                        icon: Icons.handshake_outlined,
                      ),
                      EntityFact(
                        i18n.t('common.amount'),
                        formatAmount(job.totalPrice, currency: job.currency ?? 'OMR'),
                        icon: Icons.payments_outlined,
                      ),
                      EntityFact(
                        i18n.t('job.trips'),
                        i18n.t('job.tripsCount', {'count': '${job.trips.length}'}),
                        icon: Icons.alt_route_outlined,
                      ),
                      if (job.shipment != null)
                        EntityFact(
                          i18n.t('paymentContract.title'),
                          job.shipment!.paymentTerms.label(i18n),
                          icon: Icons.event_available_outlined,
                        ),
                    ],
                    footer: from != null || to != null
                        ? AppRoutePanel(
                            fromLabel: i18n.t('common.pickup'),
                            toLabel: i18n.t('common.delivery'),
                            from: from ?? '—',
                            to: to ?? '—',
                          )
                        : null,
                  ),
                ),
                  secondary: Column(
                    children: [
                AppAppear(
                  index: 1,
                  child: SectionCard(
                    title: i18n.t('job.progress'),
                    icon: Icons.bolt_rounded,
                    child: AppStatusStepper(
                      steps: [
                        AppStepItem(
                          id: 'pending_dispatch',
                          label: i18n.status('pending_dispatch'),
                          icon: Icons.hourglass_top_rounded,
                        ),
                        AppStepItem(
                          id: 'in_progress',
                          label: i18n.status('in_progress'),
                          icon: Icons.local_shipping_rounded,
                        ),
                        AppStepItem(
                          id: 'completed',
                          label: i18n.status('completed'),
                          icon: Icons.verified_rounded,
                        ),
                      ],
                      currentId: _jobStep(job.status),
                      failed: job.status == 'cancelled',
                    ),
                  ),
                ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppAppear(
                  index: 2,
                  child: SectionCard(
                    title: i18n.t('job.trips'),
                    icon: Icons.alt_route_rounded,
                    child: job.trips.isEmpty
                        ? Text(i18n.t('job.noTrips'), style: const TextStyle(color: AppColors.muted))
                        : Column(
                            children: [
                              for (var index = 0; index < job.trips.length; index++) ...[
                                if (index > 0) const Divider(height: 1, indent: 4, endIndent: 4),
                                AppListCard(
                                  embedded: true,
                                  onTap: () => context.push('/trips/${job.trips[index].id}'),
                                  leading: AppGlyph(
                                    icon: tripStatusIcon(job.trips[index].status),
                                    size: 40,
                                    iconSize: 20,
                                    tone: tripStatusTone(job.trips[index].status),
                                  ),
                                  title: job.trips[index].reference ??
                                      i18n.t('trip.sequence', {'n': '${job.trips[index].sequence ?? ''}'}),
                                  subtitleWidget: AppRouteLine(
                                    from: job.trips[index].pickupCity ??
                                        job.trips[index].pickupAddress ??
                                        '—',
                                    to: job.trips[index].deliveryCity ??
                                        job.trips[index].deliveryAddress ??
                                        '—',
                                    fromLabel: i18n.t('common.pickup'),
                                    toLabel: i18n.t('common.delivery'),
                                  ),
                                  trailing: StatusBadge(
                                    status: CustomerTripProgress.stageOf(
                                      job.trips[index].status,
                                    ),
                                    label: customerTripStageLabel(
                                      i18n,
                                      job.trips[index].status,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                if (job.shipment != null) ...[
                  const SizedBox(height: 16),
                  AppAppear(
                    index: 3,
                    child: SectionCard(
                      title: i18n.t('paymentContract.title'),
                      icon: Icons.payments_outlined,
                      child: PaymentTermsReadout(i18n: i18n, terms: job.shipment!.paymentTerms),
                    ),
                  ),
                ],
                if (job.shipment != null || job.payableInvoices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppAppear(
                    index: 4,
                    child: SectionCard(
                      title: i18n.t('common.actions'),
                      icon: Icons.touch_app_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final invoice in job.payableInvoices) ...[
                            AppButton(
                              label: invoice.tripReference == null
                                  ? i18n.t('invoice.pay')
                                  : i18n.t('invoice.payTrip', {'trip': invoice.tripReference!}),
                              icon: Icons.payments_outlined,
                              onPressed: () => startInvoicePayment(
                                context: context,
                                ref: ref,
                                invoice: invoice,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (job.shipment != null)
                            AppButton(
                              label: i18n.t('job.viewShipment'),
                              icon: Icons.inventory_2_outlined,
                              variant: job.payableInvoices.isNotEmpty
                                  ? AppButtonVariant.secondary
                                  : AppButtonVariant.primary,
                              onPressed: () => context.push('/shipments/${job.shipment!.id}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _jobStep(String? status) {
  return switch (status) {
    'in_progress' => 'in_progress',
    'completed' => 'completed',
    _ => 'pending_dispatch',
  };
}
