import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/company_contact.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/breakpoints.dart';

const _orange = Color(0xFFF15A22);
const _bar = Color(0xFF101A2B);

class HomeFooter extends ConsumerWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final wide = context.isDesktop;
    final links = _footerColumns(context, i18n, wide);
    final brand = _FooterBrand(i18n: i18n);
    final contact = _FooterContact(i18n: i18n);
    return ColoredBox(
      color: _bar,
      child: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 48 : 20, wide ? 72 : 48, wide ? 48 : 20, 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: brand),
                        const SizedBox(width: 28),
                        for (final column in links) ...[
                          Expanded(flex: 2, child: column),
                          const SizedBox(width: 12),
                        ],
                        Expanded(flex: 4, child: contact),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        brand,
                        const SizedBox(height: 28),
                        contact,
                        const SizedBox(height: 28),
                        for (final column in links) ...[
                          column,
                          const SizedBox(height: 22),
                        ],
                      ],
                    ),
            ),
          ),
        ),
        const _FooterRoad(),
        _FooterBar(i18n: i18n, wide: wide),
      ],
      ),
    );
  }
}

List<Widget> _footerColumns(BuildContext context, I18nBundle i18n, bool wide) {
  return [
    _FooterColumn(
      title: i18n.t('footer.services'),
      links: [
        _FooterLink(i18n.t('home.newShipment'), () => context.push('/shipments/new')),
        _FooterLink(i18n.t('nav.shipments'), () => context.go('/shipments')),
        _FooterLink(i18n.t('nav.jobs'), () => context.go('/jobs')),
      ],
    ),
    _FooterColumn(
      title: i18n.t('footer.finance'),
      links: [
        _FooterLink(i18n.t('nav.invoices'), () => context.go(wide ? '/invoices' : '/billing')),
        _FooterLink(i18n.t('nav.payments'), () => context.go('/payments')),
        _FooterLink(i18n.t('nav.billing'), () => context.go('/billing')),
      ],
    ),
    _FooterColumn(
      title: i18n.t('footer.account'),
      links: [
        _FooterLink(i18n.t('nav.home'), () => context.go('/home')),
        _FooterLink(i18n.t('nav.profile'), () => context.go('/profile')),
        _FooterLink(i18n.t('nav.notifications'), () => context.go('/notifications')),
      ],
    ),
  ];
}

class _FooterLink {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand({required this.i18n});

  final I18nBundle i18n;

  @override
  Widget build(BuildContext context) {
    final name = i18n.t('app.name');
    final mark = name.lastIndexOf('X');
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mark < 0
            ? Text(name, style: style)
            : Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    TextSpan(text: name.substring(0, mark)),
                    TextSpan(text: name.substring(mark, mark + 1), style: const TextStyle(color: _orange)),
                    TextSpan(text: name.substring(mark + 1)),
                  ],
                ),
              ),
        const SizedBox(height: 12),
        Text(
          i18n.t('app.tagline'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t('home.heroBody'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFC5CDD8), height: 1.5),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});

  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final link in links)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC5CDD8),
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: AlignmentDirectional.centerStart,
              ),
              onPressed: link.onTap,
              child: Text(link.label),
            ),
          ),
      ],
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact({required this.i18n});

  final I18nBundle i18n;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.t('footer.contact'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _ContactChannel(
            label: i18n.t('footer.phone'),
            value: CompanyContact.phoneDisplay,
            icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 20),
            onTap: () => CompanyContact.open(CompanyContact.phoneUri),
          ),
          _ContactChannel(
            label: i18n.t('footer.whatsapp'),
            value: CompanyContact.phoneDisplay,
            icon: const CustomPaint(size: Size(20, 20), painter: _WhatsAppMark()),
            onTap: () => CompanyContact.open(CompanyContact.whatsappUri),
          ),
          _ContactChannel(
            label: i18n.t('footer.instagram'),
            value: CompanyContact.instagramHandle,
            icon: const CustomPaint(size: Size(20, 20), painter: _InstagramMark()),
            onTap: () => CompanyContact.open(CompanyContact.instagramUri),
          ),
        ],
      ),
    );
  }
}

class _ContactChannel extends StatelessWidget {
  const _ContactChannel({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0x22FFFFFF),
        highlightColor: const Color(0x14FFFFFF),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x99F15A22)),
                  ),
                  child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: const Color(0xFFC5CDD8), height: 1.3),
                      ),
                    ],
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

class _WhatsAppMark extends CustomPainter {
  const _WhatsAppMark();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final bubble = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.06, size.width * 0.74, size.height * 0.74),
          Radius.circular(size.width * 0.24),
        ),
      )
      ..moveTo(size.width * 0.28, size.height * 0.76)
      ..lineTo(size.width * 0.18, size.height * 0.94)
      ..lineTo(size.width * 0.46, size.height * 0.76);
    canvas.drawPath(bubble, stroke);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.46, size.height * 0.42), radius: size.width * 0.16),
      -0.9,
      2.4,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstagramMark extends CustomPainter {
  const _InstagramMark();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.08, size.width * 0.84, size.height * 0.84),
      Radius.circular(size.width * 0.24),
    );
    canvas.drawRRect(frame, stroke);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.2, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.055,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FooterRoad extends StatefulWidget {
  const _FooterRoad();

  @override
  State<_FooterRoad> createState() => _FooterRoadState();
}

