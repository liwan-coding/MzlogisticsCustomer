import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/features/quotations/data/quotation_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/shipment_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/shipment_detail_screen.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/shipment_providers.dart';
import 'package:mz_logistics_customer_app/shared/models/organization.dart';

void main() {
  testWidgets('draft request leads with publish, not comparison', (tester) async {
    await _pumpDetail(
      tester,
      const Size(390, 1400),
      _english,
      _shipment(status: 'draft'),
    );

    expect(
      find.text(
        'This request is still a draft. Publish it so service providers can send quotations.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shipment-publish')), findsOneWidget);
    expect(find.byKey(const Key('shipment-compare')), findsNothing);
    expect(find.text('Cement'), findsWidgets);
    expect(find.text('Flatbed'), findsOneWidget);
    expect(find.textContaining('Sohar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('published request shows the lowest quotation and compare', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      const Size(1280, 1100),
      _english,
      _shipment(
        status: 'published',
        quotations: const [
          Quotation(
            id: 3,
            reference: 'Q-3',
            totalPrice: 900,
            currency: 'OMR',
            status: 'submitted',
            provider: Organization(id: 1, name: 'Gulf Haulage'),
          ),
          Quotation(
            id: 4,
            reference: 'Q-4',
            totalPrice: 640,
            currency: 'OMR',
            status: 'submitted',
            provider: Organization(id: 2, name: 'Coastal Freight'),
          ),
        ],
      ),
    );

    expect(find.textContaining('From'), findsOneWidget);
    expect(find.text('Coastal Freight'), findsOneWidget);
    expect(find.byKey(const Key('shipment-compare')), findsOneWidget);
    expect(find.byKey(const Key('shipment-publish')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('shipment-compare')));
    await tester.tap(find.byKey(const Key('shipment-compare')));
    await tester.pumpAndSettle();
    expect(find.text('comparison'), findsOneWidget);
  });

  testWidgets('arabic detail stays within a narrow window', (tester) async {
    await _pumpDetail(
      tester,
      const Size(360, 1600),
      _arabic,
      _shipment(
        status: 'published',
        cargoType: 'أسمنت بورتلاندي سائب لشحنة ساحلية طويلة',
        quotations: const [
          Quotation(
            id: 8,
            reference: 'Q-8',
            totalPrice: 510,
            currency: 'OMR',
            status: 'submitted',
            provider: Organization(id: 4, nameAr: 'النقل الساحلي', name: 'Coastal'),
          ),
        ],
      ),
      textScale: 1.3,
    );

    expect(find.text('انشره ليصلك عروض الأسعار من مقدمي الخدمة.'), findsNothing);
    expect(find.textContaining('قارنها واختر'), findsOneWidget);
    expect(find.byKey(const Key('shipment-compare')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('publish asks for confirmation before sending', (tester) async {
    await _pumpDetail(
      tester,
      const Size(390, 1200),
      _english,
      _shipment(status: 'draft'),
    );

    await tester.ensureVisible(find.byKey(const Key('shipment-publish')));
    await tester.tap(find.byKey(const Key('shipment-publish')));
    await tester.pumpAndSettle();
    expect(
      find.text('Publish this request to service providers?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

ShipmentRequest _shipment({
  required String status,
  String cargoType = 'Cement',
  List<Quotation> quotations = const [],
}) {
  return ShipmentRequest(
    id: 7,
    reference: 'SR-7',
    cargoType: cargoType,
    truckType: 'flatbed',
    truckTypeLabel: 'Flatbed',
    cargoDescription: 'Bulk bags, keep dry',
    weightTons: 18,
    quantity: 18,
    quantityUnit: 'tons',
    pickupAddress: 'Port gate 2',
    pickupCity: 'Sohar',
    deliveryAddress: 'Yard 4',
    deliveryCity: 'Nizwa',
    requiredDate: DateTime.utc(2026, 10, 2),
    notes: 'Site opens at 7',
    status: status,
    quotations: quotations,
    quotationsCount: quotations.length,
    createdAt: DateTime.utc(2026, 9, 20, 8),
  );
}

const _english = I18nBundle(
  locale: Locale('en'),
  strings: {
    'shipment.detail': 'Shipment request',
    'shipment.requiredDate': 'Required date',
    'shipment.cargo': 'Cargo',
    'shipment.cargoType': 'Cargo type',
    'shipment.truckType': 'Vehicle type',
    'shipment.cargoDescription': 'Cargo description',
    'shipment.weight': 'Weight (tons)',
    'shipment.volume': 'Volume (m³)',
    'shipment.route': 'Route',
    'shipment.publishedAt': 'Published',
    'shipment.quotationsCount': '{count} quotations',
    'shipment.waitingQuotes': 'Waiting for quotes',
    'shipment.quotesFrom': 'From {amount}',
    'shipment.viewQuotations': 'Compare quotations',
    'shipment.quoteAccepted': 'Quotation accepted',
    'shipment.awardedQuotation': 'Accepted quotation',
    'shipment.publish': 'Publish request',
    'shipment.publishConfirm': 'Publish this request to service providers?',
    'shipment.cancelRequest': 'Cancel request',
    'shipment.cancelConfirm': 'Cancel this shipment request?',
    'shipment.nextDraft':
        'This request is still a draft. Publish it so service providers can send quotations.',
    'shipment.nextPublishedEmpty':
        'Providers can see this request. New quotations will appear here.',
    'shipment.nextPublishedReady':
        'Quotations are in. Compare them and accept the one that fits this shipment.',
    'shipment.nextAwarded':
        'A quotation was accepted. The awarded work continues as a job.',
    'shipment.nextCancelled':
        'This request was cancelled. Providers can no longer quote it.',
    'shipment.nextExpired':
        'This request expired before a quotation was accepted.',
    'shipment.unitTons': 'tons',
    'common.tons': 'tons',
    'common.pickup': 'Pickup',
    'common.delivery': 'Delivery',
    'common.notes': 'Notes',
    'common.created': 'Created',
    'common.notAvailable': 'Not available',
    'common.cancel': 'Cancel',
    'common.confirm': 'Confirm',
    'common.loading': 'Loading',
    'quotation.title': 'Quotations',
    'quotation.empty': 'No quotations have been submitted for this request.',
    'quotation.detail': 'Quotation',
    'paymentContract.title': 'Payment terms',
    'paymentContract.trigger': 'When payment is due',
    'paymentContract.onAward': 'Pay in full when the quotation is accepted',
    'status.draft': 'Draft',
    'status.published': 'Published',
    'status.awarded': 'Awarded',
    'status.submitted': 'Submitted',
    'status.accepted': 'Accepted',
  },
);

const _arabic = I18nBundle(
  locale: Locale('ar'),
  strings: {
    'shipment.detail': 'طلب الشحن',
    'shipment.requiredDate': 'التاريخ المطلوب',
    'shipment.cargo': 'البضاعة',
    'shipment.cargoType': 'نوع البضاعة',
    'shipment.truckType': 'نوع المركبة',
    'shipment.cargoDescription': 'وصف البضاعة',
    'shipment.weight': 'الوزن (طن)',
    'shipment.volume': 'الحجم (م³)',
    'shipment.route': 'المسار',
    'shipment.publishedAt': 'تاريخ النشر',
    'shipment.quotationsCount': '{count} عروض أسعار',
    'shipment.waitingQuotes': 'بانتظار العروض',
    'shipment.quotesFrom': 'ابتداءً من {amount}',
    'shipment.viewQuotations': 'مقارنة عروض الأسعار',
    'shipment.quoteAccepted': 'تم قبول عرض سعر',
    'shipment.awardedQuotation': 'العرض المقبول',
    'shipment.publish': 'نشر الطلب',
    'shipment.publishConfirm': 'نشر هذا الطلب لمقدمي الخدمة؟',
    'shipment.cancelRequest': 'إلغاء الطلب',
    'shipment.cancelConfirm': 'إلغاء طلب الشحن؟',
    'shipment.nextDraft':
        'هذا الطلب ما زال مسودة. انشره ليصلك عروض الأسعار من مقدمي الخدمة.',
    'shipment.nextPublishedEmpty': 'الطلب منشور. ستظهر عروض الأسعار هنا فور وصولها.',
    'shipment.nextPublishedReady': 'وصلت العروض. قارنها واختر العرض المناسب لهذه الشحنة.',
    'shipment.nextAwarded': 'تم قبول عرض سعر. يُنفَّذ العمل الآن كمهمة.',
    'shipment.nextCancelled': 'أُلغي هذا الطلب، ولم يعد متاحاً لتقديم العروض.',
    'shipment.nextExpired': 'انتهت صلاحية الطلب قبل قبول أي عرض.',
    'shipment.unitTons': 'طن',
    'common.tons': 'طن',
    'common.pickup': 'التحميل',
    'common.delivery': 'التسليم',
    'common.notes': 'ملاحظات',
    'common.created': 'تم الإنشاء',
    'common.notAvailable': 'غير متوفر',
    'common.cancel': 'إلغاء',
    'common.confirm': 'تأكيد',
    'common.loading': 'جارٍ التحميل',
    'quotation.title': 'عروض الأسعار',
    'quotation.empty': 'لم تُقدَّم عروض أسعار لهذا الطلب بعد.',
    'quotation.detail': 'عرض السعر',
    'paymentContract.title': 'شروط الدفع',
    'paymentContract.trigger': 'موعد استحقاق الدفع',
    'paymentContract.onAward': 'الدفع كاملاً عند قبول العرض',
    'status.draft': 'مسودة',
    'status.published': 'منشور',
    'status.awarded': 'مُرسى',
    'status.submitted': 'مقدَّم',
    'status.accepted': 'مقبول',
  },
);

class _FixedI18n extends I18nController {
  _FixedI18n(this.bundle);

  final I18nBundle bundle;

  @override
  Future<I18nBundle> build() async => bundle;
}

Future<void> _pumpDetail(
  WidgetTester tester,
  Size size,
  I18nBundle bundle,
  ShipmentRequest shipment, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/shipments/${shipment.id}',
    routes: [
      GoRoute(
        path: '/shipments/:id',
        builder: (context, state) =>
            ShipmentDetailScreen(shipmentId: shipment.id),
      ),
      GoRoute(
        path: '/shipments/:id/quotations',
        builder: (context, state) => const Text('comparison'),
      ),
      GoRoute(
        path: '/quotations/:id',
        builder: (context, state) => const SizedBox(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        i18nControllerProvider.overrideWith(() => _FixedI18n(bundle)),
        shipmentDetailProvider(shipment.id).overrideWith((ref) async => shipment),
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
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}
