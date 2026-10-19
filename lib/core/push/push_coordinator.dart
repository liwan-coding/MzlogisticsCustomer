import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../i18n/i18n_controller.dart';
import '../providers.dart';
import '../router/app_router.dart';
import 'push_notifications.dart';

final pushCoordinatorProvider = Provider<void>((ref) {
  PushNotifications.bindRouter(ref.watch(routerProvider));
  PushNotifications.onForeground = () {
    try {
      ref.invalidate(notificationsProvider);
    } catch (_) {}
  };
  ref.onDispose(() => PushNotifications.onForeground = null);

  String locale() {
    return ref.read(i18nControllerProvider).asData?.value.locale.languageCode ??
        'ar';
  }

  void sync(bool authenticated) {
    PushNotifications.setNavigationEnabled(authenticated);
    if (authenticated) {
      unawaited(PushNotifications.register(ref.read(apiClientProvider), locale()));
    }
  }

  ref.listen(authControllerProvider, (previous, next) {
    sync(next.isAuthenticated);
  });
  ref.listen(i18nControllerProvider, (previous, next) {
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    final code = next.asData?.value.locale.languageCode;
    final previousCode = previous?.asData?.value.locale.languageCode;
    if (code == null || code == previousCode) return;
    unawaited(PushNotifications.register(ref.read(apiClientProvider), code));
  });

  if (ref.read(authControllerProvider).isAuthenticated) {
    unawaited(Future<void>.microtask(() => sync(true)));
  }
});
