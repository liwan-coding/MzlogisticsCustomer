import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/pagination_meta.dart';
import 'trip_model.dart';

class TripRepository {
  TripRepository(this._api);

  final ApiClient _api;

  Future<PagedResult<Trip>> list({
    int page = 1,
    String? status,
    int? perPage,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (perPage != null) query['per_page'] = perPage;
    final envelope = await _api.get('/trips', query: query);
    return PagedResult(
      items: envelope.list
          .whereType<Map>()
          .map((item) => Trip.fromJson(asMap(item)))
          .toList(),
      meta: PaginationMeta.fromJson(
        envelope.meta.isEmpty ? envelope.map : envelope.meta,
      ),
    );
  }

  Future<Trip> getById(int id) async {
    final envelope = await _api.get('/trips/$id');
    return Trip.fromJson(envelope.map);
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(apiClientProvider));
});
