import '../../../core/utils/json_utils.dart';
import '../../../shared/models/organization.dart';
import '../../payments/data/payment_contract_model.dart';
import '../../quotations/data/quotation_model.dart';
import 'platform_offer.dart';

class ShipmentRequest {
  const ShipmentRequest({
    required this.id,
    this.reference,
    this.cargoType,
    this.truckType,
    this.truckTypeLabel,
    this.cargoDescription,
    this.weightTons,
    this.volumeCbm,
    this.quantity,
    this.quantityUnit,
    this.pickupAddress,
    this.pickupCity,
    this.pickupLat,
    this.pickupLng,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryLat,
    this.deliveryLng,
    this.requiredDate,
    this.notes,
    this.status,
    this.publishedAt,
    this.customer,
    this.quotations = const [],
    this.quotationsCount,
    this.offerSelectionMode = 'admin',
    this.platformOffer,
    this.paymentTerms = const PaymentTermsSnapshot(),
    this.createdAt,
  });

  final int id;
  final String? reference;
  final String? cargoType;
  final String? truckType;
  final String? truckTypeLabel;
  final String? cargoDescription;
  final double? weightTons;
  final double? volumeCbm;
  final double? quantity;
  final String? quantityUnit;
  final String? pickupAddress;
  final String? pickupCity;
  final double? pickupLat;
  final double? pickupLng;
  final String? deliveryAddress;
  final String? deliveryCity;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime? requiredDate;
  final String? notes;
  final String? status;
  final DateTime? publishedAt;
  final Organization? customer;
  final List<Quotation> quotations;
  final int? quotationsCount;
  final String offerSelectionMode;
  final PlatformOffer? platformOffer;
  final PaymentTermsSnapshot paymentTerms;
  final DateTime? createdAt;

  bool get canPublish => status == 'draft';
  bool get canCancel => status == 'draft' || status == 'published';
  bool get canEdit => status == 'draft';
  bool get isPrepaid => paymentTerms.prepaid;
  bool get isAwarded => status == 'awarded';

  /// Comparison is only for open requests that still need a decision.
  bool get canCompareQuotations =>
      status == 'published' && !usesAdminSelection;

  bool get usesAdminSelection => offerSelectionMode == 'admin';

  List<Quotation> get awardedQuotations =>
      quotations.where((quotation) => quotation.isAccepted).toList();

  String get routeLabel {
    final from = pickupCity ?? pickupAddress ?? '—';
    final to = deliveryCity ?? deliveryAddress ?? '—';
    return '$from → $to';
  }

  factory ShipmentRequest.fromJson(Map<String, dynamic> json) {
    return ShipmentRequest(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      cargoType: asString(json['cargo_type']),
      truckType: asString(json['truck_type']),
      truckTypeLabel: asString(json['truck_type_label']),
      cargoDescription: asString(json['cargo_description']),
      weightTons: asDouble(json['weight_tons']),
      volumeCbm: asDouble(json['volume_cbm']),
      quantity: asDouble(json['quantity']),
      quantityUnit: asString(json['quantity_unit']),
      pickupAddress: asString(json['pickup_address']),
      pickupCity: asString(json['pickup_city']),
      pickupLat: asDouble(json['pickup_lat']),
      pickupLng: asDouble(json['pickup_lng']),
      deliveryAddress: asString(json['delivery_address']),
      deliveryCity: asString(json['delivery_city']),
      deliveryLat: asDouble(json['delivery_lat']),
      deliveryLng: asDouble(json['delivery_lng']),
      requiredDate: asDateTime(json['required_date']),
      notes: asString(json['notes']),
      status: asString(json['status']),
      publishedAt: asDateTime(json['published_at']),
      customer: json['customer'] is Map
          ? Organization.fromJson(asMap(json['customer']))
          : null,
      quotations: asList(json['quotations'])
          .whereType<Map>()
          .map((item) => Quotation.fromJson(asMap(item)))
          .toList(),
      quotationsCount: asInt(json['quotations_count']),
      offerSelectionMode: asString(json['offer_selection_mode']) ?? 'admin',
      platformOffer: json['platform_offer'] is Map
          ? PlatformOffer.fromJson(asMap(json['platform_offer']))
          : null,
      paymentTerms: PaymentTermsSnapshot.fromJson(
        json['payment_terms'] is Map ? asMap(json['payment_terms']) : null,
      ),
      createdAt: asDateTime(json['created_at']),
    );
  }
}

class CreateShipmentPayload {
  const CreateShipmentPayload({
    required this.cargoType,
    required this.truckType,
    this.cargoDescription,
    required this.weightTons,
    this.volumeCbm,
    required this.quantity,
    this.quantityUnit,
    required this.pickupAddress,
    required this.pickupCity,
    this.pickupLat,
    this.pickupLng,
    required this.deliveryAddress,
    required this.deliveryCity,
    this.deliveryLat,
    this.deliveryLng,
    required this.requiredDate,
    this.notes,
    this.publish = false,
    this.billingTrigger = 'on_delivery',
    this.dueDays = 0,
    this.billingUnit = 'job',
  });

  final String cargoType;
  final String truckType;
  final String? cargoDescription;
  final double weightTons;
  final double? volumeCbm;
  final double quantity;
  final String? quantityUnit;
  final String pickupAddress;
  final String pickupCity;
  final double? pickupLat;
  final double? pickupLng;
  final String deliveryAddress;
  final String deliveryCity;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime requiredDate;
  final String? notes;
  final bool publish;
  final String billingTrigger;
  final int dueDays;
  final String billingUnit;

  Map<String, dynamic> toJson() {
    return {
      'cargo_type': cargoType,
      'truck_type': truckType,
      if (cargoDescription != null && cargoDescription!.isNotEmpty)
        'cargo_description': cargoDescription,
      'weight_tons': weightTons,
      if (volumeCbm != null) 'volume_cbm': volumeCbm,
      'quantity': quantity,
      if (quantityUnit != null && quantityUnit!.isNotEmpty)
        'quantity_unit': quantityUnit,
      'pickup_address': pickupAddress,
      'pickup_city': pickupCity,
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      'delivery_address': deliveryAddress,
      'delivery_city': deliveryCity,
      if (deliveryLat != null) 'delivery_lat': deliveryLat,
      if (deliveryLng != null) 'delivery_lng': deliveryLng,
      'required_date': requiredDate.toIso8601String().split('T').first,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'publish': publish,
      'billing_trigger': billingTrigger,
      'due_days': billingTrigger == 'on_award' ? 0 : dueDays,
      'billing_unit': billingTrigger == 'on_award' ? 'job' : billingUnit,
    };
  }
}
