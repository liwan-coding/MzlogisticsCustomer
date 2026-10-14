import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../home/presentation/home_providers.dart';
import '../../invoices/presentation/invoice_providers.dart';
import '../../jobs/presentation/job_providers.dart';
import '../../shipments/presentation/shipment_providers.dart';
import '../data/payment_repository.dart';
import '../data/payment_status_result.dart';
import 'payment_providers.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    this.paymentId,
    this.jobId,
    this.success = true,
  });

  final int? paymentId;
  final int? jobId;
  final bool success;

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (widget.jobId != null && widget.success) {
      ref.invalidate(jobsProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(shipmentsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(jobDetailProvider(widget.jobId!));
      if (!mounted) return;
      context.go('/jobs/${widget.jobId}');
      return;
    }

    final paymentId = widget.paymentId;
    if (paymentId == null) return;

    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .status(paymentId);
      if (!mounted) return;
      ref.invalidate(jobsProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(shipmentsProvider);
      ref.invalidate(dashboardProvider);
      if (result.isPaid && result.job != null) {
        ref.invalidate(jobDetailProvider(result.job!.id));
        context.go('/jobs/${result.job!.id}');
        return;
      }
      setState(() {
        _checking = false;
        _error = ref.i18n.t('payment.pendingConfirmation');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    return PageScaffold(
      title: i18n.t('payment.successTitle'),
      showBack: true,
      body: ContentWidth(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.success
                    ? i18n.t('payment.successBody')
                    : i18n.t('payment.pendingConfirmation'),
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: i18n.t('payment.checkStatus'),
                loading: _checking,
                expanded: true,
                onPressed: _resolve,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: i18n.t('payment.viewPayments'),
                variant: AppButtonVariant.ghost,
                expanded: true,
                onPressed: () => context.go('/payments'),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentCancelScreen extends ConsumerStatefulWidget {
  const PaymentCancelScreen({
    super.key,
    this.paymentId,
    this.jobId,
    this.invoicePayment = false,
  });

  final int? paymentId;
  final int? jobId;
  final bool invoicePayment;

  @override
  ConsumerState<PaymentCancelScreen> createState() =>
      _PaymentCancelScreenState();
}

class _PaymentCancelScreenState extends ConsumerState<PaymentCancelScreen> {
  PaymentStatusResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final paymentId = widget.paymentId;
    if (paymentId == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .status(paymentId);
      if (!mounted) return;
      ref.invalidate(paymentsProvider);
      ref.invalidate(invoicesProvider);
      if (result.job != null) {
        ref.invalidate(jobDetailProvider(result.job!.id));
        ref.invalidate(jobsProvider);
      }
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _invoiceCheckout {
    if (widget.invoicePayment || widget.jobId != null) return true;
    return _result?.settlesExistingJob == true;
  }

  int? get _jobId => _result?.job?.id ?? widget.jobId;

  String _bodyKey() {
    if (_invoiceCheckout) return 'payment.cancelInvoiceBody';
    if (_result != null) return 'payment.cancelQuotationBody';
    return 'payment.cancelBody';
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final jobId = _jobId;
    return PageScaffold(
      title: i18n.t('payment.cancelTitle'),
      showBack: true,
      body: ContentWidth(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.t(_bodyKey()),
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (_loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 24),
              ],
              if (_invoiceCheckout && jobId != null) ...[
                AppButton(
                  label: i18n.t('payment.viewJob'),
                  expanded: true,
                  onPressed: () => context.go('/jobs/$jobId'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: i18n.t('invoice.title'),
                  variant: AppButtonVariant.ghost,
                  expanded: true,
                  onPressed: () => context.go('/invoices'),
                ),
              ] else if (_invoiceCheckout) ...[
                AppButton(
                  label: i18n.t('invoice.title'),
                  expanded: true,
                  onPressed: () => context.go('/invoices'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: i18n.t('payment.viewPayments'),
                  variant: AppButtonVariant.ghost,
                  expanded: true,
                  onPressed: () => context.go('/payments'),
                ),
              ] else ...[
                AppButton(
                  label: i18n.t('payment.viewPayments'),
                  expanded: true,
                  onPressed: () => context.go('/payments'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: i18n.t('nav.shipments'),
                  variant: AppButtonVariant.ghost,
                  expanded: true,
                  onPressed: () => context.go('/shipments'),
                ),
              ],
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
