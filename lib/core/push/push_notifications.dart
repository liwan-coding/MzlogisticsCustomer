import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import 'firebase_options.dart';

const _channel = AndroidNotificationChannel(
  'movex_alerts',
  'MoveX',
  description: 'Shipment and trip alerts',
  importance: Importance.high,
);

final _local = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotifications {
  static bool _ready = false;
  static bool _listening = false;
  static bool _navigationEnabled = false;
  static ApiClient? _api;
  static String _locale = 'ar';
  static String? _token;
  static GoRouter? _router;
  static String? _pending;
  static void Function()? onForeground;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> start() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: _onLocalTap,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      if (!_listening) {
        _listening = true;
        FirebaseMessaging.onMessage.listen((message) {
          unawaited(_show(message));
          onForeground?.call();
        });
        FirebaseMessaging.onMessageOpenedApp.listen((message) => open(message.data));
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
          unawaited(_publish(token));
        });
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) open(initial.data);
      _ready = true;
    } catch (error) {
      debugPrint('Push setup failed: $error');
    }
  }

  static void bindRouter(GoRouter router) {
    _router = router;
    _flush();
  }

  static void setNavigationEnabled(bool enabled) {
    _navigationEnabled = enabled;
    if (!enabled) {
      _pending = null;
      return;
    }
    _flush();
  }

  static void open(Map<String, dynamic> data) {
    final path = pathFor(data);
    if (path == null) return;
    _pending = path;
    _flush();
  }

  static Future<void> register(ApiClient api, String locale) async {
    if (!_ready) return;
    _api = api;
    _locale = locale == 'en' ? 'en' : 'ar';
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _publish(token);
    } catch (error) {
      debugPrint('Push registration failed: $error');
    }
  }

  static Future<void> unregister() async {
    _navigationEnabled = false;
    _pending = null;
    final api = _api;
    _api = null;
    if (!_ready || api == null) return;
    try {
      // ignore: deprecated_member_use
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await api.delete('/device-tokens', data: {'token': token});
    } catch (error) {
      debugPrint('Push unregister failed: $error');
    }
  }

  static Future<void> _publish(String token) async {
    final api = _api;
    if (api == null || token.isEmpty) return;
    _token = token;
    await api.post('/device-tokens', data: {
      'token': token,
      'platform': 'android',
      'app': 'customer',
      'locale': _locale,
    });
  }

  static void _flush() {
    if (!_navigationEnabled) return;
    final path = _pending;
    final router = _router;
    if (path == null || router == null) return;
    _pending = null;
    router.push(path);
  }

  static Future<void> _show(RemoteMessage message) async {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final rawId = message.messageId?.hashCode ?? message.hashCode;
    await _local.show(
      id: rawId.abs() % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'movex_alerts',
          'MoveX',
          channelDescription: 'Shipment and trip alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

void _onLocalTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      PushNotifications.open(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
  } catch (_) {}
}

String? pathFor(Map<String, dynamic> data) {
  final type = data['target_type']?.toString();
  final id = data['target_id']?.toString();
  final hasId = id != null && id.isNotEmpty;
  return switch (type) {
    'shipment' || 'platform_offer' => hasId ? '/shipments/$id' : null,
    'quotation' => hasId ? '/quotations/$id' : null,
    'job' => hasId ? '/jobs/$id' : null,
    'trip' || 'pod' => hasId ? '/trips/$id' : null,
    'invoice' => '/invoices',
    'payment' => '/payments',
    'organization' => '/profile',
    _ => null,
  };
}
