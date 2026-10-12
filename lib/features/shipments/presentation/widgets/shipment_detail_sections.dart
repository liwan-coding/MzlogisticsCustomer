import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glyph.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/location_preview.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../payments/presentation/widgets/payment_terms_readout.dart';
import '../../../quotations/data/quotation_model.dart';
import '../../data/quantity_units.dart';
import '../../data/shipment_model.dart';

const shipmentDetailSplitWidth = 760.0;

String shipmentNextMessage(I18nBundle i18n, ShipmentRequest shipment) {
  if (shipment.usesAdminSelection &&
      shipment.status == 'published' &&
      shipment.platformOffer == null) {
    return '';
  }
  if (shipment.usesAdminSelection && shipment.status == 'published') {
    return i18n.t('shipment.nextAdminReady');
  }
  final quotes = shipment.quotationsCount ?? shipment.quotations.length;
  return switch (shipment.status) {
    'draft' => i18n.t('shipment.nextDraft'),
    'published' => quotes > 0
        ? i18n.t('shipment.nextPublishedReady')
        : i18n.t('shipment.nextPublishedEmpty'),
    'awarded' => i18n.t('shipment.nextAwarded'),
    'cancelled' => i18n.t('shipment.nextCancelled'),
    'expired' => i18n.t('shipment.nextExpired'),
    _ => i18n.status(shipment.status),
  };
}

({String label, String value})? shipmentQuoteFact(
  I18nBundle i18n,
  ShipmentRequest shipment,
) {
  if (shipment.usesAdminSelection) {
    final offer = shipment.platformOffer;
    if (offer?.customerPrice == null) return null;
    return (
      label: i18n.t('shipment.platformOffer'),
      value: formatAmount(offer!.customerPrice, currency: offer.currency ?? 'OMR'),
    );
  }

  final quotes = shipment.quotationsCount ?? shipment.quotations.length;
  if (shipment.isAwarded) {
    Quotation? accepted;
    for (final quotation in shipment.awardedQuotations) {
      accepted ??= quotation;
      if (quotation.totalPrice != null) {
        accepted = quotation;
        break;
      }
    }
    return (
      label: i18n.t('shipment.awardedQuotation'),
      value: accepted?.totalPrice == null
          ? i18n.t('shipment.quoteAccepted')
          : formatAmount(
              accepted!.totalPrice,
              currency: accepted.currency ?? 'OMR',
            ),
    );
  }

  final label = i18n.t('shipment.quotationsCount', {'count': '$quotes'});
  if (quotes <= 0) {
    return (label: label, value: i18n.t('shipment.waitingQuotes'));
  }

  final priced = shipment.quotations
      .where((quotation) => quotation.totalPrice != null)
      .toList()
    ..sort((a, b) => a.totalPrice!.compareTo(b.totalPrice!));
  if (priced.isEmpty) {
    return (label: label, value: i18n.status(shipment.status));
  }

  final lowest = priced.first;
  final amount = formatAmount(
    lowest.totalPrice,
    currency: lowest.currency ?? 'OMR',
  );
  if (quotes == 1) return (label: label, value: amount);
  return (
    label: label,
    value: i18n.t('shipment.quotesFrom', {'amount': amount}),
  );
}

