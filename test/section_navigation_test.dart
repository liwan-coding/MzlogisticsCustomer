import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/core/router/app_router.dart';
import 'package:mz_logistics_customer_app/core/router/section_paths.dart';
import 'package:mz_logistics_customer_app/features/auth/presentation/auth_controller.dart';
import 'package:mz_logistics_customer_app/features/home/data/dashboard_model.dart';
import 'package:mz_logistics_customer_app/features/home/presentation/home_providers.dart';
import 'package:mz_logistics_customer_app/features/jobs/data/job_model.dart';
import 'package:mz_logistics_customer_app/features/jobs/presentation/job_providers.dart';
import 'package:mz_logistics_customer_app/features/notifications/data/notification_model.dart';
import 'package:mz_logistics_customer_app/features/notifications/presentation/notification_providers.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/shipment_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/truck_type.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/shipment_providers.dart';
import 'package:mz_logistics_customer_app/shared/models/pagination_meta.dart';
import 'package:mz_logistics_customer_app/shared/models/user.dart';
import 'package:mz_logistics_customer_app/shared/widgets/page_scaffold.dart';
import 'package:mz_logistics_customer_app/shared/widgets/responsive_scaffold.dart';

void main() {
  test('section fallback follows the business hierarchy', () {
    expect(sectionFallback('/trips/4/pod'), '/jobs');
    expect(sectionFallback('/quotations/9'), '/shipments');
    expect(sectionFallback('/shipments/3/quotations'), '/shipments');
    expect(sectionFallback('/jobs/2'), '/jobs');
    expect(sectionFallback('/payments/checkout/8'), '/payments');
    expect(sectionFallback('/payment/success'), '/payments');
    expect(sectionFallback('/notifications'), '/home');
    expect(isShellSectionRoot('/jobs'), isTrue);
    expect(isShellSectionRoot('/jobs/2'), isFalse);
  });

  test('shell destinations stay aligned with section roots', () {
    expect(
      shellDestinations.map((item) => item.location).toList(),
      shellSectionRoots,
    );
  });

  testWidgets('job detail keeps section navigation and returns to the list', (
    tester,
  ) async {
    final router = await _pumpShell(tester, const Size(390, 844));

    expect(find.text('Jobs').hitTestable(), findsWidgets);
    expect(find.byType(BackButtonIcon), findsNothing);

    router.push('/jobs/7');
    await _settle(tester);

    expect(router.state.uri.path, '/jobs/7');
    expect(find.text('Jobs').hitTestable(), findsOneWidget);
    expect(find.byType(BackButtonIcon).hitTestable(), findsOneWidget);
    expect(find.text('Customer'), findsNothing);

    await tester.tap(find.text('Jobs').hitTestable());
    await _settle(tester);

    expect(router.state.uri.path, '/jobs');
    expect(find.byType(BackButtonIcon), findsNothing);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(router.state.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening a shell route from notifications keeps a single shell page', (
    tester,
  ) async {
    final router = await _pumpShell(tester, const Size(1280, 900));

    router.push('/notifications');
    await _settle(tester);
    expect(tester.takeException(), isNull);

    router.go('/jobs/7');
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(router.state.uri.path, '/jobs/7');
    expect(find.byType(BackButtonIcon).hitTestable(), findsOneWidget);
  });

  testWidgets('desktop detail keeps the side navigation', (tester) async {
    final router = await _pumpShell(tester, const Size(1280, 900));
    router.go('/jobs/7');
    await _settle(tester);

    expect(find.text('Customer').hitTestable(), findsOneWidget);
    expect(find.text('Jobs').hitTestable(), findsOneWidget);
    expect(find.byType(BackButtonIcon).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back icon follows reading direction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/jobs/7',
      routes: [
        GoRoute(path: '/jobs', builder: (context, state) => const SizedBox()),
        GoRoute(
          path: '/jobs/7',
          builder: (context, state) => const PageScaffold(
            title: 'Job',
            showBack: true,
            body: SizedBox.shrink(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pump();

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(BackButtonIcon),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon?.matchTextDirection, isTrue);
    expect(
      Directionality.of(tester.element(find.byType(BackButtonIcon))),
      TextDirection.rtl,
    );

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.state.uri.path, '/jobs');
  });
}

Future<GoRouter> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/jobs',
    routes: customerRoutes(rootNavigatorKey: rootKey),
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        i18nControllerProvider.overrideWith(() => _FixedI18n(_bundle)),
        authControllerProvider.overrideWith(_SignedInAuth.new),
        notificationsProvider.overrideWith(
          (ref) async => const PagedResult<AppNotification>(
            items: [],
            meta: PaginationMeta(),
          ),
        ),
        jobsProvider.overrideWith(
          (ref) async => const PagedResult<TransportJob>(
            items: [],
            meta: PaginationMeta(),
          ),
        ),
        jobDetailProvider.overrideWith(
          (ref, id) async =>
              TransportJob(id: id, reference: 'JOB-$id', status: 'completed'),
        ),
        dashboardProvider.overrideWith((ref) async => _summary),
        shipmentsProvider.overrideWith(
          (ref) async => const PagedResult<ShipmentRequest>(
            items: [],
            meta: PaginationMeta(),
          ),
        ),
        truckTypesProvider.overrideWith((ref) async => const <TruckTypeOption>[]),
      ],
      child: MaterialApp.router(
        locale: _bundle.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return router;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _SignedInAuth extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      token: 'test-token',
      user: UserAccount(id: 1, name: 'Lina', email: 'lina@example.com'),
    );
  }
}

class _FixedI18n extends I18nController {
  _FixedI18n(this.bundle);

  final I18nBundle bundle;

  @override
  Future<I18nBundle> build() async => bundle;
}

const _summary = DashboardSummary(
  shipmentsOpen: 1,
  shipmentsTotal: 1,
  quotationsPending: 0,
  jobsActive: 1,
  jobsCompleted: 1,
  tripsActive: 0,
  tripsInTransit: 0,
  paymentsCompletedAmount: 0,
  invoicesCount: 0,
);

const _bundle = I18nBundle(
  locale: Locale('en'),
  strings: {
    'app.name': 'MZ Logistics',
    'app.customer': 'Customer',
    'nav.home': 'Home',
    'nav.shipments': 'Shipments',
    'nav.jobs': 'Jobs',
    'nav.invoices': 'Invoices',
    'nav.payments': 'Payments',
    'nav.billing': 'Billing',
    'nav.profile': 'Profile',
    'nav.notifications': 'Notifications',
    'job.detail': 'Job details',
    'job.headerSubtitle': 'Track active work',
    'job.empty': 'No jobs',
    'job.hint': 'Jobs appear after a quotation is accepted.',
    'home.heroTitle': 'Need to move cargo?',
    'home.greeting': 'Hello {name}',
  },
);
