import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/bidi_text.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/hero_edge.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../shipments/data/shipment_model.dart';
import '../../shipments/data/truck_type.dart';
import '../../shipments/presentation/shipment_providers.dart';
import '../data/dashboard_model.dart';
import 'home_footer.dart';
import 'home_providers.dart';

const _heroImage = 'assets/images/home backround.png';
const _truckPlaceholder = 'assets/images/truck_placeholder.jpg';
const _orange = Color(0xFFF15A22);
const _ink = Color(0xFF1C2430);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE7E9EF);
const _canvas = Color(0xFFF7F8FB);

double _sectionGap(bool wide) => wide ? 48 : 32;

EdgeInsets _sectionPadding(bool wide) {
  return EdgeInsets.fromLTRB(wide ? 40 : 16, _sectionGap(wide), wide ? 40 : 16, 0);
}

BoxDecoration _homePanel() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(color: Color(0x101C2430), blurRadius: 28, offset: Offset(0, 14)),
    ],
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final dashboard = ref.watch(dashboardProvider);
    final shipments = ref.watch(shipmentsProvider);

    return AsyncBody<DashboardSummary>(
      value: dashboard,
      i18n: i18n,
      onRetry: () => ref.invalidate(dashboardProvider),
      builder: (summary) {
        return Material(
          color: _canvas,
          child: RefreshIndicator(
            color: _orange,
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(shipmentsProvider);
              ref.invalidate(truckTypesProvider);
              await Future.wait([
                ref.read(dashboardProvider.future),
                ref.read(shipmentsProvider.future),
                ref.read(truckTypesProvider.future),
              ]);
            },
            child: shipments.when(
              loading: () => _HomeBody(
                i18n: i18n,
                summary: summary,
                loadingShipments: true,
              ),
              error: (error, _) => _HomeBody(
                i18n: i18n,
                summary: summary,
                shipmentsError: error,
                onRetryShipments: () => ref.invalidate(shipmentsProvider),
              ),
              data: (page) => _HomeBody(
                i18n: i18n,
                summary: summary,
                shipments: page.items,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.i18n,
    required this.summary,
    this.shipments = const [],
    this.loadingShipments = false,
    this.shipmentsError,
    this.onRetryShipments,
  });

  final I18nBundle i18n;
  final DashboardSummary summary;
  final List<ShipmentRequest> shipments;
  final bool loadingShipments;
  final Object? shipmentsError;
  final VoidCallback? onRetryShipments;

  @override
  Widget build(BuildContext context) {
    final wide = context.isDesktop;
    final featured = shipments.isEmpty ? null : shipments.first;
    return _HomeScroller(
      children: [
        _Hero(
          i18n: i18n,
          wide: wide,
          from: _city(featured?.pickupCity, featured?.pickupAddress),
          to: _city(featured?.deliveryCity, featured?.deliveryAddress),
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
        _ScrollReveal(child: _FleetTypes(i18n: i18n, wide: wide)),
        _ScrollReveal(child: _QuickAction(i18n: i18n, wide: wide)),
        _ScrollReveal(child: _Glance(i18n: i18n, summary: summary, wide: wide)),
        _ScrollReveal(
          child: shipmentsError != null
              ? Padding(
                  padding: _sectionPadding(wide).copyWith(bottom: _sectionGap(wide)),
                  child: ErrorState(
                    i18n: i18n,
                    error: shipmentsError!,
                    onRetry: onRetryShipments,
                  ),
                )
              : _RecentShipments(
                  i18n: i18n,
                  shipments: shipments,
                  loading: loadingShipments,
                  wide: wide,
                ),
        ),
        if (wide) const HomeFooter(),
      ],
    );
  }
}

class _RevealBus extends ChangeNotifier {
  void ping() {
    if (hasListeners) notifyListeners();
  }
}

class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.bus, required this.scroll, required super.child});

  final _RevealBus bus;
  final ScrollController scroll;

  static _RevealScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RevealScope>();
  }

  @override
  bool updateShouldNotify(covariant _RevealScope oldWidget) {
    return bus != oldWidget.bus || scroll != oldWidget.scroll;
  }
}

class _HomeScroller extends StatefulWidget {
  const _HomeScroller({required this.children});

  final List<Widget> children;

  @override
  State<_HomeScroller> createState() => _HomeScrollerState();
}

class _HomeScrollerState extends State<_HomeScroller> {
  final _scroll = ScrollController();
  final _bus = _RevealBus();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_bus.ping);
  }

  @override
  void dispose() {
    _scroll.removeListener(_bus.ping);
    _scroll.dispose();
    _bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RevealScope(
      bus: _bus,
      scroll: _scroll,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: widget.children,
      ),
    );
  }
}

