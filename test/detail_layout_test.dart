import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_customer_app/core/i18n/i18n_controller.dart';
import 'package:mz_logistics_customer_app/features/payments/data/payment_contract_model.dart';
import 'package:mz_logistics_customer_app/features/profile/presentation/widgets/profile_sections.dart';
import 'package:mz_logistics_customer_app/features/shipments/data/shipment_model.dart';
import 'package:mz_logistics_customer_app/features/shipments/presentation/widgets/shipment_detail_sections.dart';
import 'package:mz_logistics_customer_app/shared/models/user.dart';
import 'package:mz_logistics_customer_app/shared/widgets/page_scaffold.dart';

void main() {
  testWidgets('paired cards share width and height, and the next card spans both', (tester) async {
    await _pump(tester, const Size(1100, 900));

    final request = tester.getRect(find.byKey(const Key('shipment-request-card')));
    final cargo = tester.getRect(find.byKey(const Key('shipment-cargo-card')));
    final route = tester.getRect(find.byKey(const Key('shipment-route-card')));
    final left = request.left < cargo.left ? request : cargo;
    final right = request.left < cargo.left ? cargo : request;
    final gap = right.left - left.right;

    expect((request.width - cargo.width).abs(), lessThan(1));
    expect((request.height - cargo.height).abs(), lessThan(1));
    expect((route.width - (request.width + cargo.width + gap)).abs(), lessThan(1));
    expect(route.top, greaterThanOrEqualTo(request.bottom - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow detail page stacks the pair at full width', (tester) async {
    await _pump(tester, const Size(400, 1200));

    final request = tester.getSize(find.byKey(const Key('shipment-request-card')));
    final cargo = tester.getSize(find.byKey(const Key('shipment-cargo-card')));
    final route = tester.getSize(find.byKey(const Key('shipment-route-card')));
    expect((request.width - cargo.width).abs(), lessThan(1));
    expect((request.width - route.width).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile pairs share width and height', (tester) async {
    const i18n = I18nBundle(locale: Locale('ar'), strings: {});
    const user = UserAccount(id: 1, name: 'Rawan', email: 'rawan@example.com', phone: '96890000000');
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EqualCardRow(
            children: [
              ProfileAccountCard(i18n: i18n, user: user, onEdit: () {}),
              const ProfileContactCard(i18n: i18n),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final account = tester.getRect(find.byType(ProfileAccountCard));
    final contact = tester.getRect(find.byType(ProfileContactCard));
    expect((account.width - contact.width).abs(), lessThan(1));
    expect((account.height - contact.height).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShipmentRecordLayout(i18n: _i18n, shipment: _shipment),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _i18n = I18nBundle(
  locale: Locale('ar'),
  strings: {
    'shipment.requestDetails': 'تفاصيل الطلب',
    'shipment.cargo': 'البضاعة',
    'shipment.route': 'المسار',
    'shipment.reference': 'المرجع',
    'shipment.requiredDate': 'التاريخ',
    'shipment.cargoType': 'نوع البضاعة',
    'shipment.truckType': 'نوع الشاحنة',
    'shipment.weight': 'الوزن',
    'common.tons': 'طن',
    'common.status': 'الحالة',
    'common.pickup': 'التحميل',
    'common.delivery': 'التسليم',
    'common.openInMaps': 'الخريطة',
    'paymentContract.title': 'الدفع',
  },
);

const _shipment = ShipmentRequest(
  id: 1,
  reference: 'SHP-1',
  status: 'published',
  cargoType: 'حديد',
  truckType: 'flatbed',
  weightTons: 12,
  pickupCity: 'مسقط',
  deliveryCity: 'صحار',
  paymentTerms: PaymentTermsSnapshot(),
);
