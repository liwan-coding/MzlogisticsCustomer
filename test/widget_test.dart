import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/core/theme/app_colors.dart';
import 'package:mz_logistics_customer_app/core/utils/formatters.dart';
import 'package:mz_logistics_customer_app/core/utils/json_utils.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/shipment_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/widgets/shipment_card.dart';

void main() {
  test('brand colors follow the home palette', () {
    expect(AppColors.ink, const Color(0xFF1C2430));
    expect(AppColors.orange, const Color(0xFFF15A22));
    expect(AppColors.surface, const Color(0xFFF7F8FB));
    expect(AppColors.bar, const Color(0xFF101A2B));
    expect(AppColors.navy, AppColors.orange);
    expect(AppColors.accentFrom, AppColors.orange);
    expect(AppColors.success, const Color(0xFF1F9D62));
    expect(AppColors.danger, const Color(0xFFA33B32));
  });

  test('amount formatter includes currency', () {
    expect(formatAmount(12.5), contains('OMR'));
  });

  testWidgets('compact shipment card shows cargo, route, and quote facts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const i18n = I18nBundle(
      locale: Locale('en'),
      strings: {
        'shipment.detail': 'Shipment request',
        'shipment.quotationsCount': '{count} quotations',
        'shipment.waitingQuotes': 'Waiting for quotes',
        'shipment.unitTons': 'tons',
        'common.tons': 'tons',
        'status.published': 'Published',
        'common.pickup': 'Pickup',
        'common.delivery': 'Delivery',
      },
    );

    const shipment = ShipmentRequest(
      id: 12,
      reference: 'SR-1042',
      cargoType: 'Portland cement',
      pickupCity: 'Muscat',
      deliveryCity: 'Salalah',
      status: 'published',
      weightTons: 24,
      quantity: 24,
      quantityUnit: 'tons',
      requiredDate: null,
      quotationsCount: 3,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ShipmentCard(i18n: i18n, shipment: shipment, compact: true),
          ),
        ),
        GoRoute(
          path: '/shipments/:id',
          builder: (context, state) => const Text('shipment-detail'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Portland cement'), findsOneWidget);
    expect(find.text('SR-1042'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.textContaining('Muscat'), findsOneWidget);
    expect(find.textContaining('Salalah'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('3 quotations'), findsOneWidget);
    expect(find.textContaining('tons'), findsWidgets);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('shipment-detail'), findsOneWidget);
  });

  test('photo path lists decode json strings and map values', () {
    expect(asStringList(['pods/1/a.jpg', 'pods/1/b.jpg']), [
      'pods/1/a.jpg',
      'pods/1/b.jpg',
    ]);
    expect(asStringList('["pods/1/a.jpg"]'), ['pods/1/a.jpg']);
    expect(asStringList({'0': 'pods/1/a.jpg'}), ['pods/1/a.jpg']);
    expect(asStringList(null), isEmpty);
  });

  test('published shipments can compare quotations until awarded', () {
    const published = ShipmentRequest(id: 1, status: 'published');
    const awarded = ShipmentRequest(id: 2, status: 'awarded');
    const cancelled = ShipmentRequest(id: 3, status: 'cancelled');

    expect(published.canCompareQuotations, isTrue);
    expect(awarded.canCompareQuotations, isFalse);
    expect(awarded.isAwarded, isTrue);
    expect(cancelled.canCompareQuotations, isFalse);
  });
}
