import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/maps/google_maps_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glyph.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/page_scaffold.dart';
import '../../../../shared/widgets/status_badge.dart';
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

String shipmentStepId(String? status) {
  return switch (status) {
    'published' || 'expired' => 'published',
    'awarded' => 'awarded',
    _ => 'draft',
  };
}

class ShipmentSummaryPanel extends StatelessWidget {
  const ShipmentSummaryPanel({
    super.key,
    required this.i18n,
    required this.shipment,
    required this.title,
    required this.status,
    required this.locale,
    required this.busy,
    required this.onPublish,
    required this.onCancel,
    required this.onCompare,
    this.reference,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final String title;
  final String? reference;
  final String status;
  final String locale;
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
    final ref = reference?.trim();

    return _Sheet(
      wash: true,
      child: Column(
        key: const Key('shipment-next-step'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (ref != null && ref.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ref,
                        style: text.titleSmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${i18n.t('shipment.requiredDate')}  ${formatDate(shipment.requiredDate, locale: locale)}',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: status, label: i18n.status(status)),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              message,
              style: text.bodyLarge?.copyWith(height: 1.45, color: AppColors.ink),
            ),
          ],
          if (shipment.canPublish || shipment.canCancel || showCompare) ...[
            const SizedBox(height: 16),
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
    );
  }
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
    final request = _RequestSheet(i18n: i18n, shipment: shipment);
    final cargo = _CargoSheet(i18n: i18n, shipment: shipment);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPair(
          primary: request,
          secondary: cargo,
          splitAt: shipmentDetailSplitWidth,
        ),
        const SizedBox(height: 16),
        _RouteSheet(i18n: i18n, shipment: shipment),
      ],
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
    final locale = i18n.locale.languageCode;
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHead(title: i18n.t('shipment.platformOffer'), icon: Icons.request_quote_outlined),
          _FactLine(
            label: i18n.t('quotation.price'),
            value: formatAmount(offer.customerPrice, currency: currency),
          ),
          _FactLine(label: i18n.t('quotation.trucks'), value: '${offer.truckCount ?? '—'}'),
          _FactLine(
            label: i18n.t('quotation.truckType'),
            value: offer.truckTypeLabel ?? offer.truckType ?? '—',
          ),
          _FactLine(label: i18n.t('quotation.trips'), value: '${offer.tripCount ?? '—'}'),
          _FactLine(label: i18n.t('quotation.duration'), value: '${offer.durationDays ?? '—'}'),
          _FactLine(
            label: i18n.t('quotation.transportStart'),
            value: formatDate(offer.transportStartDate, locale: locale),
          ),
          if ((offer.conditions ?? '').trim().isNotEmpty)
            _FactLine(label: i18n.t('quotation.conditions'), value: offer.conditions!.trim()),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(status: offer.status ?? '', label: i18n.status(offer.status)),
            ),
          ),
          if (offer.canAccept && shipment.status == 'published') ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: i18n.t('shipment.acceptPlatformOffer'),
                icon: Icons.check_circle_outline,
                onPressed: onAccept,
              ),
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
    final title = quotations.isEmpty
        ? i18n.t('quotation.title')
        : showCompare
            ? i18n.t('shipment.quotationsCount', {'count': '${quotations.length}'})
            : i18n.t('shipment.awardedQuotation');

    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHead(title: title, icon: Icons.handshake_outlined),
          if (quotations.isEmpty)
            Text(
              i18n.t('quotation.empty'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
            )
          else
            for (var index = 0; index < quotations.length; index++) ...[
              if (index > 0) const Divider(height: 1, color: AppColors.border),
              _QuotationRow(i18n: i18n, locale: locale, quotation: quotations[index]),
            ],
        ],
      ),
    );
  }
}

class _RequestSheet extends StatelessWidget {
  const _RequestSheet({required this.i18n, required this.shipment});

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    final locale = i18n.locale.languageCode;
    final quote = shipmentQuoteFact(i18n, shipment);
    final reference = shipment.reference?.trim();

    return _Sheet(
      key: const Key('shipment-request-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHead(title: i18n.t('shipment.requestDetails'), icon: Icons.article_outlined),
          if (reference != null && reference.isNotEmpty)
            _FactLine(label: i18n.t('shipment.reference'), value: reference),
          _FactLine(
            label: i18n.t('shipment.requiredDate'),
            value: formatDate(shipment.requiredDate, locale: locale),
          ),
          if (shipment.createdAt != null)
            _FactLine(
              label: i18n.t('common.created'),
              value: formatDateTime(shipment.createdAt, locale: locale),
            ),
          if (shipment.publishedAt != null)
            _FactLine(
              label: i18n.t('shipment.publishedAt'),
              value: formatDateTime(shipment.publishedAt, locale: locale),
            ),
          _FactLine(
            label: i18n.t('common.status'),
            valueChild: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusBadge(
                status: shipment.status ?? '',
                label: i18n.status(shipment.status),
              ),
            ),
          ),
          if (quote != null) _FactLine(label: quote.label, value: quote.value),
          _FactLine(
            label: i18n.t('paymentContract.title'),
            value: shipment.paymentTerms.label(i18n),
          ),
        ],
      ),
    );
  }
}

