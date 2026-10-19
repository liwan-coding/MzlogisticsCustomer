import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
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
const _hint = Color(0xFF3E4756);
const _line = Color(0xFFE7E9EF);
const _track = Color(0xFFD5DCE6);

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
    final compact = context.isCompact;
    final gap = wide ? 48.0 : (compact ? 22.0 : 28.0);
    final radius = BorderRadius.circular(compact ? 20 : 28);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 40 : (compact ? 14 : 16),
        gap,
        wide ? 40 : (compact ? 14 : 16),
        0,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x161C2430),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  const PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: _orange,
                      child: SizedBox(width: 4),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      wide ? 32 : (compact ? 14 : 18),
                      wide ? 22 : (compact ? 14 : 16),
                      wide ? 28 : (compact ? 14 : 16),
                      wide ? 22 : (compact ? 14 : 16),
                    ),
                    child: child,
                  ),
                ],
              ),
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
    final stage = CustomerTripProgress.stageOf(trip.status);
    final onTheRoad = stage == CustomerTripProgress.inTransit;
    final plate = trip.truck?.plateNumber?.trim();
    final driver = trip.driver?.name.trim();
    final colors = _statusColors(trip.status);
    final narrow = !wide && MediaQuery.sizeOf(context).width < 420;
    final eta = trip.etaAt == null
        ? null
        : Column(
            crossAxisAlignment: narrow
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
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
                textAlign: narrow ? TextAlign.start : TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          );
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
    final facts = <Widget>[
      if (plate != null && plate.isNotEmpty)
        _FactChip(
          icon: Icons.local_shipping_outlined,
          label: i18n.t('trip.truck'),
          value: plate,
        ),
      if (driver != null && driver.isNotEmpty)
        _FactChip(
          icon: Icons.person_outline_rounded,
          label: i18n.t('trip.driver'),
          value: driver,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusMark(
              icon: tripStatusIcon(trip.status),
              background: colors.$1,
              foreground: colors.$2,
              live: CustomerTripProgress.isActive(trip.status),
            ),
            const SizedBox(width: 12),
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
                      height: 1.2,
                    ),
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ReferenceChip(reference: reference),
                  ],
                  if (trip.etaAt == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      customerTripStageHint(i18n, trip.status),
                      style: text.bodyMedium?.copyWith(
                        color: _hint,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (narrow && eta != null) ...[
                    const SizedBox(height: 8),
                    eta,
                  ],
                ],
              ),
            ),
            if (!narrow && eta != null) ...[
              const SizedBox(width: 12),
              Flexible(child: eta),
            ],
          ],
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CityBlock(
                        icon: Icons.trip_origin_rounded,
                        label: i18n.t('home.pickupLabel'),
                        city: pickup,
                        alignEnd: false,
                        reached: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CityBlock(
                        icon: Icons.flag_rounded,
                        label: i18n.t('home.deliveryLabel'),
                        city: delivery,
                        alignEnd: true,
                        reached: stage == CustomerTripProgress.delivered,
                      ),
                    ),
                  ],
                ),
                _AnimatedRoute(status: trip.status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _FactWrap(facts: facts)),
              const SizedBox(width: 16),
              follow,
            ],
          )
        else ...[
          if (facts.isNotEmpty) ...[
            _FactWrap(facts: facts),
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

(Color, Color) _statusColors(String? status) {
  return switch (CustomerTripProgress.stageOf(status)) {
    CustomerTripProgress.delivered => (
      AppColors.successSoft,
      AppColors.success,
    ),
    CustomerTripProgress.cancelled => (AppColors.dangerSoft, AppColors.danger),
    _ => (AppColors.amberSoft, _orange),
  };
}

/// How far the truck sits between pickup (0) and delivery (1).
double _settledProgress(String? status) {
  return switch (CustomerTripProgress.stageOf(status)) {
    CustomerTripProgress.loaded => 0.34,
    CustomerTripProgress.inTransit => 0.62,
    CustomerTripProgress.delivered => 1,
    CustomerTripProgress.cancelled => 0,
    _ => 0.16,
  };
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            bidiIsolate(reference),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _CityBlock extends StatelessWidget {
  const _CityBlock({
    required this.icon,
    required this.label,
    required this.city,
    required this.alignEnd,
    required this.reached,
  });

  final IconData icon;
  final String label;
  final String city;
  final bool alignEnd;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mark = _PlaceMark(icon: icon, reached: reached);
    final copy = Column(
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
        const SizedBox(height: 3),
        Text(
          bidiIsolate(city),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (context.isDesktop
                  ? text.titleLarge
                  : context.isCompact
                      ? text.titleSmall
                      : text.titleMedium)
              ?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alignEnd
          ? [Expanded(child: copy), const SizedBox(width: 8), mark]
          : [mark, const SizedBox(width: 8), Expanded(child: copy)],
    );
  }
}

class _PlaceMark extends StatelessWidget {
  const _PlaceMark({required this.icon, required this.reached});

  final IconData icon;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: reached ? AppColors.amberSoft : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: reached ? _orange : _track, width: 1.5),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: reached ? _orange : _muted),
      ),
    );
  }
}