class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({required this.child});

  final Widget child;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  _RevealBus? _bus;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 860));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = _RevealScope.maybeOf(context)?.bus;
    if (!identical(_bus, bus)) {
      _bus?.removeListener(_onScroll);
      _bus = bus;
      _bus?.addListener(_onScroll);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _started = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }
  }

  void _onScroll() {
    if (!mounted || _started) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _started = true;
      return;
    }
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) return;
    final top = object.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * 0.98) {
      _started = true;
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _bus?.removeListener(_onScroll);
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 72),
            child: Transform.scale(
              scale: 0.94 + (0.06 * t),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _HeroMotion extends StatelessWidget {
  const _HeroMotion({required this.child, this.parallax = false});

  final Widget child;
  final bool parallax;

  @override
  Widget build(BuildContext context) {
    final scroll = _RevealScope.maybeOf(context)?.scroll;
    if (scroll == null || MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedBuilder(
      animation: scroll,
      child: child,
      builder: (context, child) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        if (parallax) {
          return Transform.translate(
            offset: Offset(0, offset * 0.42),
            child: Transform.scale(scale: 1.38, child: child),
          );
        }
        final fade = (1 - offset / 220).clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, offset * 0.28),
            child: child,
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.i18n,
    required this.wide,
    required this.from,
    required this.to,
    required this.rtl,
  });

  final I18nBundle i18n;
  final bool wide;
  final String? from;
  final String? to;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: wide ? 520 : 400),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const HeroEdgeClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroMotion(
                    parallax: true,
                    child: Image.asset(
                      _heroImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 0.9,
                        colors: [
                          Color(0xC4102033),
                          Color(0x88102033),
                          Color(0x00102033),
                        ],
                        stops: [0.15, 0.48, 0.82],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(wide ? 56 : 20, wide ? 118 : 24, wide ? 56 : 20, wide ? 120 : 88),
              child: _HeroMotion(
                child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        i18n.t('home.eyebrow'),
                        textAlign: TextAlign.center,
                        style: text.labelMedium?.copyWith(
                          color: const Color(0xFFE8EEF6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: rtl ? 0 : 0.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        i18n.t('home.heroLead'),
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          fontSize: wide ? 72 : 44,
                        ),
                      ),
                      Text(
                        i18n.t('home.heroAccent'),
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          color: _orange,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          fontSize: wide ? 72 : 44,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        i18n.t('home.heroBody'),
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: const Color(0xFFE4EAF2),
                          height: 1.45,
                          fontSize: wide ? 20 : 17,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _OrangeButton(
                        label: i18n.t('home.newShipment'),
                        icon: Icons.add,
                        pulse: true,
                        large: wide,
                        onPressed: () => context.push('/shipments/new'),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _EdgeRoad(from: from, to: to, rtl: rtl),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// The photograph is cut along this road. The truck travels on that edge
/// from pickup to delivery.
class _EdgeRoad extends StatefulWidget {
  const _EdgeRoad({required this.from, required this.to, required this.rtl});

  final String? from;
  final String? to;
  final bool rtl;

  @override
  State<_EdgeRoad> createState() => _EdgeRoadState();
}

class _EdgeRoadState extends State<_EdgeRoad> with SingleTickerProviderStateMixin {
  late final AnimationController _travel;

  @override
  void initState() {
    super.initState();
    _travel = AnimationController(vsync: this, duration: const Duration(milliseconds: 14000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _travel
        ..stop()
        ..value = 0.42;
    } else if (!_travel.isAnimating) {
      _travel.repeat();
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width < 2 || size.height < 2) return const SizedBox.shrink();
        final road = HeroEdge(size).road(rtl: widget.rtl);
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _travel,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _EdgeRoadPainter(
                progress: _travel.value,
                road: road,
                showPins: widget.from != null && widget.to != null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgeRoadPainter extends CustomPainter {
  const _EdgeRoadPainter({required this.progress, required this.road, required this.showPins});

  final double progress;
  final Path road;
  final bool showPins;

  @override
  void paint(Canvas canvas, Size size) {
    final path = road;
    final metric = path.computeMetrics().single;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x59000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xF0121822),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xB3FFFFFF),
    );

    if (showPins) {
      _paintPin(canvas, metric.getTangentForOffset(0)!.position);
      _paintPin(canvas, metric.getTangentForOffset(math.max(0, metric.length - 0.4))!.position);
    }

    final fadeIn = (progress / 0.07).clamp(0.0, 1.0).toDouble();
    final fadeOut = ((1 - progress) / 0.07).clamp(0.0, 1.0).toDouble();
    final pose = _pose(metric, progress);
    _paintTruck(canvas, pose.$1, pose.$2, math.min(fadeIn, fadeOut));
  }

  (Offset, double) _pose(PathMetric metric, double t) {
    final length = metric.length;
    final limit = math.max(0.0, length - 0.4);
    final distance = (length * t.clamp(0.0, 1.0)).clamp(0.0, limit).toDouble();
    final center = metric.getTangentForOffset(distance)!.position;
    const span = 22.0;
    final back = metric.getTangentForOffset((distance - span).clamp(0.0, limit).toDouble())!.position;
    final front = metric.getTangentForOffset((distance + span).clamp(0.0, limit).toDouble())!.position;
    final delta = front - back;
    final angle = delta.distance < 0.5 ? metric.getTangentForOffset(distance)!.angle : math.atan2(delta.dy, delta.dx);
    return (center, angle);
  }

  void _paintPin(Canvas canvas, Offset point) {
    canvas.drawCircle(
      point,
      10,
      Paint()
        ..color = _orange.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(point, 6.2, Paint()..color = Colors.white);
    canvas.drawCircle(point, 4.4, Paint()..color = _orange);
  }

  void _paintTruck(Canvas canvas, Offset position, double angle, double opacity) {
    if (opacity <= 0) return;
    Color tone(Color color) => color.withValues(alpha: color.a * opacity);
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    // Wheels stay on the road. The body stays on the photograph side.
    if (math.cos(angle) < 0) canvas.scale(1, -1);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1), width: 72, height: 9),
      Paint()
        ..color = tone(const Color(0x59000000))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final body = Paint()..color = tone(Colors.white);
    final accent = Paint()..color = tone(_orange);
    final glass = Paint()..color = tone(const Color(0xFF243040));
    final chassis = Paint()..color = tone(const Color(0xFF1C2430));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-42, -28, 4, -10), const Radius.circular(2.4)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-40, -18, 2, -15.4), const Radius.circular(1)),
      accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(5, -24, 28, -10),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(6),
        bottomRight: const Radius.circular(2),
        bottomLeft: const Radius.circular(1),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(18, -22, 26, -15), const Radius.circular(1.6)),
      glass,
    );
    canvas.drawRect(const Rect.fromLTRB(-40, -10, 26, -7.4), chassis);
    void wheelAt(double x) {
      canvas.drawCircle(Offset(x, -5.2), 5.2, chassis);
      canvas.drawCircle(Offset(x, -5.2), 2.1, body);
    }

    wheelAt(-30);
    wheelAt(-14);
    wheelAt(18);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EdgeRoadPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.road != road || oldDelegate.showPins != showPins;
  }
}

class _FleetTypes extends ConsumerWidget {
  const _FleetTypes({required this.i18n, required this.wide});

  final I18nBundle i18n;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(truckTypesProvider);
    return types.when(
      loading: () => _FleetFrame(
        wide: wide,
        title: i18n.t('home.fleetTitle'),
        child: const _FleetSkeleton(),
      ),
      error: (_, _) => _FleetFrame(
        wide: wide,
        title: i18n.t('home.fleetTitle'),
        child: TextButton(
          onPressed: () => ref.invalidate(truckTypesProvider),
          child: Text(i18n.t('shipment.truckTypesFailed')),
        ),
      ),
      data: (items) {
        final visible = items.where((type) => type.displayName(i18n.locale.languageCode).isNotEmpty).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return _FleetFrame(
          wide: wide,
          title: i18n.t('home.fleetTitle'),
          child: _FleetStrip(types: visible, locale: i18n.locale.languageCode, wide: wide),
        );
      },
    );
  }
}