class _CargoSheet extends StatelessWidget {
  const _CargoSheet({required this.i18n, required this.shipment});

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    final description = shipment.cargoDescription?.trim();
    final notes = shipment.notes?.trim();

    return _Sheet(
      key: const Key('shipment-cargo-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHead(title: i18n.t('shipment.cargo'), icon: Icons.inventory_2_outlined),
          _FactLine(label: i18n.t('shipment.cargoType'), value: shipment.cargoType ?? '—'),
          _FactLine(
            label: i18n.t('shipment.truckType'),
            value: shipment.truckTypeLabel ?? shipment.truckType ?? '—',
          ),
          _FactLine(
            label: i18n.t('shipment.weight'),
            value: '${formatNumber(shipment.weightTons)} ${i18n.t('common.tons')}',
          ),
          if (!QuantityUnits.isTons(shipment.quantityUnit))
            _FactLine(
              label: QuantityUnits.countFieldLabel(i18n, shipment.quantityUnit ?? ''),
              value: QuantityUnits.formatQuantity(i18n, shipment.quantity, shipment.quantityUnit),
            ),
          if (shipment.volumeCbm != null)
            _FactLine(
              label: i18n.t('shipment.volume'),
              value: '${formatNumber(shipment.volumeCbm)} ${i18n.t('common.cbm')}',
            ),
          if (description != null && description.isNotEmpty)
            _FactLine(label: i18n.t('shipment.cargoDescription'), value: description),
          if (notes != null && notes.isNotEmpty) _FactLine(label: i18n.t('common.notes'), value: notes),
        ],
      ),
    );
  }
}

class _RouteSheet extends StatelessWidget {
  const _RouteSheet({required this.i18n, required this.shipment});

  final I18nBundle i18n;
  final ShipmentRequest shipment;

