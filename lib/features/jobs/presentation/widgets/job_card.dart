import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_glyph.dart';
import '../../../../shared/widgets/app_route_line.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/job_model.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.i18n,
    required this.job,
  });

  final I18nBundle i18n;
  final TransportJob job;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locale = i18n.locale.languageCode;
    final status = job.status ?? '';
    final shipment = job.shipment;
    final cargo = shipment?.cargoType?.trim();
    final reference = job.reference?.trim();
    final title = (cargo != null && cargo.isNotEmpty)
        ? cargo
        : (reference != null && reference.isNotEmpty)
            ? reference
            : i18n.t('job.detail');
    final showReference = cargo != null &&
        cargo.isNotEmpty &&
        reference != null &&
        reference.isNotEmpty;
    final from = shipment?.pickupCity ?? shipment?.pickupAddress;
    final to = shipment?.deliveryCity ?? shipment?.deliveryAddress;
    final provider = job.provider?.displayName(locale);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/jobs/${job.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.statusForeground(status).withValues(alpha: 0.85),
              child: const SizedBox(height: 3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppGlyph(
                        icon: jobStatusIcon(status),
                        size: 44,
                        iconSize: 22,
                        tone: jobStatusTone(status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (showReference) ...[
                              const SizedBox(height: 2),
                              Text(
                                reference,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelMedium?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: StatusBadge(status: status, label: i18n.status(status)),
                      ),
                    ],
                  ),
                  if (from != null || to != null) ...[
                    const SizedBox(height: 14),
                    AppRoutePanel(
                      fromLabel: i18n.t('common.pickup'),
                      toLabel: i18n.t('common.delivery'),
                      from: from ?? '—',
                      to: to ?? '—',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (provider != null && provider.isNotEmpty)
                        _FactChip(
                          icon: Icons.handshake_outlined,
                          label: provider,
                        ),
                      _FactChip(
                        icon: Icons.alt_route_outlined,
                        label: i18n.t('job.tripsCount', {'count': '${job.trips.length}'}),
                      ),
                      _FactChip(
                        icon: Icons.payments_outlined,
                        label: formatAmount(job.totalPrice, currency: job.currency ?? 'OMR'),
                        emphasize: status == 'in_progress',
                      ),
                      if (status == 'pending_dispatch')
                        _FactChip(
                          icon: Icons.hourglass_empty_rounded,
                          label: i18n.t('job.waitingDispatch'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasize ? AppColors.amberSoft : AppColors.mist,
        borderRadius: BorderRadius.circular(20),
        border: emphasize
            ? Border.all(color: AppColors.accentFrom.withValues(alpha: 0.55))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasize ? AppColors.orange : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: emphasize ? AppColors.orange : AppColors.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData jobStatusIcon(String? status) {
  return switch (status) {
    'pending_dispatch' => Icons.hourglass_top_rounded,
    'in_progress' => Icons.local_shipping_rounded,
    'completed' => Icons.verified_rounded,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.assignment_outlined,
  };
}

AppGlyphTone jobStatusTone(String? status) {
  return switch (status) {
    'pending_dispatch' => AppGlyphTone.muted,
    'in_progress' => AppGlyphTone.navy,
    'completed' => AppGlyphTone.success,
    'cancelled' => AppGlyphTone.danger,
    _ => AppGlyphTone.navy,
  };
}