class _FooterRoadState extends State<_FooterRoad> with SingleTickerProviderStateMixin {
  late final AnimationController _ride;

  @override
  void initState() {
    super.initState();
    _ride = AnimationController(vsync: this, duration: const Duration(milliseconds: 12000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ride
        ..stop()
        ..value = 0.62;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return SizedBox(
          height: compact ? 124 : 108,
          child: AnimatedBuilder(
            animation: _ride,
            builder: (context, _) {
              return CustomPaint(
                painter: _FooterRoadPainter(progress: _ride.value, rtl: rtl),
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      },
    );
  }
}

class _FooterRoadPainter extends CustomPainter {
  const _FooterRoadPainter({required this.progress, required this.rtl});

  final double progress;
  final bool rtl;

  Path _path(Size size) {
    final h = size.height;
    final w = size.width;
    final compact = w < 700;
    // Narrow screens use a shallower wave so the truck stays on the stroke
    // and is not clipped by the top or bottom of the band.
    final path = Path();
    if (compact) {
      path
        ..moveTo(0, h * 0.62)
        ..cubicTo(w * 0.22, h * 0.76, w * 0.38, h * 0.42, w * 0.56, h * 0.54)
        ..cubicTo(w * 0.74, h * 0.66, w * 0.88, h * 0.40, w, h * 0.56);
    } else {
      path
        ..moveTo(0, h * 0.78)
        ..cubicTo(w * 0.16, h * 0.95, w * 0.3, h * 0.34, w * 0.48, h * 0.52)
        ..cubicTo(w * 0.66, h * 0.72, w * 0.8, h * 0.30, w, h * 0.58);
    }
    if (!rtl) return path;
    final mirror = Matrix4.identity()
      ..translateByDouble(w, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);
    return path.transform(mirror.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 2 || size.height < 2) return;
    final path = _path(size);
    final metric = path.computeMetrics().single;
    final compact = size.width < 700;
    final scale = !compact ? 1.0 : (size.width < 380 ? 0.78 : 0.86);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5A6578)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final wheelSpan = 28.0 * scale;
    final tail = 10.0 * scale;
    final length = metric.length;
    final inset = math.min(wheelSpan / 2, length / 2);
    final pad = math.min(tail, math.max(0.0, length / 2 - inset));
    final drive = math.max(0.0, length - (inset + pad) * 2);
    final center = inset + pad + drive * progress.clamp(0.0, 1.0);
    final head = math.min(length, center + inset);
    canvas.drawPath(
      metric.extractPath(0, head),
      Paint()
        ..color = _orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    for (final stop in const [0.06, 0.5, 0.94]) {
      final point = metric.getTangentForOffset(metric.length * stop);
      if (point == null) continue;
      canvas.drawCircle(point.position, 7, Paint()..color = Colors.white);
      canvas.drawCircle(point.position, 4.2, Paint()..color = _orange);
    }
    final rear = metric.getTangentForOffset((center - inset).clamp(0.0, length).toDouble());
    final nose = metric.getTangentForOffset(head);
    if (rear == null || nose == null) return;
    final delta = nose.position - rear.position;
    final fallback = metric.getTangentForOffset(center.clamp(0.0, length).toDouble());
    final angle = delta.distance < 0.8 ? (fallback?.angle ?? 0) : math.atan2(delta.dy, delta.dx);
    _paintTruck(canvas, (rear.position + nose.position) / 2, angle, scale);
  }

  /// Wheels rest on the road sample. The heading is the chord under the
  /// wheelbase, so the body follows the curve instead of a single tangent.
  void _paintTruck(Canvas canvas, Offset origin, double angle, double scale) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    if (math.cos(angle) < 0) canvas.scale(1, -1);
    canvas.scale(scale);
    const wheelR = 3.2;
    final body = Paint()..color = const Color(0xFFF7F8FB);
    final line = Paint()
      ..color = const Color(0xFF243040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final trailer = RRect.fromRectAndRadius(const Rect.fromLTRB(-24, -17.2, 4, -5.4), const Radius.circular(2));
    final cab = RRect.fromRectAndRadius(const Rect.fromLTRB(4, -15.2, 20, -5.4), const Radius.circular(3));
    canvas.drawRRect(trailer, body);
    canvas.drawRRect(trailer, line);
    canvas.drawRRect(cab, body);
    canvas.drawRRect(cab, line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(10, -13.2, 18, -8.2), const Radius.circular(1)),
      Paint()..color = const Color(0xFF8FB4D8),
    );
    canvas.drawRect(const Rect.fromLTRB(-22, -11.2, 2, -9.2), Paint()..color = _orange);
    for (final x in const [-14.0, -2.0, 14.0]) {
      canvas.drawCircle(Offset(x, -wheelR), wheelR, Paint()..color = const Color(0xFF243040));
      canvas.drawCircle(Offset(x, -wheelR), 1.2, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FooterRoadPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rtl != rtl;
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({required this.i18n, required this.wide});

  final I18nBundle i18n;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bar,
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 18, wide ? 48 : 20, 18),
        child: Center(
          child: Text(
            '${i18n.t('footer.rights')} © ${i18n.t('app.name')} ${DateTime.now().year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFD5DBE3)),
          ),
        ),
      ),
    );
  }
}
