import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trips/data/trip_model.dart';
import '../../trips/data/trip_repository.dart';
import '../data/dashboard_model.dart';
import '../data/dashboard_repository.dart';
import '../data/live_trip.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});

const _liveTripRefresh = Duration(seconds: 15);

/// The customer's current moving trip, refreshed while one is on the road.
final featuredInTransitTripProvider = FutureProvider.autoDispose<Trip?>((
  ref,
) async {
  final page = await ref
      .watch(tripRepositoryProvider)
      .list(status: featuredTripStatuses.join(','), perPage: 15);
  final trip = nearestMovingTrip(page.items);
  if (trip != null) {
    final timer = Timer(_liveTripRefresh, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return trip;
});