class _AnimatedRoute extends StatefulWidget {
  const _AnimatedRoute({required this.status});

  final String? status;

  @override
  State<_AnimatedRoute> createState() => _AnimatedRouteState();
}

class _AnimatedRouteState extends State<_AnimatedRoute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel;

  @override
  void initState() {
    super.initState();
    _travel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
  }

  bool get _moving =>
      CustomerTripProgress.stageOf(widget.status) ==
      CustomerTripProgress.inTransit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _AnimatedRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced || !_moving) {
      _travel.stop();
      return;
    }
    if (!_travel.isAnimating) _travel.repeat(reverse: true);
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final settled = _settledProgress(widget.status);
    if (reduced || !_moving) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: reduced ? settled : 0, end: settled),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => _RouteTrack(
          progress: value,
          failed: CustomerTripProgress.isFailed(widget.status),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _travel,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_travel.value);
        return _RouteTrack(progress: 0.4 + (0.46 * t));
      },
    );
  }
}

class _RouteTrack extends StatelessWidget {
  const _RouteTrack({required this.progress, this.failed = false});

  final double progress;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final amount = progress.clamp(0.0, 1.0);
    final accent = failed ? _muted : _orange;

    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const truck = 42.0;
          const inset = 8.0;
          final span = (width - (inset * 2)).clamp(0.0, width);
          final center = rtl
              ? width - inset - (span * amount)
              : inset + (span * amount);
          final left = (center - (truck / 2)).clamp(0.0, width - truck);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                child: SizedBox(
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: _track),
                        FractionallySizedBox(
                          widthFactor: amount,
                          alignment: AlignmentDirectional.centerStart,
                          child: ColoredBox(color: accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                child: _EndDot(active: !failed, color: accent),
              ),
              PositionedDirectional(
                end: 0,
                child: _EndDot(active: amount >= 0.98, color: accent),
              ),
              Positioned(
                left: left,
                child: _TruckMarker(color: accent, rtl: rtl),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EndDot extends StatelessWidget {
  const _EndDot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: active ? color : _track, width: 2),
      ),
    );
  }
}

class _TruckMarker extends StatelessWidget {
  const _TruckMarker({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Transform.flip(
          flipX: rtl,
          child: Icon(Icons.local_shipping_rounded, size: 20, color: color),
        ),
      ),
    );
  }
}

class _FactWrap extends StatelessWidget {
  const _FactWrap({required this.facts});

  final List<Widget> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in facts)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: fact,
              ),
          ],
        );
      },
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _orange),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              style: text.labelMedium?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              bidiIsolate(value),
              maxLines: 1,
              style: text.labelLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.live,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (live) _PulseRing(color: foreground),
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: foreground.withValues(alpha: 0.28)),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: foreground, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color});

  final Color color;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
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
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Transform.scale(
          scale: 1 + (_pulse.value * 0.18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.28 * (1 - _pulse.value)),
            ),
            child: const SizedBox(width: 40, height: 40),
          ),
        );
      },
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
        Row(
          children: [
            _Bone(width: 40, height: 40, radius: 20),
            SizedBox(width: 12),
            Expanded(child: _Bone(width: double.infinity, height: 16)),
          ],
        ),
        SizedBox(height: 18),
        _Bone(width: double.infinity, height: 92, radius: 18),
        SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Bone(width: 180, height: 40),
        ),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, this.radius = 8});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _line,
        borderRadius: BorderRadius.circular(radius),
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