class _FleetFrame extends StatelessWidget {
  const _FleetFrame({required this.wide, required this.title, required this.child});

  final bool wide;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _sectionPadding(wide),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetStrip extends StatefulWidget {
  const _FleetStrip({required this.types, required this.locale, required this.wide});

  final List<TruckTypeOption> types;
  final String locale;
  final bool wide;

  @override
  State<_FleetStrip> createState() => _FleetStripState();
}

class _FleetStripState extends State<_FleetStrip> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _drift
        ..stop()
        ..value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.wide) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
          const gap = 8.0;
          final more = widget.types.length > 4;
          const peek = 30.0;
          final reserved = more ? gap + peek : 0.0;
          final size = ((viewport - gap * 3 - reserved) / 4).clamp(52.0, 88.0);
          return _strip(size: size, small: size, gap: gap, labelHeight: 40, scroll: true);
        },
      );
    }

    const large = 132.0;
    const small = 88.0;
    return _strip(
      size: large,
      small: small,
      gap: 22,
      labelHeight: 40,
      scroll: widget.types.length > 7,
    );
  }

  Widget _strip({
    required double size,
    required double small,
    required double gap,
    required double labelHeight,
    required bool scroll,
  }) {
    return SizedBox(
      height: size + 28 + labelHeight,
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          Widget mark(int index) {
            final type = widget.types[index];
            final prominent = index.isEven;
            final circle = prominent ? size : small;
            final phase = (index * 0.17) % 1;
            final travel = (_drift.value + phase) % 1;
            final bob = (math.sin(travel * math.pi * 2) + 1) / 2;
            final lift = MediaQuery.disableAnimationsOf(context) ? 0.0 : -bob * (prominent ? 8 : 5);
            final name = type.displayName(widget.locale);
            final itemWidth = circle + (widget.wide ? 12 : 0);
            return SizedBox(
              width: itemWidth,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, lift),
                  child: Semantics(
                    label: name,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FleetCircle(type: type, size: circle, prominent: prominent),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: itemWidth,
                          height: labelHeight,
                          child: Text(
                            bidiIsolate(name),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
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

          if (!scroll) {
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < widget.types.length; index++) ...[
                      if (index > 0) SizedBox(width: gap),
                      mark(index),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsetsDirectional.only(end: 4),
            itemCount: widget.types.length,
            separatorBuilder: (_, _) => SizedBox(width: gap),
            itemBuilder: (context, index) => mark(index),
          );
        },
      ),
    );
  }
}

