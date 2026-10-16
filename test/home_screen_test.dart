import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/features/home/data/dashboard_model.dart';
import 'package:mz_logistics_customer_app/features/home/presentation/home_providers.dart';
import 'package:mz_logistics_customer_app/features/home/presentation/home_screen.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/shipment_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/truck_type.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/shipment_providers.dart';
import 'package:mz_logistics_customer_app/features/trips/data/trip_model.dart';
import 'package:mz_logistics_customer_app/shared/models/pagination_meta.dart';
import 'package:mz_logistics_customer_app/shared/models/user.dart';

void main() {
  testWidgets('home board lays out on a phone in Arabic', (tester) async {
    await _pumpHome(tester, const Size(360, 1400), _arabic, textScale: 1.3);
    expect(find.text('انقل البضاعة'), findsOneWidget);
    expect(find.text('عروض بانتظار القرار'), findsOneWidget);
    expect(find.text('المبالغ المدفوعة'), findsNothing);
    expect(find.text('طلب شحن جديد'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home board lays out on a wide window in English', (
    tester,
  ) async {
    await _pumpHome(tester, const Size(1280, 900), _english);
    expect(find.text('Move cargo'), findsOneWidget);
    expect(find.text('with confidence.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pending quotations'), 300);
    expect(find.text('Pending quotations'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Trips in transit'), findsOneWidget);
    expect(find.text('Paid amount'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home route scene lays out between two cities', (tester) async {
    await _pumpHome(
      tester,
      const Size(1280, 900),
      _english,
      shipments: const [
        ShipmentRequest(
          id: 7,
          pickupCity: 'Muscat',
          deliveryCity: 'Sohar',
          cargoType: 'Steel',
          status: 'published',
        ),
      ],
      truckTypes: const [
        TruckTypeOption(code: 'flatbed', name: 'Flatbed', nameAr: 'سطحة'),
        TruckTypeOption(code: 'reefer', name: 'Reefer', nameAr: 'مبرد'),
      ],
    );
    await tester.scrollUntilVisible(find.textContaining('Muscat'), 300);
    expect(find.textContaining('Muscat'), findsWidgets);
    expect(find.textContaining('Sohar'), findsWidgets);
    expect(find.text('Truck types'), findsOneWidget);
    expect(
      find.text('Choose a type to start a shipment request'),
      findsOneWidget,
    );
    expect(find.textContaining('Flatbed'), findsWidgets);
    expect(find.textContaining('Reefer'), findsWidgets);
    expect(find.text('Follow trip'), findsNothing);
    expect(tester.takeException(), isNull);

    final flatbed = find.ancestor(
      of: find.textContaining('Flatbed'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(flatbed);
    await tester.tap(flatbed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('truck:flatbed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows the nearest moving trip', (tester) async {
    await _pumpHome(
      tester,
      const Size(390, 1400),
      _english,
      liveTrip: Trip(
        id: 9,
        status: 'in_transit',
        pickupCity: 'Muscat',
        deliveryCity: 'Sohar',
        etaAt: DateTime.utc(2026, 10, 15, 12, 30),
        truck: const TruckSummary(id: 3, plateNumber: '12345'),
        driver: const UserAccount(
          id: 4,
          name: 'Ahmed',
          email: 'ahmed@example.com',
        ),
      ),
    );
    expect(find.text('On the road now'), findsOneWidget);
    expect(find.textContaining('Muscat'), findsWidgets);
    expect(find.textContaining('Sohar'), findsWidgets);
    expect(find.textContaining('12345'), findsOneWidget);
    expect(find.textContaining('Ahmed'), findsOneWidget);
    expect(find.text('Follow trip'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Follow trip'));
    await tester.tap(find.text('Follow trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('trip:9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving trip lays out on a phone in Arabic', (tester) async {
    await _pumpHome(
      tester,
      const Size(360, 1400),
      _arabic,
      textScale: 1.3,
      liveTrip: Trip(
        id: 9,
        status: 'in_transit',
        pickupCity: 'مسقط',
        deliveryCity: 'صحار',
        truck: const TruckSummary(id: 3, plateNumber: '12345'),
        driver: const UserAccount(
          id: 4,
          name: 'أحمد',
          email: 'ahmed@example.com',
        ),
      ),
    );
    expect(find.text('في الطريق الآن'), findsOneWidget);
    expect(find.text('متابعة الرحلة'), findsOneWidget);
    expect(find.textContaining('12345'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _summary = DashboardSummary(
  shipmentsOpen: 12,
  shipmentsTotal: 20,
  quotationsPending: 3,
  jobsActive: 4,
  jobsCompleted: 7,
  tripsActive: 6,
  tripsInTransit: 2,
  paymentsCompletedAmount: 1240,
  invoicesCount: 8,
);

const _arabic = I18nBundle(
  locale: Locale('ar'),
  strings: {
    'home.snapshot': 'لمحة سريعة',
    'home.ofTotal': '{current} من {total}',
    'home.heroLead': 'انقل البضاعة',
    'app.name': 'MoveX',
    'app.tagline': 'شحن يلتزم بالجدول',
    'footer.services': 'الخدمات',
    'footer.finance': 'المالية',
    'footer.account': 'الحساب',
    'footer.rights': 'جميع الحقوق محفوظة',
    'footer.gateway': 'Thawani',
    'footer.contact': 'تواصل',
    'footer.phone': 'الهاتف',
    'footer.whatsapp': 'واتساب',
    'footer.instagram': 'إنستغرام',
    'nav.home': 'الرئيسية',
    'nav.shipments': 'طلبات الشحن',
    'nav.billing': 'المالية',
    'nav.profile': 'الملف',
    'nav.notifications': 'الإشعارات',
    'home.heroAccent': 'بثقة.',
    'home.heroBody':
        'اطلب النقل، وقارن عروض الأسعار من مزودي الخدمة الموثوقين.',
    'home.eyebrow': 'نقل موثوق',
    'home.fleetTitle': 'أنواع الشاحنات',
    'home.fleetHint': 'اختر النوع لبدء طلب الشحن',
    'home.fleetRequest': 'طلب شحن بنوع {type}',
    'home.liveTripNow': 'في الطريق الآن',
    'home.liveTripFollow': 'متابعة الرحلة',
    'home.quickAction': 'إجراء سريع',
    'home.quickTitle': 'أنشئ طلب شحن جديد',
    'home.quickBody': 'احصل على عروض أسعار.',
    'home.stepRequest': 'الطلب',
    'home.stepRequestBody': 'أنشئ طلب الشحن',
    'home.stepQuotes': 'العروض',
    'home.stepQuotesBody': 'يرسل مقدمو الخدمة عروضهم',
    'home.stepAccept': 'القبول',
    'home.stepAcceptBody': 'قارن العروض واقبل أحدها',
    'home.stepTrack': 'المتابعة',
    'home.stepTrackBody': 'تابع المهمة حتى التسليم',
    'home.pickupLabel': 'موقع التحميل',
    'home.deliveryLabel': 'موقع التسليم',
    'common.eta': 'الوصول المتوقع',
    'common.dash': '—',
    'common.retry': 'إعادة المحاولة',
    'trip.truck': 'الشاحنة',
    'trip.driver': 'السائق',
    'trip.stageHint.in_transit': 'الشحنة في الطريق إلى موقع التسليم.',
    'home.glanceTitle': 'ملخص النشاط',
    'home.shipmentsTotal': 'كل الطلبات',
    'home.stageCreated': 'تم الإنشاء',
    'home.stageQuotes': 'بانتظار العروض',
    'home.stageAccepted': 'تم القبول',
    'home.viewAllShipments': 'عرض كل الشحنات',
    'home.newShipment': 'طلب شحن جديد',
    'home.shipmentsOpen': 'طلبات مفتوحة',
    'home.quotationsPending': 'عروض بانتظار القرار',
    'home.jobsActive': 'مهام نشطة',
    'home.tripsInTransit': 'رحلات في الطريق',
    'home.paymentsCompleted': 'المبالغ المدفوعة',
    'home.invoices': 'الفواتير',
    'home.quickActions': 'اختصارات',
    'nav.shipmentsShort': 'الشحنات',
    'nav.jobs': 'المهام',
    'nav.invoices': 'الفواتير',
    'nav.payments': 'المدفوعات',
    'home.recentShipments': 'أحدث طلبات الشحن',
    'common.viewAll': 'عرض الكل',
    'home.noShipments': 'لا توجد طلبات شحن بعد',
    'home.emptyHint': 'أنشئ طلب شحن لتبدأ باستلام عروض الأسعار.',
  },
);

const _english = I18nBundle(
  locale: Locale('en'),
  strings: {
    'home.snapshot': 'At a glance',
    'home.ofTotal': '{current} of {total}',
    'home.heroLead': 'Move cargo',
    'app.name': 'MoveX',
    'app.tagline': 'Freight that stays on schedule',
    'footer.services': 'Services',
    'footer.finance': 'Billing',
    'footer.account': 'Account',
    'footer.rights': 'All rights reserved',
    'footer.gateway': 'Thawani',
    'footer.contact': 'Contact',
    'footer.phone': 'Phone',
    'footer.whatsapp': 'WhatsApp',
    'footer.instagram': 'Instagram',
    'nav.home': 'Home',
    'nav.shipments': 'Shipments',
    'nav.billing': 'Billing',
    'nav.profile': 'Profile',
    'nav.notifications': 'Notifications',
    'home.heroAccent': 'with confidence.',
    'home.heroBody': 'Request transportation and compare quotations.',
    'home.eyebrow': 'Reliable transport for a stronger tomorrow',
    'home.fleetTitle': 'Truck types',
    'home.fleetHint': 'Choose a type to start a shipment request',
    'home.fleetRequest': 'Request a shipment with {type}',
    'home.liveTripNow': 'On the road now',
    'home.liveTripFollow': 'Follow trip',
    'home.quickAction': 'Quick action',
    'home.quickTitle': 'Create a new shipment request',
    'home.quickBody': 'Get quotations from trusted transport providers',
    'home.stepRequest': 'Request',
    'home.stepRequestBody': 'Create your shipment request',
    'home.stepQuotes': 'Quotations',
    'home.stepQuotesBody': 'Providers send their quotations',
    'home.stepAccept': 'Accept',
    'home.stepAcceptBody': 'Compare and accept one quotation',
    'home.stepTrack': 'Track',
    'home.stepTrackBody': 'Follow the job until delivery',
    'home.pickupLabel': 'Pickup location',
    'home.deliveryLabel': 'Delivery location',
    'common.eta': 'ETA',
    'common.retry': 'Retry',
    'trip.truck': 'Truck',
    'trip.driver': 'Driver',
    'trip.stageHint.in_transit': 'The shipment is on the way to delivery.',
    'home.glanceTitle': 'Activity summary',
    'home.shipmentsTotal': 'All requests',
    'home.stageCreated': 'Created',
    'home.stageQuotes': 'Quotations',
    'home.stageAccepted': 'Accepted',
    'status.published': 'Published',
    'common.dash': '—',
    'home.movingForward': 'Moving Oman forward',
    'home.viewAllShipments': 'View all shipments',
    'home.newShipment': 'New shipment request',
    'home.shipmentsOpen': 'Open requests',
    'home.quotationsPending': 'Pending quotations',
    'home.jobsActive': 'Active jobs',
    'home.tripsInTransit': 'Trips in transit',
    'home.paymentsCompleted': 'Paid amount',
    'home.invoices': 'Invoices',
    'home.quickActions': 'Shortcuts',
    'nav.shipmentsShort': 'Shipments',
    'nav.jobs': 'Jobs',
    'nav.invoices': 'Invoices',
    'nav.payments': 'Payments',
    'home.recentShipments': 'Recent shipment requests',
    'common.viewAll': 'View all',
    'home.noShipments': 'No shipment requests yet',
    'home.emptyHint':
        'Create a shipment request to start receiving quotations.',
  },
);

class _FixedI18n extends I18nController {
  _FixedI18n(this.bundle);

  final I18nBundle bundle;

  @override
  Future<I18nBundle> build() async => bundle;
}

Future<void> _pumpHome(
  WidgetTester tester,
  Size size,
  I18nBundle bundle, {
  double textScale = 1,
  List<ShipmentRequest> shipments = const [],
  List<TruckTypeOption> truckTypes = const [],
  Trip? liveTrip,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/shipments/new',
        builder: (context, state) =>
            Text('truck:${state.uri.queryParameters['truck'] ?? ''}'),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (context, state) => Text('trip:${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/shipments',
        builder: (context, state) => const SizedBox(),
      ),
      GoRoute(path: '/jobs', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/invoices', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/payments', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/billing', builder: (context, state) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        i18nControllerProvider.overrideWith(() => _FixedI18n(bundle)),
        dashboardProvider.overrideWith((ref) async => _summary),
        shipmentsProvider.overrideWith(
          (ref) async => PagedResult<ShipmentRequest>(
            items: shipments,
            meta: const PaginationMeta(),
          ),
        ),
        truckTypesProvider.overrideWith((ref) async => truckTypes),
        featuredInTransitTripProvider.overrideWith((ref) async => liveTrip),
      ],
      child: MaterialApp.router(
        locale: bundle.locale,
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
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}
