import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/maps/google_maps_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/customer_trip_progress.dart';
import '../../data/trip_model.dart';
import 'trip_status.dart';

class TripBoard extends StatelessWidget {
  const TripBoard({super.key, required this.i18n, required this.trip});

  final I18nBundle i18n;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final wide = context.isDesktop;
    final gap = wide ? 16.0 : 12.0;
    final stepper = _StageCard(i18n: i18n, trip: trip, wide: wide);
    final info = _InfoCard(i18n: i18n, trip: trip);
    final route = _RouteCard(i18n: i18n, trip: trip, wide: wide);
    final quantities = _QuantityCard(i18n: i18n, trip: trip);
    final stops = _StopsCard(i18n: i18n, trip: trip);
    final extra = _extraCard(context);

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stepper,
          SizedBox(height: gap),
          info,
          SizedBox(height: gap),
          route,
          SizedBox(height: gap),
          quantities,
          SizedBox(height: gap),
          stops,
          if (extra != null) ...[
            SizedBox(height: gap),
            extra,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stepper,
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: info),
            SizedBox(width: gap),
            Expanded(flex: 8, child: route),
          ],
        ),
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: extra == null ? 1 : 5, child: quantities),
            SizedBox(width: gap),
            Expanded(flex: extra == null ? 1 : 4, child: stops),
            if (extra != null) ...[
              SizedBox(width: gap),
              Expanded(flex: 3, child: extra),
            ],
          ],
        ),
      ],
    );
  }

  Widget? _extraCard(BuildContext context) {
    final code = trip.otpCode?.trim();
    if (code != null && code.isNotEmpty) {
      return _OtpCard(i18n: i18n, code: code);
    }
    final notes = trip.proofOfDelivery?.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      return _Panel(
        title: i18n.t('common.notes'),
        child: Text(
          notes,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }
    return null;
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.i18n, required this.trip, required this.wide});

  final I18nBundle i18n;
  final Trip trip;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final failed = CustomerTripProgress.isFailed(trip.status);
    final current = CustomerTripProgress.indexOf(trip.status);
    final steps = [
      _Stage(
        label: i18n.t('trip.stage.assigned'),
        icon: Icons.inventory_2_outlined,
        at: CustomerTripProgress.timestampFor(trip, CustomerTripProgress.assigned),
      ),
      _Stage(
        label: i18n.t('trip.stage.loaded'),
        icon: Icons.inventory_2_rounded,
        at: CustomerTripProgress.timestampFor(trip, CustomerTripProgress.loaded),
      ),
      _Stage(
        label: i18n.t('trip.stage.in_transit'),
        icon: Icons.local_shipping_outlined,
        at: CustomerTripProgress.timestampFor(trip, CustomerTripProgress.inTransit),
      ),
      _Stage(
        label: i18n.t('trip.stage.delivered'),
        icon: Icons.flag_outlined,
        at: CustomerTripProgress.timestampFor(trip, CustomerTripProgress.delivered),
      ),
    ];

    return _Panel(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < steps.length; index++)
                Expanded(
                  child: _StageNode(
                    stage: steps[index],
                    wide: wide,
                    failed: failed && index == current,
                    current: !failed && index == current,
                    done: !failed && index < current,
                    showBefore: index > 0,
                    showAfter: index < steps.length - 1,
                    lineBefore: index > 0 && !failed && index <= current,
                    lineAfter: index < steps.length - 1 && !failed && index < current,
                    locale: i18n.locale.languageCode,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customerTripStageHint(i18n, trip.status),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: failed ? AppColors.danger : AppColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _Stage {
  const _Stage({required this.label, required this.icon, required this.at});

  final String label;
  final IconData icon;
  final DateTime? at;
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.wide,
    required this.failed,
    required this.current,
    required this.done,
    required this.showBefore,
    required this.showAfter,
    required this.lineBefore,
    required this.lineAfter,
    required this.locale,
  });

  final _Stage stage;
  final bool wide;
  final bool failed;
  final bool current;
  final bool done;
  final bool showBefore;
  final bool showAfter;
  final bool lineBefore;
  final bool lineAfter;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final size = wide ? 48.0 : 36.0;
    final active = current || done;
    final ring = failed
        ? AppColors.danger
        : active
            ? AppColors.orange
            : AppColors.border;
    final iconColor = current
        ? AppColors.white
        : failed
            ? AppColors.danger
            : done
                ? AppColors.orange
                : AppColors.muted;
    final text = Theme.of(context).textTheme;
    final when = stage.at == null ? null : formatDateTime(stage.at, locale: locale);

    return Column(
      children: [
        SizedBox(
          height: size,
          child: Row(
            children: [
              Expanded(child: _StageLine(on: lineBefore, shown: showBefore)),
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: current
                      ? (failed ? AppColors.danger : AppColors.orange)
                      : AppColors.white,
                  border: Border.all(color: ring, width: current ? 0 : 1.5),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: (failed ? AppColors.danger : AppColors.orange).withValues(alpha: 0.28),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(stage.icon, size: wide ? 22 : 18, color: iconColor),
              ),
              Expanded(child: _StageLine(on: lineAfter, shown: showAfter)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stage.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.labelMedium?.copyWith(
            color: current ? AppColors.ink : AppColors.muted,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        if (when != null && when != '—') ...[
          const SizedBox(height: 2),
          Text(
            when,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: AppColors.muted, height: 1.3),
          ),
        ],
      ],
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({required this.on, required this.shown});

  final bool on;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: !shown
            ? const Color(0x00000000)
            : on
                ? AppColors.orange
                : AppColors.border,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.i18n, required this.trip});

  final I18nBundle i18n;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final locale = i18n.locale.languageCode;
    final reference = trip.reference?.trim();
    final title = (reference != null && reference.isNotEmpty)
        ? reference
        : i18n.t('trip.sequence', {'n': '${trip.sequence ?? trip.id}'});
    final plate = trip.truck?.plateNumber?.trim();
    final type = trip.truck?.type?.trim();
    final truck = [
      if (plate != null && plate.isNotEmpty) plate,
      if (type != null && type.isNotEmpty) type,
    ].join(' · ');
    final rows = <_Fact>[
      _Fact(i18n.t('common.reference'), title, Icons.tag_outlined),
      _Fact(i18n.t('nav.jobs'), trip.jobReference ?? '—', Icons.assignment_outlined),
      _Fact(
        i18n.t('trip.truck'),
        truck.isEmpty ? i18n.t('common.notAvailable') : truck,
        Icons.local_shipping_outlined,
      ),
      _Fact(
        i18n.t('common.status'),
        '',
        Icons.flag_outlined,
        badge: StatusBadge(
          status: CustomerTripProgress.stageOf(trip.status),
          label: customerTripStageLabel(i18n, trip.status),
        ),
      ),
      _Fact(
        i18n.t('trip.driver'),
        trip.driver?.name.trim().isNotEmpty == true ? trip.driver!.name.trim() : i18n.t('common.notAvailable'),
        Icons.person_outline,
      ),
      _Fact(
        i18n.t('trip.scheduledDeparture'),
        formatDateTime(trip.scheduledDepartureAt ?? trip.assignedAt, locale: locale),
        Icons.event_outlined,
      ),
      _Fact(
        i18n.t('common.eta'),
        formatDateTime(trip.etaAt, locale: locale),
        Icons.schedule_outlined,
      ),
      if (trip.trailerPlate != null && trip.trailerPlate!.trim().isNotEmpty)
        _Fact(i18n.t('trip.trailer'), trip.trailerPlate!.trim(), Icons.rv_hookup_outlined),
      if (trip.deliveryNoteNumber != null && trip.deliveryNoteNumber!.trim().isNotEmpty)
        _Fact(i18n.t('trip.deliveryNote'), trip.deliveryNoteNumber!.trim(), Icons.receipt_long_outlined),
    ];

    return _Panel(
      title: i18n.t('trip.info'),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _FactRow(fact: rows[index]),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (AppConstants.liveTrackingEnabled) ...[
                Expanded(
                  child: AppButton(
                    label: i18n.t('trip.viewTracking'),
                    icon: Icons.near_me_rounded,
                    expanded: true,
                    onPressed: () => context.push('/trips/${trip.id}/tracking'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppButton(
                  label: i18n.t('trip.viewPod'),
                  icon: Icons.verified_rounded,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => context.push('/trips/${trip.id}/pod'),
                ),
              ),
              if (trip.jobId != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: i18n.t('job.detail'),
                    icon: Icons.assignment_outlined,
                    variant: AppButtonVariant.ghost,
                    expanded: true,
                    onPressed: () => context.push('/jobs/${trip.jobId}'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value, this.icon, {this.badge});

  final String label;
  final String value;
  final IconData icon;
  final Widget? badge;
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fact.icon, size: 16, color: AppColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: fact.badge ??
                  Text(
                    fact.value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.i18n, required this.trip, required this.wide});

  final I18nBundle i18n;
  final Trip trip;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final from = _place(trip.pickupCity, trip.pickupAddress);
    final to = _place(trip.deliveryCity, trip.deliveryAddress);
    final locale = i18n.locale.languageCode;
    final eta = trip.etaAt == null ? null : formatDateTime(trip.etaAt, locale: locale);

    return _Panel(
      title: i18n.t('shipment.route'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
                return SizedBox(
                  width: mapWidth,
                  height: wide ? 280 : 200,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _RouteMap(trip: trip)),
                      if (_hasAnyPoint(trip))
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (trip.pickupLat != null && trip.pickupLng != null)
                                _MapLink(
                                  label: i18n.t('trip.mapPickup'),
                                  iconColor: AppColors.orange,
                                  maxWidth: mapWidth * 0.46,
                                  onPressed: () => _openPoint(trip.pickupLat!, trip.pickupLng!),
                                ),
                              if (trip.pickupLat != null &&
                                  trip.pickupLng != null &&
                                  trip.deliveryLat != null &&
                                  trip.deliveryLng != null)
                                const SizedBox(height: 8),
                              if (trip.deliveryLat != null && trip.deliveryLng != null)
                                _MapLink(
                                  label: i18n.t('trip.mapDelivery'),
                                  iconColor: AppColors.success,
                                  maxWidth: mapWidth * 0.46,
                                  onPressed: () => _openPoint(trip.deliveryLat!, trip.deliveryLng!),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if ((from != null && to != null) || eta != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (eta != null)
                  _RouteChip(
                    icon: Icons.schedule_outlined,
                    label: i18n.t('common.eta'),
                    value: eta,
                  ),
                if (from != null && to != null)
                  _RouteChip(
                    icon: Icons.route_outlined,
                    label: i18n.t('shipment.route'),
                    value: '$from → $to',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[
      if (trip.pickupLat != null && trip.pickupLng != null) LatLng(trip.pickupLat!, trip.pickupLng!),
      if (trip.currentLat != null && trip.currentLng != null) LatLng(trip.currentLat!, trip.currentLng!),
      if (trip.deliveryLat != null && trip.deliveryLng != null) LatLng(trip.deliveryLat!, trip.deliveryLng!),
    ];
    if (points.isEmpty) {
      return const ColoredBox(
        color: AppColors.mist,
        child: Center(child: Icon(Icons.map_outlined, color: AppColors.muted, size: 36)),
      );
    }

    final pickup = trip.pickupLat != null && trip.pickupLng != null
        ? LatLng(trip.pickupLat!, trip.pickupLng!)
        : null;
    final delivery = trip.deliveryLat != null && trip.deliveryLng != null
        ? LatLng(trip.deliveryLat!, trip.deliveryLng!)
        : null;
    final current = trip.currentLat != null && trip.currentLng != null
        ? LatLng(trip.currentLat!, trip.currentLng!)
        : null;
    final line = [?pickup, ?delivery];

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: line.length < 2 ? 12 : 8,
        initialCameraFit: line.length < 2
            ? null
            : CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(line),
                padding: const EdgeInsets.all(42),
              ),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mz_logistics_customer_app',
        ),
        if (line.length == 2)
          PolylineLayer(
            polylines: [
              Polyline(points: line, color: AppColors.orange, strokeWidth: 4),
            ],
          ),
        MarkerLayer(
          markers: [
            if (pickup != null)
              Marker(
                point: pickup,
                width: 36,
                height: 36,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on, color: AppColors.orange, size: 36),
              ),
            if (delivery != null)
              Marker(
                point: delivery,
                width: 36,
                height: 36,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on, color: AppColors.success, size: 36),
              ),
            if (current != null)
              Marker(
                point: current,
                width: 36,
                height: 36,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  child: Icon(Icons.local_shipping_rounded, color: AppColors.orange, size: 22),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapLink extends StatelessWidget {
  const _MapLink({
    required this.label,
    required this.onPressed,
    required this.iconColor,
    required this.maxWidth,
  });

  final String label;
  final VoidCallback onPressed;
  final Color iconColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      shadowColor: const Color(0x22101A2B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.icon,
    required this.label,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.orange),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
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

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({required this.i18n, required this.trip});

  final I18nBundle i18n;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: i18n.t('trip.quantities'),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: i18n.t('trip.planned'),
              value: formatNumber(trip.plannedQuantity),
              icon: Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Metric(
              label: i18n.t('trip.delivered'),
              value: formatNumber(trip.deliveredQuantity),
              icon: Icons.verified_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _StopsCard extends StatelessWidget {
  const _StopsCard({required this.i18n, required this.trip});

  final I18nBundle i18n;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: i18n.t('trip.stops'),
      child: Column(
        children: [
          _Stop(
            label: i18n.t('common.pickup'),
            place: _place(trip.pickupCity, trip.pickupAddress) ?? i18n.t('common.notAvailable'),
            point: _point(trip.pickupLat, trip.pickupLng),
            color: AppColors.orange,
          ),
          const SizedBox(height: 14),
          _Stop(
            label: i18n.t('common.delivery'),
            place: _place(trip.deliveryCity, trip.deliveryAddress) ?? i18n.t('common.notAvailable'),
            point: _point(trip.deliveryLat, trip.deliveryLng),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.label,
    required this.place,
    required this.point,
    required this.color,
  });

  final String label;
  final String place;
  final String? point;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelSmall?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                place,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              if (point != null) ...[
                const SizedBox(height: 2),
                Text(
                  point!,
                  style: text.labelSmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.i18n, required this.code});

  final I18nBundle i18n;
  final String code;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: i18n.t('trip.otp'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t('trip.otpHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: i18n.t('trip.otpCopy'),
            icon: Icons.copy_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(i18n.t('trip.otpCopied'))),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A101A2B), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

String? _place(String? city, String? address) {
  final town = city?.trim() ?? '';
  final line = address?.trim() ?? '';
  if (town.isEmpty && line.isEmpty) return null;
  if (town.isEmpty) return line;
  if (line.isEmpty || line == town) return town;
  return '$town, $line';
}

String? _point(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  return formatCoordinates(lat, lng);
}

bool _hasAnyPoint(Trip trip) {
  return (trip.pickupLat != null && trip.pickupLng != null) ||
      (trip.deliveryLat != null && trip.deliveryLng != null);
}

Future<void> _openPoint(double lat, double lng) {
  return launchUrl(
    GoogleMapsLinks.view(lat: lat, lng: lng),
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );
}
