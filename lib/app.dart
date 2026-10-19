import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/i18n/i18n_controller.dart';
import 'core/push/push_coordinator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/error_state.dart';

class MzCustomerApp extends ConsumerWidget {
  const MzCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nControllerProvider);
    final router = ref.watch(routerProvider);
    ref.watch(pushCoordinatorProvider);
    const fallback = I18nBundle(locale: Locale('en'), strings: {});
    final bundle = i18n.asData?.value ?? fallback;

    if (i18n.hasError && !i18n.hasValue) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: ErrorState(
            i18n: fallback,
            error: i18n.error ?? 'error',
            onRetry: () => ref.invalidate(i18nControllerProvider),
          ),
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: bundle.t('app.name'),
      theme: AppTheme.light(bundle.locale),
      locale: bundle.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        final width = MediaQuery.sizeOf(context).width;
        if (width >= AppConstants.tabletBreakpoint) return content;
        final compact = width < AppConstants.compactBreakpoint;
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 14,
                vertical: compact ? 12 : 13,
              ),
            ),
          ),
          child: content,
        );
      },
    );
  }
}
