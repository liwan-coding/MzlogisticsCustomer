import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../quotations/presentation/quotation_accept_flow.dart';
import '../data/shipment_model.dart';
import '../data/shipment_repository.dart';
import 'shipment_providers.dart';
import 'widgets/shipment_detail_sections.dart';

class ShipmentDetailScreen extends ConsumerStatefulWidget {
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  ConsumerState<ShipmentDetailScreen> createState() =>
      _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends ConsumerState<ShipmentDetailScreen> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action, String successKey) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ref.invalidate(shipmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ref.i18n.t(successKey))));
    } catch (error) {
      if (!mounted) return;
      final i18n = ref.i18n;
      final message = error is ApiException && error.message == 'network'
          ? i18n.t('common.networkError')
          : error.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish(ShipmentRequest shipment) async {
    final i18n = ref.i18n;
    final ok = await showConfirmDialog(
      context,
      i18n: i18n,
      title: i18n.t('shipment.publish'),
      message: i18n.t('shipment.publishConfirm'),
    );
    if (!ok || !mounted) return;
    await _act(
      () => ref.read(shipmentRepositoryProvider).publish(shipment.id),
      'shipment.published',
    );
  }

  Future<void> _cancel(ShipmentRequest shipment) async {
    final i18n = ref.i18n;
    final ok = await showConfirmDialog(
      context,
      i18n: i18n,
      title: i18n.t('shipment.cancelRequest'),
      message: i18n.t('shipment.cancelConfirm'),
      danger: true,
    );
    if (!ok || !mounted) return;
    await _act(
      () => ref.read(shipmentRepositoryProvider).cancel(shipment.id),
      'shipment.cancelled',
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final value = ref.watch(shipmentDetailProvider(widget.shipmentId));

    return PageScaffold(
      title: i18n.t('shipment.detail'),
      showBack: true,
      body: AsyncBody<ShipmentRequest>(
        value: value,
        i18n: i18n,
        onRetry: () =>
            ref.invalidate(shipmentDetailProvider(widget.shipmentId)),
        onRefresh: () async {
          ref.invalidate(shipmentDetailProvider(widget.shipmentId));
          await ref.read(shipmentDetailProvider(widget.shipmentId).future);
        },
        builder: (shipment) {
          final locale = i18n.locale.languageCode;
          final status = shipment.status ?? '';
          final cargo = shipment.cargoType?.trim();
          final reference = shipment.reference?.trim();
          final title = (cargo != null && cargo.isNotEmpty)
              ? cargo
              : (reference != null && reference.isNotEmpty)
                  ? reference
                  : i18n.t('shipment.detail');
          final listedQuotes = shipment.canCompareQuotations
              ? shipment.quotations
              : shipment.awardedQuotations;
          final showCompare = shipment.canCompareQuotations;
          final showQuotes = listedQuotes.isNotEmpty || showCompare;

          final quotations = ShipmentQuotationsSection(
            i18n: i18n,
            quotations: listedQuotes,
            showCompare: showCompare,
          );

          return ContentWidth(
            child: PageList(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppAppear(
                  index: 0,
                  child: ShipmentStageCard(
                    i18n: i18n,
                    shipment: shipment,
                    locale: locale,
                  ),
                ),
                const SizedBox(height: 16),
                AppAppear(
                  index: 1,
                  child: ShipmentSummaryPanel(
                    i18n: i18n,
                    shipment: shipment,
                    title: title,
                    reference: reference != null &&
                            reference.isNotEmpty &&
                            reference != title
                        ? reference
                        : null,
                    status: status,
                    locale: locale,
                    busy: _busy,
                    onPublish: () => _publish(shipment),
                    onCancel: () => _cancel(shipment),
                    onCompare: () =>
                        context.push('/shipments/${shipment.id}/quotations'),
                  ),
                ),
                const SizedBox(height: 16),
                AppAppear(
                  index: 2,
                  child: ShipmentRecordLayout(i18n: i18n, shipment: shipment),
                ),
                if (shipment.platformOffer != null &&
                    (shipment.status == 'published' ||
                        shipment.status == 'awarded')) ...[
                  const SizedBox(height: 16),
                  AppAppear(
                    index: 2,
                    child: ShipmentPlatformOfferSection(
                      i18n: i18n,
                      shipment: shipment,
                      onAccept: () {
                        final offer = shipment.platformOffer;
                        if (offer == null) return;
                        startPlatformOfferAcceptance(
                          context: context,
                          ref: ref,
                          offer: offer,
                          prepaid: shipment.isPrepaid,
                          shipmentId: shipment.id,
                        );
                      },
                    ),
                  ),
                ],
                if (showQuotes) ...[
                  const SizedBox(height: 16),
                  AppAppear(index: 2, child: quotations),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