class ShipmentNextStep extends StatelessWidget {
  const ShipmentNextStep({
    super.key,
    required this.i18n,
    required this.shipment,
    required this.busy,
    required this.onPublish,
    required this.onCancel,
    required this.onCompare,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final bool busy;
  final VoidCallback onPublish;
  final VoidCallback onCancel;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = shipmentNextMessage(i18n, shipment);
    final showCompare = shipment.canCompareQuotations &&
        (shipment.quotationsCount ?? shipment.quotations.length) > 0;

    return Card(
      key: const Key('shipment-next-step'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusStepper(
              steps: [
                AppStepItem(
                  id: 'draft',
                  label: i18n.status('draft'),
                  icon: Icons.edit_note_rounded,
                ),
                AppStepItem(
                  id: 'published',
                  label: i18n.status('published'),
                  icon: Icons.campaign_rounded,
                ),
                AppStepItem(
                  id: 'awarded',
                  label: i18n.status('awarded'),
                  icon: Icons.workspace_premium_rounded,
                ),
              ],
              currentId: shipmentStepId(shipment.status),
              failed:
                  shipment.status == 'cancelled' || shipment.status == 'expired',
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: text.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
            if (shipment.canPublish || shipment.canCancel || showCompare) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (showCompare)
                    AppButton(
                      key: const Key('shipment-compare'),
                      label: i18n.t('shipment.viewQuotations'),
                      icon: Icons.compare_arrows_rounded,
                      onPressed: busy ? null : onCompare,
                    ),
                  if (shipment.canPublish)
                    AppButton(
                      key: const Key('shipment-publish'),
                      label: i18n.t('shipment.publish'),
                      icon: Icons.campaign_rounded,
                      loading: busy,
                      onPressed: onPublish,
                    ),
                  if (shipment.canCancel)
                    AppButton(
                      key: const Key('shipment-cancel'),
                      label: i18n.t('shipment.cancelRequest'),
                      icon: Icons.cancel_outlined,
                      variant: AppButtonVariant.danger,
                      loading: busy,
                      onPressed: onCancel,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String shipmentStepId(String? status) {
  return switch (status) {
    'published' || 'expired' => 'published',
    'awarded' => 'awarded',
    _ => 'draft',
  };
}

class ShipmentRecordLayout extends StatelessWidget {
  const ShipmentRecordLayout({
    super.key,
    required this.i18n,
    required this.shipment,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final route = _RouteRecord(i18n: i18n, shipment: shipment);
        final specs = Column(
          children: [
            _CargoRecord(i18n: i18n, shipment: shipment),
            const SizedBox(height: 16),
            SectionCard(
              title: i18n.t('paymentContract.title'),
              icon: Icons.payments_outlined,
              child: PaymentTermsReadout(
                i18n: i18n,
                terms: shipment.paymentTerms,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < shipmentDetailSplitWidth) {
          return Column(
            children: [
              route,
              const SizedBox(height: 16),
              specs,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: route),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: specs),
          ],
        );
      },
    );
  }
}

class ShipmentPlatformOfferSection extends StatelessWidget {
  const ShipmentPlatformOfferSection({
    super.key,
    required this.i18n,
    required this.shipment,
    required this.onAccept,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final offer = shipment.platformOffer;
    if (offer == null) return const SizedBox.shrink();
    final currency = offer.currency ?? 'OMR';
    return SectionCard(
      title: i18n.t('shipment.platformOffer'),
      icon: Icons.request_quote_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: i18n.t('quotation.price'),
            value: formatAmount(offer.customerPrice, currency: currency),
          ),
          InfoRow(
            label: i18n.t('quotation.trucks'),
            value: '${offer.truckCount ?? '—'}',
          ),
          InfoRow(
            label: i18n.t('quotation.truckType'),
            value: offer.truckTypeLabel ?? offer.truckType ?? '—',
          ),
          InfoRow(
            label: i18n.t('quotation.trips'),
            value: '${offer.tripCount ?? '—'}',
          ),
          InfoRow(
            label: i18n.t('quotation.duration'),
            value: '${offer.durationDays ?? '—'}',
          ),
          InfoRow(
            label: i18n.t('quotation.transportStart'),
            value: formatDate(offer.transportStartDate, locale: i18n.locale.languageCode),
          ),
          if ((offer.conditions ?? '').trim().isNotEmpty)
            InfoRow(
              label: i18n.t('quotation.conditions'),
              value: offer.conditions!.trim(),
            ),
          const SizedBox(height: 8),
          StatusBadge(
            status: offer.status ?? '',
            label: i18n.status(offer.status),
          ),
          if (offer.canAccept && shipment.status == 'published') ...[
            const SizedBox(height: 14),
            AppButton(
              label: i18n.t('shipment.acceptPlatformOffer'),
              icon: Icons.check_circle_outline,
              onPressed: onAccept,
            ),
          ],
        ],
      ),
    );
  }
}

class ShipmentQuotationsSection extends StatelessWidget {
  const ShipmentQuotationsSection({
    super.key,
    required this.i18n,
    required this.quotations,
    required this.showCompare,
  });

  final I18nBundle i18n;
  final List<Quotation> quotations;
  final bool showCompare;

  @override
  Widget build(BuildContext context) {
    final locale = i18n.locale.languageCode;
    return SectionCard(
      title: quotations.isEmpty
          ? i18n.t('quotation.title')
          : showCompare
              ? i18n.t('shipment.quotationsCount', {
                  'count': '${quotations.length}',
                })
              : i18n.t('shipment.awardedQuotation'),
      icon: Icons.request_quote_rounded,
      child: quotations.isEmpty
          ? Text(
              i18n.t('quotation.empty'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
            )
          : Column(
              children: [
                for (var index = 0; index < quotations.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _QuotationRow(
                    i18n: i18n,
                    locale: locale,
                    quotation: quotations[index],
                  ),
                ],
              ],
            ),
    );
  }
}

class _QuotationRow extends StatelessWidget {
  const _QuotationRow({
    required this.i18n,
    required this.locale,
    required this.quotation,
  });

  final I18nBundle i18n;
  final String locale;
  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    final provider = quotation.provider?.displayName(locale);
    final reference = quotation.reference?.trim();
    final title = (provider != null && provider.isNotEmpty && provider != '—')
        ? provider
        : (reference != null && reference.isNotEmpty)
            ? reference
            : i18n.t('quotation.detail');

    return AppListCard(
      embedded: true,
      onTap: () => context.push('/quotations/${quotation.id}'),
      leading: const AppGlyph(
        icon: Icons.handshake_outlined,
        size: 40,
        iconSize: 20,
        tone: AppGlyphTone.navy,
      ),
      title: title,
      subtitle: provider != null &&
              provider.isNotEmpty &&
              reference != null &&
              reference.isNotEmpty
          ? reference
          : null,
      meta: formatAmount(
        quotation.totalPrice,
        currency: quotation.currency ?? 'OMR',
      ),
      trailing: StatusBadge(
        status: quotation.status ?? '',
        label: i18n.status(quotation.status),
      ),
    );
  }
}

class _CargoRecord extends StatelessWidget {
  const _CargoRecord({required this.i18n, required this.shipment});

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    final description = shipment.cargoDescription?.trim();
    return SectionCard(
      title: i18n.t('shipment.cargo'),
      icon: Icons.category_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactGrid(
            children: [
              InfoRow(
                label: i18n.t('shipment.cargoType'),
                value: shipment.cargoType ?? '—',
                icon: Icons.category_outlined,
              ),
              InfoRow(
                label: i18n.t('shipment.truckType'),
                value: shipment.truckTypeLabel ?? shipment.truckType ?? '—',
                icon: Icons.local_shipping_outlined,
              ),
              InfoRow(
                label: i18n.t('shipment.weight'),
                value:
                    '${formatNumber(shipment.weightTons)} ${i18n.t('common.tons')}',
                icon: Icons.scale_outlined,
              ),
              if (!QuantityUnits.isTons(shipment.quantityUnit))
                InfoRow(
                  label: QuantityUnits.countFieldLabel(
                    i18n,
                    shipment.quantityUnit ?? '',
                  ),
                  value: QuantityUnits.formatQuantity(
                    i18n,
                    shipment.quantity,
                    shipment.quantityUnit,
                  ),
                  icon: Icons.numbers_rounded,
                ),
              if (shipment.volumeCbm != null)
                InfoRow(
                  label: i18n.t('shipment.volume'),
                  value:
                      '${formatNumber(shipment.volumeCbm)} ${i18n.t('common.cbm')}',
                  icon: Icons.view_in_ar_outlined,
                ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 16),
            InfoRow(
              label: i18n.t('shipment.cargoDescription'),
              value: description,
              icon: Icons.notes_rounded,
              wide: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRecord extends StatelessWidget {
  const _RouteRecord({required this.i18n, required this.shipment});

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    final locale = i18n.locale.languageCode;
    final notes = shipment.notes?.trim();
    return SectionCard(
      title: i18n.t('shipment.route'),
      icon: Icons.route_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationPreview(
            i18n: i18n,
            title: i18n.t('common.pickup'),
            address: shipment.pickupAddress,
            city: shipment.pickupCity,
            lat: shipment.pickupLat,
            lng: shipment.pickupLng,
          ),
          const SizedBox(height: 16),
          LocationPreview(
            i18n: i18n,
            title: i18n.t('common.delivery'),
            address: shipment.deliveryAddress,
            city: shipment.deliveryCity,
            lat: shipment.deliveryLat,
            lng: shipment.deliveryLng,
          ),
          const SizedBox(height: 16),
          _FactGrid(
            children: [
              InfoRow(
                label: i18n.t('shipment.requiredDate'),
                value: formatDate(shipment.requiredDate, locale: locale),
                icon: Icons.event_outlined,
              ),
              if (shipment.publishedAt != null)
                InfoRow(
                  label: i18n.t('shipment.publishedAt'),
                  value: formatDateTime(shipment.publishedAt, locale: locale),
                  icon: Icons.campaign_outlined,
                ),
              if (shipment.createdAt != null)
                InfoRow(
                  label: i18n.t('common.created'),
                  value: formatDateTime(shipment.createdAt, locale: locale),
                  icon: Icons.schedule_outlined,
                ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            InfoRow(
              label: i18n.t('common.notes'),
              value: notes,
              icon: Icons.sticky_note_2_outlined,
              wide: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 2 : 1;
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 14),
                children[index],
              ],
            ],
          );
        }

        final itemWidth = (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
