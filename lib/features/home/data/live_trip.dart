import '../../trips/data/trip_model.dart';

/// Trips the customer still needs to follow. Delivered and cancelled trips stay off the home card.
const featuredTripStatuses = [
  'assigned',
  'arrived_at_pickup',
  'loaded',
  'in_transit',
  'arrived',
];

/// The active trip a customer should see first: furthest along, then soonest arrival.
Trip? nearestMovingTrip(Iterable<Trip> trips) {
  final moving = [
    for (final trip in trips)
      if (_rank(trip.status) > 0) trip,
  ];
  if (moving.isEmpty) return null;
  moving.sort((a, b) {
    final byRank = _rank(b.status).compareTo(_rank(a.status));
    if (byRank != 0) return byRank;
    final byEta = _soonest(a.etaAt, b.etaAt);
    if (byEta != 0) return byEta;
    return _soonest(_activity(b), _activity(a));
  });
  return moving.first;
}

int _rank(String? status) {
  return switch (status) {
    'in_transit' => 5,
    'arrived' => 4,
    'loaded' => 3,
    'arrived_at_pickup' => 2,
    'assigned' => 1,
    _ => 0,
  };
}

DateTime? _activity(Trip trip) {
  return trip.inTransitAt ??
      trip.loadedAt ??
      trip.arrivedPickupAt ??
      trip.assignedAt ??
      trip.createdAt;
}

int _soonest(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
