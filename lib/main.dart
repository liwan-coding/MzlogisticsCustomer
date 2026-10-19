import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/push/push_notifications.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.preloadFonts();
  await PushNotifications.start();
  runApp(const ProviderScope(child: MzCustomerApp()));
}
