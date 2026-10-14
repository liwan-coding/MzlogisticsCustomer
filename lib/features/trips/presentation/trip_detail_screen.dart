import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../tracking/presentation/tracking_panel.dart';
import '../data/trip_model.dart';
import 'trip_providers.dart';
import 'widgets/trip_board.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final value = ref.watch(tripDetailProvider(tripId));

    return PageScaffold(
      title: i18n.t('trip.detail'),
      showBack: true,
      body: AsyncBody<Trip>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        onRefresh: () async {
          ref.invalidate(tripDetailProvider(tripId));
          await ref.read(tripDetailProvider(tripId).future);
        },
        builder: (trip) {
          return ContentWidth(
            child: PageList(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                TripBoard(i18n: i18n, trip: trip),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TripTrackingScreen extends ConsumerWidget {
  const TripTrackingScreen({super.key, required this.tripId});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final value = ref.watch(tripDetailProvider(tripId));
    return PageScaffold(
      title: i18n.t('tracking.title'),
      showBack: true,
      body: AsyncBody<Trip>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        builder: (trip) => ContentWidth(
          child: AppAppear(
            index: 0,
            child: TrackingPanel(trip: trip, i18n: i18n),
          ),
        ),
      ),
    );
  }
}
