import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/features/home/data/dashboard_model.dart';
import 'package:mz_logistics_customer_app/features/home/presentation/home_live_trip.dart';
import 'package:mz_logistics_customer_app/features/home/presentation/home_providers.dart';
import 'package:mz_logistics_customer_app/features/trips/data/trip_model.dart';
import 'package:mz_logistics_customer_app/shared/models/user.dart';

void main() {
  testWidgets('assigned trip keeps the truck near pickup in Arabic', (
    tester,
  ) async {
    await _pump(tester, const Size(980, 640), wide: true);
    expect(find.text('معيّنة'), findsOneWidget);
    expect(find.textContaining('TRP-2026-0020'), findsOneWidget);
    expect(find.textContaining('العامرات، مسقط'), findsOneWidget);
    expect(find.textContaining('أدم، الداخلية'), findsOneWidget);
    expect(find.text('تم تعيين سائق وسيستلم الشحنة.'), findsOneWidget);
    expect(find.text('متابعة الرحلة'), findsOneWidget);
    expect(find.textContaining('123'), findsOneWidget);
    expect(find.textContaining('Ahmed'), findsOneWidget);
    expect(find.byIcon(Icons.trip_origin_rounded), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_pin_circle_rounded), findsOneWidget);

    final truck = tester.getCenter(find.byIcon(Icons.local_shipping_rounded));
    final card = tester.getCenter(find.byType(HomeLiveTrip));
    expect(truck.dx, greaterThan(card.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('assigned trip lays out on a phone', (tester) async {
    await _pump(tester, const Size(360, 900), wide: false, textScale: 1.3);
    expect(find.text('متابعة الرحلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _i18n = I18nBundle(
  locale: Locale('ar'),
  strings: {
    'home.liveTripFollow': 'متابعة الرحلة',
    'home.pickupLabel': 'موقع التحميل',
    'home.deliveryLabel': 'موقع التسليم',
    'common.dash': '—',
    'trip.truck': 'الشاحنة',
    'trip.driver': 'السائق',
    'trip.stage.assigned': 'معيّنة',
    'trip.stageHint.assigned': 'تم تعيين سائق وسيستلم الشحنة.',
  },
);

const _trip = Trip(
  id: 9,
  reference: 'TRP-2026-0020',
  status: 'assigned',
  pickupCity: 'العامرات، مسقط',
  deliveryCity: 'أدم، الداخلية',
  truck: TruckSummary(id: 3, plateNumber: '123'),
  driver: UserAccount(id: 4, name: 'Ahmed', email: 'ahmed@example.com'),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  required bool wide,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featuredInTransitTripProvider.overrideWith((ref) async => _trip),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          body: HomeLiveTrip(
            i18n: _i18n,
            summary: const DashboardSummary(tripsActive: 1),
            wide: wide,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