class _FleetCircle extends StatelessWidget {
  const _FleetCircle({required this.type, required this.size, required this.prominent});

  final TruckTypeOption type;
  final double size;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: prominent ? _orange : const Color(0xFFD5D8E0), width: prominent ? 2.5 : 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F1C2430),
            blurRadius: prominent ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFFE7E9EF),
          child: _FleetPhoto(url: type.imageUrl),
        ),
      ),
    );
  }
}

class _FleetPhoto extends StatelessWidget {
  const _FleetPhoto({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(
      _truckPlaceholder,
      fit: BoxFit.cover,
      alignment: const Alignment(-0.35, 0),
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE7E9EF),
        child: Icon(Icons.local_shipping_outlined, color: _muted),
      ),
    );
    final source = url;
    if (source == null || source.isEmpty) return asset;
    return Image.network(
      source,
      fit: BoxFit.cover,
      alignment: const Alignment(-0.35, 0),
      errorBuilder: (_, _, _) => asset,
    );
  }
}

class _FleetSkeleton extends StatelessWidget {
  const _FleetSkeleton();

  @override
  Widget build(BuildContext context) {
    final wide = context.isDesktop;
    final circle = wide ? 108.0 : 72.0;
    return SizedBox(
      height: wide ? 128 : circle + 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) => Container(
          width: wide && index.isOdd ? 74 : circle,
          height: wide && index.isOdd ? 74 : circle,
          decoration: const BoxDecoration(color: Color(0xFFE7E9EF), shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _JourneyStep {
  const _JourneyStep({required this.title, required this.body, required this.icon, this.accent = false});

  final String title;
  final String body;
  final IconData icon;
  final bool accent;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.i18n, required this.wide});

  final I18nBundle i18n;
  final bool wide;

  List<_JourneyStep> _steps() {
    return [
      _JourneyStep(
        title: i18n.t('home.stepRequest'),
        body: i18n.t('home.stepRequestBody'),
        icon: Icons.article_outlined,
      ),
      _JourneyStep(
        title: i18n.t('home.stepQuotes'),
        body: i18n.t('home.stepQuotesBody'),
        icon: Icons.receipt_long_outlined,
      ),
      _JourneyStep(
        title: i18n.t('home.stepAccept'),
        body: i18n.t('home.stepAcceptBody'),
        icon: Icons.task_alt,
      ),
      _JourneyStep(
        title: i18n.t('home.stepTrack'),
        body: i18n.t('home.stepTrackBody'),
        icon: Icons.location_on_outlined,
        accent: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final openNew = () => context.push('/shipments/new');
    final steps = _steps();
    final intro = _QuickIntro(i18n: i18n, onPressed: openNew, expanded: !wide);
    return Padding(
      padding: _sectionPadding(wide),
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
                BoxShadow(color: Color(0x101C2430), blurRadius: 28, offset: Offset(0, 14)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _QuickWash())),
                  Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 32 : 18, wide ? 26 : 18, wide ? 28 : 18, wide ? 26 : 18),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 4, child: intro),
                              const SizedBox(width: 12),
                              Expanded(flex: 7, child: _QuickJourney(steps: steps)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              intro,
                              const SizedBox(height: 20),
                              _QuickJourney(steps: steps, vertical: true),
                            ],
                          ),
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

class _QuickWash extends CustomPainter {
  const _QuickWash();

  @override
  void paint(Canvas canvas, Size size) {
    final lower = Path()
      ..moveTo(size.width * 0.46, size.height)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.18, size.width, size.height * 0.22)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lower, Paint()..color = const Color(0xFFF3F6FA));
    final upper = Path()
      ..moveTo(size.width * 0.58, 0)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.62, size.width, size.height * 0.28)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(upper, Paint()..color = const Color(0xFFF7F9FC));
  }

  @override
  bool shouldRepaint(covariant _QuickWash oldDelegate) => false;
}

class _QuickIntro extends StatelessWidget {
  const _QuickIntro({required this.i18n, required this.onPressed, required this.expanded});

