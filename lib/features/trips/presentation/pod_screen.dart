import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/authenticated_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/info_row.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/trip_model.dart';
import 'trip_providers.dart';

class PodScreen extends ConsumerWidget {
  const PodScreen({super.key, required this.tripId});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final value = ref.watch(tripDetailProvider(tripId));

    return PageScaffold(
      title: i18n.t('pod.title'),
      showBack: true,
      body: AsyncBody<Trip>(
        value: value,
        i18n: i18n,
        onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        builder: (trip) {
          final pod = trip.proofOfDelivery;
          if (pod == null) {
            return EmptyState(
              title: i18n.t('pod.empty'),
              icon: Icons.photo_outlined,
            );
          }
          final locale = i18n.locale.languageCode;
          return ContentWidth(
            child: PageList(
              children: [
                AppAppear(
                  index: 0,
                  child: SectionCard(
                  title: i18n.t('pod.title'),
                  icon: Icons.verified_rounded,
                  trailing: StatusBadge(
                    status: pod.otpVerified ? 'completed' : 'pending',
                    label: pod.otpVerified ? i18n.t('pod.otpVerified') : i18n.t('pod.otpPending'),
                  ),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      InfoRow(label: i18n.t('pod.receiver'), value: pod.receiverName ?? '—', icon: Icons.person_outline),
                      InfoRow(label: i18n.t('pod.receivedQty'), value: formatNumber(pod.receivedQuantity), icon: Icons.inventory_2_outlined),
                      InfoRow(label: i18n.t('pod.otp'), value: pod.otpVerified ? i18n.t('common.verified') : i18n.t('common.unverified'), icon: Icons.lock_outline),
                      InfoRow(label: i18n.t('pod.capturedAt'), value: formatDateTime(pod.capturedAt, locale: locale), icon: Icons.schedule_outlined),
                      if (pod.notes != null)
                        InfoRow(label: i18n.t('common.notes'), value: pod.notes!, wide: true, icon: Icons.sticky_note_2_outlined),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 16),
                Text(
                  i18n.t('common.photos'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (pod.photoPaths.isEmpty)
                  Text(i18n.t('pod.noPhotos'), style: const TextStyle(color: AppColors.muted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in pod.photoPaths.indexed)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          child: AuthenticatedImage(
                            path: '/trips/${trip.id}/pod/photos/${entry.$1}',
                            width: 160,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                if (pod.signaturePath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    i18n.t('pod.signature'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  AuthenticatedImage(
                    path: '/trips/${trip.id}/pod/signature',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ],
                if (pod.invoicePath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    i18n.t('pod.invoice'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  AuthenticatedImage(
                    path: '/trips/${trip.id}/pod/invoice',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ],
                if (pod.weightTicketPath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    i18n.t('pod.weightTicket'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  AuthenticatedImage(
                    path: '/trips/${trip.id}/pod/weight-ticket',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
