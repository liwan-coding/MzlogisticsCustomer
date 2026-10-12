import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json_utils.dart';
import 'truck_type.dart';

class TruckTypeRepository {
  TruckTypeRepository(this._api);

  final ApiClient _api;

  Future<List<TruckTypeOption>> active() async {
    final envelope = await _api.get('/catalog');
    return asList(envelope.map['truck_types'])
        .whereType<Map>()
        .map((item) => TruckTypeOption.fromJson(asMap(item)))
        .where((type) => type.code.isNotEmpty && type.isActive)
        .toList();
  }
}

final truckTypeRepositoryProvider = Provider<TruckTypeRepository>((ref) {
  return TruckTypeRepository(ref.watch(apiClientProvider));
});
