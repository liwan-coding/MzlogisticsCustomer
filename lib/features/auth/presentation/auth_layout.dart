import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/widgets/brand_mark.dart';

class AuthLayout extends ConsumerWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final localeCode = i18n.locale.languageCode;
    final narrow = MediaQuery.sizeOf(context).width < 400;
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, narrow ? 22 : 32, narrow ? 16 : 28, narrow ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: (narrow
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              SizedBox(height: narrow ? 18 : 28),
              child,
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const BrandMark(size: 36),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: i18n.t('common.language'),
                    initialValue: localeCode,
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      ref.read(i18nControllerProvider.notifier).setLocale(value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'en',
                        height: 44,
                        child: _LanguageChoice(
                          label: i18n.t('common.english'),
                          selected: localeCode == 'en',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ar',
                        height: 44,
                        child: _LanguageChoice(
                          label: i18n.t('common.arabic'),
                          selected: localeCode == 'ar',
                        ),
                      ),
                    ],
                    child: const _LanguageButton(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: context.isDesktop
                  ? Row(
                      children: [
                        SizedBox(
                          width: (context.screenWidth * 0.38).clamp(400.0, 560.0),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.navyDeep,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const BrandMark(size: 56, light: true),
                                        const SizedBox(height: 28),
                                        Text(
                                          i18n.t('app.tagline'),
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: 40,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.accentGradient,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: form,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: form,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        if (selected) ...[
          const SizedBox(width: 12),
          const Icon(Icons.check_rounded, size: 18, color: AppColors.orange),
        ],
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.navySoft,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _GlobeIconPainter()),
      ),
    );
  }
}

class _GlobeIconPainter extends CustomPainter {
  const _GlobeIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 0.8;

    canvas.drawCircle(center, radius, stroke);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 0.88, height: radius * 2),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