  @override
  Widget build(BuildContext context) {
    final pickup = _RouteStop(
      label: i18n.t('common.pickup'),
      city: shipment.pickupCity ?? shipment.pickupAddress ?? '—',
      address: shipment.pickupAddress,
      lat: shipment.pickupLat,
      lng: shipment.pickupLng,
      i18n: i18n,
    );
    final delivery = _RouteStop(
      label: i18n.t('common.delivery'),
      city: shipment.deliveryCity ?? shipment.deliveryAddress ?? '—',
      address: shipment.deliveryAddress,
      lat: shipment.deliveryLat,
      lng: shipment.deliveryLng,
      i18n: i18n,
    );

    return _Sheet(
      key: const Key('shipment-route-card'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHead(title: i18n.t('shipment.route'), icon: Icons.alt_route_rounded),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    pickup,
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Icon(Icons.south_rounded, size: 18, color: AppColors.orange),
                    ),
                    delivery,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pickup),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 22, 12, 0),
                    child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.orange),
                  ),
                  Expanded(child: delivery),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.city,
    required this.i18n,
    this.address,
    this.lat,
    this.lng,
  });

  final String label;
  final String city;
  final String? address;
  final double? lat;
  final double? lng;
  final I18nBundle i18n;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final place = address?.trim();
    final showAddress = place != null && place.isNotEmpty && place != city;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelMedium?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: text.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        if (showAddress) ...[
          const SizedBox(height: 2),
          Text(place, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
        ],
        if (lat != null && lng != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => GoogleMapsLinks.open(lat: lat!, lng: lng!),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(i18n.t('location.openInGoogleMaps')),
            ),
          ),
      ],
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
      meta: formatAmount(quotation.totalPrice, currency: quotation.currency ?? 'OMR'),
      trailing: StatusBadge(
        status: quotation.status ?? '',
        label: i18n.status(quotation.status),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({super.key, required this.child, this.wash = false});

  final Widget child;
  final bool wash;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x101C2430), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (wash) Positioned.fill(child: CustomPaint(painter: _SummaryWash(rtl: rtl))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryWash extends CustomPainter {
  const _SummaryWash({required this.rtl});

  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Path();
    if (rtl) {
      fill
        ..moveTo(0, size.height * 0.08)
        ..quadraticBezierTo(size.width * 0.22, size.height * 0.02, size.width * 0.38, size.height * 0.46)
        ..quadraticBezierTo(size.width * 0.16, size.height * 0.78, 0, size.height)
        ..close();
    } else {
      fill
        ..moveTo(size.width, size.height * 0.08)
        ..quadraticBezierTo(size.width * 0.78, size.height * 0.02, size.width * 0.62, size.height * 0.46)
        ..quadraticBezierTo(size.width * 0.84, size.height * 0.78, size.width, size.height)
        ..close();
    }
    canvas.drawPath(fill, Paint()..color = const Color(0xFFFFF4EE));

    final wave = Path();
    if (rtl) {
      wave
        ..moveTo(6, size.height * 0.34)
        ..cubicTo(
          size.width * 0.08,
          size.height * 0.18,
          size.width * 0.18,
          size.height * 0.52,
          size.width * 0.32,
          size.height * 0.3,
        );
    } else {
      wave
        ..moveTo(size.width - 6, size.height * 0.34)
        ..cubicTo(
          size.width * 0.92,
          size.height * 0.18,
          size.width * 0.82,
          size.height * 0.52,
          size.width * 0.68,
          size.height * 0.3,
        );
    }
    canvas.drawPath(
      wave,
      Paint()
        ..color = const Color(0x66F15A22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SummaryWash oldDelegate) => oldDelegate.rtl != rtl;
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.orange, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.label, this.value, this.valueChild});

  final String label;
  final String? value;
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: valueChild ??
                  Text(
                    value ?? '—',
                    textAlign: TextAlign.end,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShipmentStageCard extends StatelessWidget {
  const ShipmentStageCard({
    super.key,
    required this.i18n,
    required this.shipment,
    required this.locale,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      child: _StatusTrack(i18n: i18n, shipment: shipment, locale: locale),
    );
  }
}

class _StatusTrack extends StatefulWidget {
  const _StatusTrack({
    required this.i18n,
    required this.shipment,
    required this.locale,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final String locale;

  @override
  State<_StatusTrack> createState() => _StatusTrackState();
}

class _StatusTrackState extends State<_StatusTrack> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  var _started = false;

  static const _steps = [
    (id: 'draft', icon: Icons.edit_note_rounded),
    (id: 'published', icon: Icons.local_shipping_rounded),
    (id: 'awarded', icon: Icons.handshake_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
    } else {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  String? _caption(String id) {
    final shipment = widget.shipment;
    final locale = widget.locale;
    return switch (id) {
      'draft' when shipment.createdAt != null => formatDateTime(shipment.createdAt, locale: locale),
      'published' when shipment.publishedAt != null =>
        formatDateTime(shipment.publishedAt, locale: locale),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.shipment.status == 'cancelled' || widget.shipment.status == 'expired';
    final currentId = shipmentStepId(widget.shipment.status);
    final active = _steps.indexWhere((step) => step.id == currentId);
    final activeIndex = active < 0 ? 0 : active;

    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_motion.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final slot = width / _steps.length;
            final span = width - slot;
            final progress = activeIndex / (_steps.length - 1);
            final drawn = span * progress * t;
            return Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        start: slot / 2,
                        top: 21,
                        child: ColoredBox(
                          color: AppColors.border,
                          child: SizedBox(width: span, height: 2),
                        ),
                      ),
                      PositionedDirectional(
                        start: slot / 2,
                        top: 21,
                        child: ColoredBox(
                          color: failed ? AppColors.danger : AppColors.orange,
                          child: SizedBox(width: drawn, height: 2),
                        ),
                      ),
                      Row(
                        children: [
                          for (var index = 0; index < _steps.length; index++)
                            Expanded(
                              child: Center(
                                child: _StepDot(
                                  icon: failed && index == activeIndex
                                      ? Icons.close_rounded
                                      : index < activeIndex && !failed
                                          ? Icons.check_rounded
                                          : _steps[index].icon,
                                  current: index == activeIndex,
                                  done: !failed && index < activeIndex,
                                  failed: failed && index == activeIndex,
                                  scale: index == activeIndex ? 0.86 + (0.14 * t) : 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in _steps)
                      Expanded(
                        child: _StepCaption(
                          label: widget.i18n.status(step.id),
                          caption: _caption(step.id),
                          current: step.id == currentId,
                          failed: failed && step.id == currentId,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.icon,
    required this.current,
    required this.done,
    required this.failed,
    required this.scale,
  });

  final IconData icon;
  final bool current;
  final bool done;
  final bool failed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final color = failed
        ? AppColors.danger
        : current
            ? AppColors.orange
            : done
                ? AppColors.success
                : AppColors.border;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: current ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: current ? 0 : 1.6),
          boxShadow: current
              ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(icon, size: 18, color: current ? Colors.white : color),
      ),
    );
  }
}

class _StepCaption extends StatelessWidget {
  const _StepCaption({
    required this.label,
    required this.current,
    required this.failed,
    this.caption,
  });

  final String label;
  final String? caption;
  final bool current;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: failed
                  ? AppColors.danger
                  : current
                      ? AppColors.orange
                      : AppColors.ink,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
              height: 1.2,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: AppColors.muted, height: 1.2),
            ),
          ],
        ],
      ),
    );
  }
}