  final I18nBundle i18n;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final english = i18n.locale.languageCode == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(
              i18n.t('home.quickAction'),
              style: text.labelMedium?.copyWith(
                color: _orange,
                fontWeight: FontWeight.w700,
                letterSpacing: english ? 0.6 : 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          i18n.t('home.quickTitle'),
          style: text.headlineSmall?.copyWith(color: _ink, fontWeight: FontWeight.w800, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t('home.quickBody'),
          style: text.bodyMedium?.copyWith(color: _muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        _OrangeButton(
          label: i18n.t('home.newShipment'),
          icon: Icons.add,
          expanded: expanded,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _QuickJourney extends StatefulWidget {
  const _QuickJourney({required this.steps, this.vertical = false});

  final List<_JourneyStep> steps;
  final bool vertical;

  @override
  State<_QuickJourney> createState() => _QuickJourneyState();
}

class _QuickJourneyState extends State<_QuickJourney> with SingleTickerProviderStateMixin {
  late final AnimationController _ride;

  @override
  void initState() {
    super.initState();
    _ride = AnimationController(vsync: this, duration: const Duration(milliseconds: 11000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _ride
        ..stop()
        ..value = 0.18;
    } else if (!_ride.isAnimating) {
      _ride.repeat();
    }
  }

  @override
  void dispose() {
    _ride.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vertical) {
      return AnimatedBuilder(
        animation: _ride,
        builder: (context, _) => _VerticalJourney(steps: widget.steps, progress: _ride.value),
      );
    }
    return AnimatedBuilder(
      animation: _ride,
      builder: (context, _) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _JourneyTrackPainter(progress: _ride.value, rtl: rtl),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final step in widget.steps) Expanded(child: _StepTile(step: step)),
              ],
            ),
          ],
        );
      },
    );
  }
}

Path _journeyPath(Size size, {required bool rtl}) {
  const y = 26.0;
  final start = size.width / 8;
  final end = size.width - start;
  final path = Path()
    ..moveTo(start, y)
    ..cubicTo(size.width * 0.22, y - 5, size.width * 0.38, y + 5, size.width * 0.5, y)
    ..cubicTo(size.width * 0.64, y - 5, size.width * 0.8, y + 4, end, y);
  if (!rtl) return path;
  final mirror = Matrix4.identity()
    ..translateByDouble(size.width, 0, 0, 1)
    ..scaleByDouble(-1, 1, 1, 1);
  return path.transform(mirror.storage);
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final _JourneyStep step;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: step.accent ? const Color(0xFFE7F6F1) : const Color(0xFFF3F5F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            step.icon,
            size: 22,
            color: step.accent ? const Color(0xFF1C8C6E) : const Color(0xFF3D4654),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelLarge?.copyWith(color: _ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          step.body,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: _muted, height: 1.3),
        ),
      ],
    );
  }
}

class _VerticalJourney extends StatelessWidget {
  const _VerticalJourney({required this.steps, required this.progress});

