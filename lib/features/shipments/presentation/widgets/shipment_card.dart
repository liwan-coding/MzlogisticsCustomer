import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_glyph.dart';
import '../../../../shared/widgets/app_route_line.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/quantity_units.dart';
import '../../data/shipment_model.dart';

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.i18n,
    required this.shipment,
    this.compact = false,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locale = i18n.locale.languageCode;
    final status = shipment.status ?? '';
    final quotes = shipment.usesAdminSelection
        ? 0
        : (shipment.quotationsCount ?? shipment.quotations.length);
    final platformOffer = shipment.platformOffer;
    final cargo = shipment.cargoType?.trim();
    final reference = shipment.reference?.trim();
    final title = (cargo != null && cargo.isNotEmpty)
        ? cargo
        : (reference != null && reference.isNotEmpty)
            ? reference
            : i18n.t('shipment.detail');
    final showReference = cargo != null &&
        cargo.isNotEmpty &&
        reference != null &&
        reference.isNotEmpty;
    final tone = shipmentStatusTone(status);
    final from = shipment.pickupCity ?? shipment.pickupAddress ?? '—';
    final to = shipment.deliveryCity ?? shipment.deliveryAddress ?? '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/shipments/${shipment.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.statusForeground(status).withValues(alpha: 0.85),
              child: const SizedBox(height: 3),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, compact ? 12 : 14, 12, compact ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppGlyph(
                        icon: shipmentStatusIcon(status),
                        size: compact ? 40 : 44,
                        iconSize: compact ? 20 : 22,
                        tone: tone,
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
                  SizedBox(height: compact ? 10 : 14),
                  if (compact)
                    AppRouteLine(
                      from: from,
                      to: to,
                      fromLabel: i18n.t('common.pickup'),
                      toLabel: i18n.t('common.delivery'),
                    )
                  else
                    AppRoutePanel(
                      fromLabel: i18n.t('common.pickup'),
                      toLabel: i18n.t('common.delivery'),
                      from: from,
                      to: to,
                    ),
                  SizedBox(height: compact ? 10 : 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FactChip(
                        icon: Icons.inventory_2_outlined,
                        label: QuantityUnits.cargoSummary(
                          i18n,
                          weightTons: shipment.weightTons,
                          quantity: shipment.quantity,
                          unit: shipment.quantityUnit,
                        ),
                      ),
                      _FactChip(
                        icon: Icons.event_outlined,
                        label: formatDate(shipment.requiredDate, locale: locale),
                      ),
                      if (shipment.usesAdminSelection && platformOffer?.customerPrice != null)
                        _FactChip(
                          icon: Icons.request_quote_outlined,
                          label: formatAmount(
                            platformOffer!.customerPrice,
                            currency: platformOffer.currency ?? 'OMR',
                          ),
                          emphasize: status == 'published',
                        )
                      else if (!shipment.usesAdminSelection && quotes > 0)
                        _FactChip(
                          icon: Icons.request_quote_outlined,
                          label: i18n.t('shipment.quotationsCount', {'count': '$quotes'}),
                          emphasize: status == 'published',
                        )
                      else if (!shipment.usesAdminSelection && status == 'published')
                        _FactChip(
                          icon: Icons.hourglass_empty_rounded,
                          label: i18n.t('shipment.waitingQuotes'),
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

IconData shipmentStatusIcon(String? status) {
  return switch (status) {
    'draft' => Icons.edit_note_rounded,
    'published' => Icons.campaign_rounded,
    'awarded' => Icons.workspace_premium_rounded,
    'cancelled' => Icons.cancel_outlined,
    'expired' => Icons.timer_off_outlined,
    _ => Icons.inventory_2_outlined,
  };
}

AppGlyphTone shipmentStatusTone(String? status) {
  return switch (status) {
    'published' => AppGlyphTone.navy,
    'awarded' => AppGlyphTone.success,
    'cancelled' || 'expired' => AppGlyphTone.danger,
    'draft' => AppGlyphTone.muted,
    _ => AppGlyphTone.navy,
  };
}
