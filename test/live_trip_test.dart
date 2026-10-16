import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_customer_app/features/home/data/live_trip.dart';
import 'package:mz_logistics_customer_app/features/trips/data/trip_model.dart';

void main() {
  test('nearest moving trip is the soonest arrival', () {
    final later = Trip(
      id: 1,
      status: 'in_transit',
      etaAt: DateTime.utc(2026, 10, 15, 18),
      inTransitAt: DateTime.utc(2026, 10, 15, 8),
    );
    final sooner = Trip(
      id: 2,
      status: 'in_transit',
      etaAt: DateTime.utc(2026, 10, 15, 14),
      inTransitAt: DateTime.utc(2026, 10, 15, 6),
    );
    final parked = Trip(id: 3, status: 'loaded');

    expect(nearestMovingTrip([later, parked, sooner])?.id, 2);
  });

  test('a trip without an arrival time falls behind one that has it', () {
    final dated = Trip(
      id: 4,
      status: 'in_transit',
      etaAt: DateTime.utc(2026, 10, 16, 9),
    );
    final undated = Trip(
      id: 5,
      status: 'in_transit',
      inTransitAt: DateTime.utc(2026, 10, 15, 7),
    );

    expect(nearestMovingTrip([undated, dated])?.id, 4);
  });

  test('a loaded trip is featured when nothing is further along', () {
    expect(
      nearestMovingTrip([
        const Trip(id: 3, status: 'loaded'),
        const Trip(id: 7, status: 'delivered'),
        const Trip(id: 8, status: 'cancelled'),
      ])?.id,
      3,
    );
  });

  test('an in-transit trip stays ahead of one that is only loaded', () {
    expect(
      nearestMovingTrip([
        const Trip(id: 3, status: 'loaded'),
        const Trip(id: 2, status: 'in_transit'),
      ])?.id,
      2,
    );
  });

  test('finished trips are not featured', () {
    expect(
      nearestMovingTrip([
        const Trip(id: 6, status: 'completed'),
        const Trip(id: 7, status: 'cancelled'),
      ]),
      isNull,
    );
  });
}