  final List<_JourneyStep> steps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    const tile = 76.0;
    final height = steps.length * tile;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 21,
            top: 22,
            bottom: 22,
            width: 2,
            child: CustomPaint(
              painter: _VerticalDashPainter(progress: _journeyTravel(progress)),
            ),
          ),
          Column(
            children: [
              for (final step in steps)
                SizedBox(
                  height: tile,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: step.accent ? const Color(0xFFE7F6F1) : const Color(0xFFF3F5F8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          step.icon,
                          size: 20,
                          color: step.accent ? const Color(0xFF1C8C6E) : const Color(0xFF3D4654),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(color: _ink, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              step.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: _muted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JourneyTrackPainter extends CustomPainter {
  const _JourneyTrackPainter({required this.progress, required this.rtl});

  final double progress;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _journeyPath(size, rtl: rtl).computeMetrics().single;
    final traveled = metric.length * _journeyTravel(progress);
    _dash(canvas, metric, 0, metric.length, const Color(0xFFD5DAE3));
    _dash(canvas, metric, 0, traveled, _orange);
  }

  void _dash(Canvas canvas, PathMetric metric, double from, double to, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color;
    var distance = from;
    while (distance < to) {
      final next = math.min(distance + 5, to);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyTrackPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rtl != rtl;
  }
}

double _journeyTravel(double progress) {
  return Curves.easeInOut.transform(progress.clamp(0.0, 1.0).toDouble());
}

class _VerticalDashPainter extends CustomPainter {
  const _VerticalDashPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD5DAE3);
    final hot = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = _orange;
    final limit = size.height * progress.clamp(0.0, 1.0);
    var y = 0.0;
    while (y < size.height) {
      final next = math.min(y + 5, size.height);
      canvas.drawLine(Offset(0, y), Offset(0, next), y < limit ? hot : paint);
      y += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashPainter oldDelegate) => oldDelegate.progress != progress;
}

class _GlanceCard {
  const _GlanceCard({
    required this.tint,
    required this.accent,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final Color tint;
  final Color accent;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
}

class _Glance extends StatelessWidget {
  const _Glance({required this.i18n, required this.summary, required this.wide});

  final I18nBundle i18n;
  final DashboardSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GlanceCard(
        tint: const Color(0xFFEEF3FF),
        accent: const Color(0xFF3B6FD8),
        icon: Icons.local_shipping_outlined,
        value: '${summary.tripsInTransit}',
        label: i18n.t('home.tripsInTransit'),
        onTap: () => context.go('/jobs'),
      ),
      _GlanceCard(
        tint: const Color(0xFFE8F7EF),
        accent: const Color(0xFF1F9D62),
        icon: Icons.receipt_long_outlined,
        value: '${summary.invoicesCount}',
        label: i18n.t('home.invoices'),
        onTap: () => context.go(wide ? '/invoices' : '/billing'),
      ),
      _GlanceCard(
        tint: const Color(0xFFFFF1EA),
        accent: _orange,
        icon: Icons.description_outlined,
        value: '${summary.quotationsPending}',
        label: i18n.t('home.quotationsPending'),
        onTap: () => context.go('/shipments'),
      ),
      _GlanceCard(
        tint: const Color(0xFFF3EEFF),
        accent: const Color(0xFF7C5CD6),
        icon: Icons.inventory_2_outlined,
        value: '${summary.shipmentsTotal}',
        label: i18n.t('home.shipmentsTotal'),
        onTap: () => context.go('/shipments'),
      ),
    ];
    return Padding(
      padding: _sectionPadding(wide),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeading(title: i18n.t('home.glanceTitle')),
              const SizedBox(height: 16),
              if (wide) _GlanceBoard(cards: cards) else _GlanceStack(cards: cards),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: _ink,
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: titleStyle),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _GlanceStack extends StatelessWidget {
  const _GlanceStack({required this.cards});

  final List<_GlanceCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 28.0;
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final size = math.min(118.0, (width - gap) / 2 * 0.86);
        return Align(
          alignment: Alignment.center,
          child: Wrap(
            spacing: gap,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              for (final card in cards) _GlanceOrb(card: card, size: size),
            ],
          ),
        );
      },
    );
  }
}

class _GlanceOrb extends StatelessWidget {
  const _GlanceOrb({required this.card, required this.size});

  final _GlanceCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = '${card.value} ${card.label}';
    return SizedBox(
      width: size,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: card.onTap,
          customBorder: const CircleBorder(),
          child: Column(
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _OrbRingPainter(tint: card.tint, accent: card.accent),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(card.icon, size: 18, color: card.accent),
                      const SizedBox(height: 4),
                      Text(
                        card.value,
                        style: text.headlineSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          fontSize: size < 110 ? 24 : 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: Text(
                  card.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  const _OrbRingPainter({required this.tint, required this.accent});

  final Color tint;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    canvas.drawCircle(center, radius - 4, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = tint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.35,
      1.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbRingPainter oldDelegate) {
    return oldDelegate.tint != tint || oldDelegate.accent != accent;
  }
}

class _GlanceBoard extends StatelessWidget {
  const _GlanceBoard({required this.cards});

  final List<_GlanceCard> cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        children: [
          const Positioned(top: 0, left: 18, right: 18, height: 52, child: _GlanceRoute()),
          Positioned(
            top: 44,
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: _GlanceTile(card: cards[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlanceTile extends StatelessWidget {
  const _GlanceTile({required this.card});

  final _GlanceCard card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: card.tint,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: card.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              left: 18,
              right: 18,
              bottom: 12,
              height: 22,
              child: CustomPaint(painter: _CardWavePainter(card.accent)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Icon(card.icon, color: card.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.value,
                          style: text.headlineSmall?.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: _muted, height: 1.25),
                        ),
                      ],
                    ),
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

class _CardWavePainter extends CustomPainter {
  const _CardWavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.05, size.width * 0.52, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.74, size.height, size.width, size.height * 0.28);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CardWavePainter oldDelegate) => oldDelegate.color != color;
}

class _GlanceRoute extends StatefulWidget {
  const _GlanceRoute();

  @override
  State<_GlanceRoute> createState() => _GlanceRouteState();
}

class _GlanceRouteState extends State<_GlanceRoute> with SingleTickerProviderStateMixin {
  late final AnimationController _ride;

  @override
  void initState() {
    super.initState();
    _ride = AnimationController(vsync: this, duration: const Duration(milliseconds: 14000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ride
        ..stop()
        ..value = 0.35;
    } else if (!_ride.isAnimating) {
      _ride.repeat();
    }
  }

  @override
  void dispose() {
    _ride.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ride,
        builder: (context, _) {
          return CustomPaint(
            painter: _GlanceRoutePainter(progress: _ride.value, rtl: rtl),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _GlanceRoutePainter extends CustomPainter {
  const _GlanceRoutePainter({required this.progress, required this.rtl});

  final double progress;
  final bool rtl;

  Path _path(Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(size.width * 0.12, size.height * 0.12, size.width * 0.22, size.height * 0.95, size.width * 0.36, size.height * 0.48)
      ..cubicTo(size.width * 0.5, size.height * 0.05, size.width * 0.64, size.height * 0.9, size.width * 0.78, size.height * 0.4)
      ..cubicTo(size.width * 0.88, size.height * 0.12, size.width * 0.94, size.height * 0.55, size.width, size.height * 0.34);
    if (!rtl) return path;
    final mirror = Matrix4.identity()
      ..translateByDouble(size.width, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);
    return path.transform(mirror.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final metric = path.computeMetrics().single;
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD5DAE3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final traveled = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    canvas.drawPath(
      traveled,
      Paint()
        ..color = _orange.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    const tones = [Color(0xFF3B6FD8), Color(0xFF1F9D62), _orange, Color(0xFF7C5CD6)];
    for (var i = 0; i < tones.length; i++) {
      final point = metric.getTangentForOffset(metric.length * ((i + 0.5) / tones.length));
      if (point == null) continue;
      canvas.drawCircle(point.position, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(point.position, 3.4, Paint()..color = tones[i]);
    }
    final at = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0));
    if (at == null) return;
    canvas.save();
    canvas.translate(at.position.dx, at.position.dy);
    canvas.rotate(at.angle);
    if (math.cos(at.angle) < 0) canvas.scale(1, -1);
    final body = Paint()..color = const Color(0xFF243040);
    final glass = Paint()..color = const Color(0xFF8FB4D8);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(-16, -11, 2, -4), const Radius.circular(1.4)), body);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(2, -9, 12, -4), const Radius.circular(1.6)), body);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(6, -8, 11, -5.2), const Radius.circular(0.8)), glass);
    canvas.drawCircle(const Offset(-8, -2.2), 2.3, body);
    canvas.drawCircle(const Offset(7, -2.2), 2.3, body);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlanceRoutePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rtl != rtl;
  }
}

class _RecentShipments extends StatelessWidget {
  const _RecentShipments({
    required this.i18n,
    required this.shipments,
    required this.loading,
    required this.wide,
  });

  final I18nBundle i18n;
  final List<ShipmentRequest> shipments;
  final bool loading;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = shipments.take(6).toList();
    return Padding(
      padding: _sectionPadding(wide).copyWith(
        top: _sectionGap(wide) + (wide ? 28 : 20),
        bottom: _sectionGap(wide),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeading(
                title: i18n.t('home.recentShipments'),
                trailing: TextButton(
                  onPressed: () => context.go('/shipments'),
                  child: Text(i18n.t('home.viewAllShipments')),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: _homePanel(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 8, wide ? 28 : 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator(color: _orange)),
                        )
                      else if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Text(
                                i18n.t('home.noShipments'),
                                textAlign: TextAlign.center,
                                style: text.titleMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                i18n.t('home.emptyHint'),
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(color: _muted, height: 1.4),
                              ),
                            ],
                          ),
                        )
                      else
                        for (var i = 0; i < visible.length; i++)
                          _RecentRow(
                            key: ValueKey(visible[i].id),
                            i18n: i18n,
                            shipment: visible[i],
                            wide: wide,
                            divided: i < visible.length - 1,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    super.key,
    required this.i18n,
    required this.shipment,
    required this.wide,
    required this.divided,
  });

  final I18nBundle i18n;
  final ShipmentRequest shipment;
  final bool wide;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cargo = (shipment.cargoType ?? '').trim();
    final reference = (shipment.reference ?? '').trim();
    final when = shipment.requiredDate ?? shipment.createdAt;
    final weight = shipment.weightTons == null
        ? i18n.t('common.dash')
        : '${formatNumber(shipment.weightTons)} ${i18n.t('common.tons')}';
    final pickup = _place(i18n, shipment.pickupCity, shipment.pickupAddress);
    final delivery = _place(i18n, shipment.deliveryCity, shipment.deliveryAddress);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bidiIsolate(reference.isNotEmpty ? reference : (cargo.isEmpty ? weight : cargo)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(color: _ink, fontWeight: FontWeight.w700),
        ),
        if (reference.isNotEmpty && cargo.isNotEmpty)
          Text(bidiIsolate(cargo), maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: _muted)),
        Text(
          '${bidiIsolate(pickup)}  →  ${bidiIsolate(delivery)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: _ink, height: 1.3),
        ),
      ],
    );
    final stages = [
      i18n.t('home.stageCreated'),
      i18n.t('home.stageQuotes'),
      i18n.t('home.stageAccepted'),
    ];
    final track = _RequestTrack(labels: stages, index: _requestStage(shipment.status));
    final badge = StatusBadge(status: shipment.status ?? '', label: i18n.status(shipment.status));
    final whenText = Text(
      formatDate(when, locale: i18n.locale.languageCode),
      style: text.bodySmall?.copyWith(color: _muted),
    );
    return InkWell(
      onTap: () => context.push('/shipments/${shipment.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: divided ? const Border(bottom: BorderSide(color: _line)) : null,
        ),
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 4, child: identity),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: track),
                  const SizedBox(width: 12),
                  SizedBox(width: 96, child: Text(weight, style: text.bodyMedium?.copyWith(color: _ink))),
                  SizedBox(width: 112, child: whenText),
                  badge,
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 18, color: _muted),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$weight   ${formatDate(when, locale: i18n.locale.languageCode)}', style: text.bodySmall?.copyWith(color: _muted)),
                  const SizedBox(height: 8),
                  track,
                ],
              ),
      ),
    );
  }
}

