import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/pagination_meta.dart';
import '../data/shipment_model.dart';
import '../data/shipment_repository.dart';
import '../data/truck_type.dart';
import '../data/truck_type_repository.dart';

final shipmentsProvider =
    FutureProvider.autoDispose<PagedResult<ShipmentRequest>>((ref) {
  return ref.watch(shipmentRepositoryProvider).list();
});

final truckTypesProvider = FutureProvider.autoDispose<List<TruckTypeOption>>((
  ref,
) {
  return ref.watch(truckTypeRepositoryProvider).active();
});

final shipmentDetailProvider =
    FutureProvider.autoDispose.family<ShipmentRequest, int>((ref, id) {
  return ref.watch(shipmentRepositoryProvider).getById(id);
});
