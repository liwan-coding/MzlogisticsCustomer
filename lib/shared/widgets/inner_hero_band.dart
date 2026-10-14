import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'hero_edge.dart';
import 'hero_title_scope.dart';
import 'page_scaffold.dart';
import 'page_scroll.dart';

class InnerHeroBand extends StatelessWidget {
  const InnerHeroBand({super.key, required this.child, this.scroll});

  final Widget child;
  final ValueNotifier<double>? scroll;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final photo = const Image(
      image: AssetImage(heroPhoto),
      fit: BoxFit.cover,
      alignment: Alignment(0.55, 0.32),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: const HeroEdgeClipper(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (scroll == null || reduced)
                  photo
                else
                  AnimatedBuilder(
                    animation: scroll!,
                    child: photo,
                    builder: (context, child) {
                      final offset = scroll!.value;
                      return Transform.translate(
                        offset: Offset(0, offset * 0.32),
                        child: Transform.scale(scale: 1.22, child: child),
                      );
                    },
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xD4101A2B),
                        Color(0xA8102033),
                        Color(0x66102033),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: HeroRoadStrokePainter(rtl: rtl)),
          ),
        ),
        child,
      ],
    );
  }
}

/// Header and page title on a short hero. Detail screens publish their title
/// through [HeroTitleScope] when [pinned] is null.
class HeroBandHost extends StatefulWidget {
  const HeroBandHost({
    super.key,
    required this.header,
    required this.child,
    required this.location,
    this.pinned,
  });

  final Widget header;
  final Widget child;
  final String location;
  final HeroTitleData? pinned;

  @override
  State<HeroBandHost> createState() => _HeroBandHostState();
}

class _HeroBandHostState extends State<HeroBandHost> {
  final _titles = HeroTitleController();
  final _offset = ValueNotifier<double>(0);

  @override
  void didUpdateWidget(HeroBandHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _titles.reset();
      _offset.value = 0;
    }
  }

  @override
  void dispose() {
    _titles.dispose();
    _offset.dispose();
    super.dispose();
  }

  bool get _fills => widget.location.contains('/payments/checkout');

  Widget _band(BuildContext context) {
    final barSpace = MediaQuery.paddingOf(context).top + 14 + 64;
    return ListenableBuilder(
      listenable: _titles,
      builder: (context, _) {
        final title = widget.pinned ?? _titles.registered;
        return InnerHeroBand(
          scroll: _offset,
          child: Column(
            children: [
              SizedBox(height: barSpace),
              const SizedBox(height: 12),
              ContentWidth(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                child: title == null
                    ? const SizedBox(height: 44)
                    : PageHeading(
                        title: title.title,
                        subtitle: title.subtitle,
                        actions: title.actions,
                        showBack: title.showBack,
                        onBack: title.onBack,
                        onHero: true,
                      ),
              ),
              const SizedBox(height: 108),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeroTitleScope(
      controller: _titles,
      child: PageHeroScope(
        band: _band,
        inline: !_fills,
        child: ColoredBox(
          color: AppColors.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis != Axis.vertical) return false;
                  final pixels = notification.metrics.pixels;
                  if ((_offset.value - pixels).abs() >= 0.5) _offset.value = pixels;
                  return false;
                },
                child: _fills
                    ? Column(
                        children: [
                          _band(context),
                          Expanded(child: widget.child),
                        ],
                      )
                    : widget.child,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: widget.header,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
