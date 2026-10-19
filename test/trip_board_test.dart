import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/core/utils/bidi_text.dart';
import 'package:mz_logistics_customer_app/features/trips/data/trip_model.dart';
import 'package:mz_logistics_customer_app/features/trips/presentation/widgets/trip_board.dart';
import 'package:mz_logistics_customer_app/shared/models/user.dart';

void main() {
  testWidgets('delivery code sits above the trip facts and stays readable', (tester) async {
    await _pump(tester, const Size(1280, 900));

    final code = tester.getRect(find.byKey(const Key('trip-delivery-code')));
    final quantities = tester.getTopLeft(find.text('الكميات'));
    expect(code.top, lessThan(quantities.dy));
    expect(code.width, greaterThan(240));
    expect(code.height, greaterThan(48));

    for (final glyph in ['2', '5', '4', '7', '8', '1']) {
      expect(
        find.descendant(
          of: find.byKey(const Key('trip-delivery-code')),
          matching: find.text(glyph),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('أعطِ هذا الرمز للسائق عند وصول البضاعة فقط. لا تشاركه مسبقاً.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop cards match in height and quantities span both', (tester) async {
    await _pump(tester, const Size(1280, 900));

    final info = tester.getRect(find.byKey(const Key('trip-info-card')));
    final route = tester.getRect(find.byKey(const Key('trip-route-card')));
    final quantities = tester.getRect(find.byKey(const Key('trip-quantities-card')));
    final left = info.left < route.left ? info : route;
    final right = info.left < route.left ? route : info;
    final gap = right.left - left.right;

    expect((info.height - route.height).abs(), lessThan(1));
    expect((info.width - route.width).abs(), lessThan(1));
    expect((quantities.width - (info.width + route.width + gap)).abs(), lessThan(1));
    expect((quantities.left - left.left).abs(), lessThan(1));
    expect((quantities.right - right.right).abs(), lessThan(1));
    expect(quantities.top, greaterThanOrEqualTo(info.bottom - 1));
    expect(find.text('موقع التحميل والتسليم'), findsOneWidget);
    expect(find.textContaining('العامرات، مسقط'), findsOneWidget);
    expect(find.textContaining('أدم، الداخلية'), findsOneWidget);

    final planned = tester.getCenter(find.textContaining('25.00'));
    final plannedIcon = tester.getCenter(
      find.descendant(
        of: find.byKey(const Key('trip-quantities-card')),
        matching: find.byIcon(Icons.inventory_2_outlined),
      ),
    );
    expect(plannedIcon.dx, greaterThan(planned.dx));
    expect((plannedIcon.dy - planned.dy).abs(), lessThan(28));
    expect(tester.takeException(), isNull);
  });

  testWidgets('names keep their own direction in Arabic and English layouts', (tester) async {
    await _pump(tester, const Size(1280, 900));
    _expectNameDirection('Ahmed', TextDirection.ltr);
    _expectNameDirection('العامرات، مسقط', TextDirection.rtl);
    _expectNameDirection('flatbed · 123', TextDirection.ltr);

    await _pump(tester, const Size(1280, 900), locale: const Locale('en'), trip: _arabicDriver);
    _expectNameDirection('أحمد', TextDirection.rtl);
    _expectNameDirection('Muscat', TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery code lays out on a phone without overflow', (tester) async {
    await _pump(tester, const Size(360, 900), textScale: 1.3);
    expect(find.byKey(const Key('trip-delivery-code')), findsOneWidget);
    expect(find.text('نسخ الرمز'), findsOneWidget);
    final info = tester.getSize(find.byKey(const Key('trip-info-card')));
    final route = tester.getSize(find.byKey(const Key('trip-route-card')));
    expect((info.width - route.width).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });
}

void _expectNameDirection(String name, TextDirection direction) {
  final text = testerWidget(name);
  expect(text.data, bidiIsolate(name));
  expect(text.textDirection, direction);
}

Text testerWidget(String name) {
  return find.textContaining(name).evaluate().map((element) => element.widget).whereType<Text>().first;
}

const _i18n = I18nBundle(
  locale: Locale('ar'),
  strings: {
    'trip.otp': 'رمز التسليم',
    'trip.otpHint': 'أعطِ هذا الرمز للسائق عند وصول البضاعة فقط. لا تشاركه مسبقاً.',
    'trip.otpCopy': 'نسخ الرمز',
    'trip.otpCopied': 'تم نسخ الرمز',
    'trip.quantities': 'الكميات',
    'trip.planned': 'الكمية المخططة',
    'trip.delivered': 'الكمية المسلمة',
    'trip.stops': 'موقع التحميل والتسليم',
    'trip.info': 'معلومات الرحلة',
    'trip.truck': 'الشاحنة',
    'trip.driver': 'السائق',
    'trip.scheduledDeparture': 'موعد الانطلاق',
    'trip.viewPod': 'عرض إثبات التسليم',
    'trip.stage.assigned': 'معينة',
    'trip.stage.loaded': 'تم الاستلام',
    'trip.stage.in_transit': 'في الطريق',
    'trip.stage.delivered': 'تم التسليم',
    'trip.stageHint.delivered': 'تم التسليم',
    'shipment.route': 'المسار',
    'common.reference': 'المرجع',
    'common.status': 'الحالة',
    'common.eta': 'الوصول المتوقع',
    'common.pickup': 'التحميل',
    'common.delivery': 'التسليم',
    'common.notAvailable': '—',
    'common.dash': '—',
    'nav.jobs': 'المهام',
    'job.detail': 'تفاصيل الوظيفة',
  },
);

const _trip = Trip(
  id: 9,
  reference: 'TRP-2026-0020',
  status: 'delivered',
  plannedQuantity: 25,
  deliveredQuantity: 0,
  pickupCity: 'العامرات، مسقط',
  deliveryCity: 'أدم، الداخلية',
  otpCode: '254781',
  jobId: 4,
  jobReference: 'JOB-2026-0008',
  truck: TruckSummary(id: 3, plateNumber: 'flatbed', type: '123'),
  driver: UserAccount(id: 4, name: 'Ahmed', email: 'ahmed@example.com'),
);

const _arabicDriver = Trip(
  id: 10,
  reference: 'TRP-2026-0021',
  status: 'assigned',
  pickupCity: 'Muscat',
  deliveryCity: 'Adam',
  driver: UserAccount(id: 5, name: 'أحمد', email: 'ahmad@example.com'),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  Locale locale = const Locale('ar'),
  Trip trip = _trip,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: SingleChildScrollView(
          child: TripBoard(i18n: _i18n, trip: trip),
        ),
      ),
    ),
  );
  await tester.pump();
}
