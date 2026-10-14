import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_mark.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final name = i18n.t('app.name');
    final mark = name.lastIndexOf('X');
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 64, light: true),
            const SizedBox(height: 20),
            mark < 0
                ? Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  )
                : Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(text: name.substring(0, mark)),
                  const TextSpan(text: 'X', style: TextStyle(color: AppColors.orange)),
                  TextSpan(text: name.substring(mark + 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              i18n.t('app.tagline'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onBar,
                  ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentFrom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