int? _requestStage(String? status) {
  return switch (status) {
    'draft' => 0,
    'published' => 1,
    'awarded' => 2,
    _ => null,
  };
}

class _RequestTrack extends StatefulWidget {
  const _RequestTrack({required this.labels, required this.index});

  final List<String> labels;
  final int? index;

  @override
  State<_RequestTrack> createState() => _RequestTrackState();
}

class _RequestTrackState extends State<_RequestTrack> with SingleTickerProviderStateMixin {
  late final AnimationController _ride;

  @override
  void initState() {
    super.initState();
    _ride = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ride
        ..stop()
        ..value = 1;
    } else if (_ride.status == AnimationStatus.dismissed) {
      _ride.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _RequestTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _ride.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ride.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.labels.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final index = widget.index;
    return AnimatedBuilder(
      animation: _ride,
      builder: (context, _) {
        final travel = Curves.easeOutCubic.transform(_ride.value);
        final shown = index == null ? 0.0 : (index / (n - 1)) * travel;
        return SizedBox(
          height: 46,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / n;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    top: 7,
                    start: slot / 2,
                    end: slot / 2,
                    height: 2,
                    child: CustomPaint(
                      painter: _StageLinePainter(progress: shown, rtl: rtl),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: Column(
                            children: [
                              _StageNode(
                                done: index != null && i < index,
                                current: index != null && i == index,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.labels[i],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  height: 1.1,
                                  color: index != null && i == index ? _ink : _muted,
                                  fontWeight: index != null && i == index ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    const doneColor = Color(0xFF1F9D62);
    const idle = Color(0xFFE4E7EE);
    final color = done ? doneColor : (current ? _orange : idle);
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? doneColor : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: current ? 2 : 1.5),
        boxShadow: current
            ? const [BoxShadow(color: Color(0x47F15A22), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: done
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : (current
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                )
              : null),
    );
  }
}

class _StageLinePainter extends CustomPainter {
  const _StageLinePainter({required this.progress, required this.rtl});

  final double progress;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final base = Paint()
      ..color = const Color(0xFFE4E7EE)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), base);
    if (progress <= 0) return;
    final start = rtl ? size.width : 0.0;
    final end = rtl ? size.width * (1 - progress) : size.width * progress;
    canvas.drawLine(
      Offset(start, y),
      Offset(end, y),
      Paint()
        ..color = _orange
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StageLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rtl != rtl;
  }
}

class _OrangeButton extends StatelessWidget {
  const _OrangeButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.pulse = false,
    this.large = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;
  final bool pulse;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 24.0 : 18.0;
    final labelStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: large ? 18 : 14,
    );
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: Colors.white),
          SizedBox(width: large ? 10 : 6),
        ],
        if (expanded)
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          )
        else
          Text(label, style: labelStyle),
        SizedBox(width: large ? 12 : 8),
        Icon(Icons.arrow_forward, size: large ? 22 : 16, color: Colors.white),
      ],
    );
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        minimumSize: large ? const Size(0, 64) : null,
        padding: EdgeInsets.symmetric(horizontal: large ? 32 : 16, vertical: large ? 20 : 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(large ? 16 : 10)),
      ),
      child: child,
    );
    final sized = expanded ? SizedBox(width: double.infinity, child: button) : button;
    if (!pulse) return sized;
    return _PulsingButton(child: sized);
  }
}

class _PulsingButton extends StatefulWidget {
  const _PulsingButton({required this.child});

  final Widget child;

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
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
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final t = _pulse.value;
        final beat = math.sin(t * math.pi);
        return Transform.scale(
          scale: 1 + 0.045 * beat,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + 0.28 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _orange.withValues(alpha: 0.42 * (1 - t)),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.35 * beat),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
    );
  }
}

String? _city(String? city, String? address) {
  if (city != null && city.trim().isNotEmpty) return city.trim();
  if (address != null && address.trim().isNotEmpty) return address.trim();
  return null;
}

String _place(I18nBundle i18n, String? city, String? address) {
  return _city(city, address) ?? i18n.t('common.dash');
}
