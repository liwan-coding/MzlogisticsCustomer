import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/bidi_text.dart';
import '../../../core/utils/formatters.dart';
import '../../trips/data/customer_trip_progress.dart';
import '../../trips/data/trip_model.dart';
import '../../trips/presentation/widgets/trip_status.dart';
import '../data/dashboard_model.dart';
import 'home_providers.dart';

const _orange = Color(0xFFF15A22);
const _ink = Color(0xFF1C2430);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE7E9EF);

/// One moving trip, shown only while a truck is actually on the road.
class HomeLiveTrip extends ConsumerWidget {
  const HomeLiveTrip({
    super.key,
    required this.i18n,
    required this.summary,
    required this.wide,
  });

  final I18nBundle i18n;
  final DashboardSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(featuredInTransitTripProvider);
    return trip.when(
      loading: () => _expectsLiveTrip(summary)
          ? _LiveTripShell(wide: wide, child: const _LiveTripSkeleton())
          : const SizedBox.shrink(),
      error: (_, _) => _expectsLiveTrip(summary)
          ? _LiveTripShell(
              wide: wide,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(featuredInTransitTripProvider),
                  child: Text(i18n.t('common.retry')),
                ),
              ),
            )
          : const SizedBox.shrink(),
      data: (moving) {
        if (moving == null) return const SizedBox.shrink();
        return _LiveTripShell(
          wide: wide,
          child: _LiveTripCard(i18n: i18n, trip: moving, wide: wide),
        );
      },
    );
  }
}

bool _expectsLiveTrip(DashboardSummary summary) {
  return summary.tripsActive > 0 || summary.tripsInTransit > 0;
}

class _LiveTripShell extends StatelessWidget {
  const _LiveTripShell({required this.wide, required this.child});

  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gap = wide ? 48.0 : 32.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 40 : 16, gap, wide ? 40 : 16, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x101C2430),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 18,
                wide ? 24 : 18,
                wide ? 28 : 18,
                wide ? 24 : 18,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveTripCard extends StatelessWidget {
  const _LiveTripCard({
    required this.i18n,
    required this.trip,
    required this.wide,
  });

  final I18nBundle i18n;
  final Trip trip;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locale = i18n.locale.languageCode;
    final pickup =
        _place(trip.pickupCity, trip.pickupAddress) ?? i18n.t('common.dash');
    final delivery =
        _place(trip.deliveryCity, trip.deliveryAddress) ??
        i18n.t('common.dash');
    final reference = (trip.reference ?? '').trim();
    final onTheRoad =
        CustomerTripProgress.stageOf(trip.status) ==
        CustomerTripProgress.inTransit;
    final plate = trip.truck?.plateNumber?.trim();
    final driver = trip.driver?.name.trim();
    final facts = <String>[
      if (plate != null && plate.isNotEmpty)
        '${i18n.t('trip.truck')}  ${bidiIsolate(plate)}',
      if (driver != null && driver.isNotEmpty)
        '${i18n.t('trip.driver')}  ${bidiIsolate(driver)}',
    ];
    final follow = FilledButton.icon(
      onPressed: () => _openTrip(context, trip),
      style: FilledButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        minimumSize: Size(wide ? 0 : double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.near_me_rounded, size: 18),
      label: Text(
        i18n.t('home.liveTripFollow'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LiveDot(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTheRoad
                        ? i18n.t('home.liveTripNow')
                        : customerTripStageLabel(i18n, trip.status),
                    style: text.titleMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bidiIsolate(reference),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trip.etaAt != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      i18n.t('common.eta'),
                      style: text.labelMedium?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(trip.etaAt, locale: locale),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (trip.etaAt == null) ...[
          const SizedBox(height: 6),
          Text(
            customerTripStageHint(i18n, trip.status),
            style: text.bodyMedium?.copyWith(color: _muted, height: 1.4),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CityBlock(
                label: i18n.t('home.pickupLabel'),
                city: pickup,
                alignEnd: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _CityBlock(
                label: i18n.t('home.deliveryLabel'),
                city: delivery,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _RouteLine(),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _FactLine(facts: facts)),
              const SizedBox(width: 16),
              follow,
            ],
          )
        else ...[
          if (facts.isNotEmpty) ...[
            _FactLine(facts: facts),
            const SizedBox(height: 14),
          ],
          SizedBox(width: double.infinity, child: follow),
        ],
      ],
    );
  }
}

void _openTrip(BuildContext context, Trip trip) {
  final path = AppConstants.liveTrackingEnabled
      ? '/trips/${trip.id}/tracking'
      : '/trips/${trip.id}';
  context.push(path);
}

class _CityBlock extends StatelessWidget {
  const _CityBlock({
    required this.label,
    required this.city,
    required this.alignEnd,
  });

  final String label;
  final String city;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bidiIsolate(city),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _RouteStop(filled: false),
                Expanded(child: _RouteStroke()),
                _RouteStop(filled: true),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _orange, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AF15A22),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Transform.flip(
                flipX: rtl,
                child: const Icon(
                  Icons.local_shipping_rounded,
                  size: 18,
                  color: _orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? _orange : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? _orange : const Color(0xFFC5CDD8),
          width: 2,
        ),
      ),
    );
  }
}

class _RouteStroke extends StatelessWidget {
  const _RouteStroke();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      child: ColoredBox(color: Color(0xFFD5DAE3)),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    return Text(
      facts.join('    '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: _ink, height: 1.35),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = DecoratedBox(
      decoration: BoxDecoration(color: _orange, shape: BoxShape.circle),
      child: SizedBox(width: 8, height: 8),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: 16,
        height: 16,
        child: MediaQuery.disableAnimationsOf(context)
            ? const Center(child: dot)
            : AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + (_pulse.value * 0.9),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _orange.withValues(
                              alpha: 0.35 * (1 - _pulse.value),
                            ),
                          ),
                          child: const SizedBox(width: 8, height: 8),
                        ),
                      ),
                      dot,
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _LiveTripSkeleton extends StatelessWidget {
  const _LiveTripSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Bone(width: 140, height: 16),
        ),
        SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _Bone(width: double.infinity, height: 28)),
            SizedBox(width: 48),
            Expanded(child: _Bone(width: double.infinity, height: 28)),
          ],
        ),
        SizedBox(height: 18),
        _Bone(width: double.infinity, height: 8),
        SizedBox(height: 18),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Bone(width: 180, height: 40),
        ),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7E9EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

String? _place(String? city, String? address) {
  if (city != null && city.trim().isNotEmpty) return city.trim();
  if (address != null && address.trim().isNotEmpty) return address.trim();
  return null;
}
