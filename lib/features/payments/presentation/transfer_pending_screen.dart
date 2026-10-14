import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_glyph.dart';
import '../../../shared/widgets/entity_summary_card.dart';
import '../../../shared/widgets/info_row.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/bank_account.dart';
import '../data/payment_repository.dart';
import '../data/transfer_pending_args.dart';
import 'payment_providers.dart';

class TransferPendingScreen extends ConsumerStatefulWidget {
  const TransferPendingScreen({super.key, required this.args});

  final TransferPendingArgs args;

  @override
  ConsumerState<TransferPendingScreen> createState() => _TransferPendingScreenState();
}

class _TransferPendingScreenState extends ConsumerState<TransferPendingScreen> {
  static const _maxBytes = 5 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _picker = ImagePicker();

  BankAccount? _loadedAccount;
  Uint8List? _bytes;
  String? _filename;
  bool _submitting = false;
  bool _uploaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uploaded = widget.args.receiptUploaded;
    if (!widget.args.bankAccount.hasDetails) {
      _loadAccount();
    }
  }

  BankAccount get _account => _loadedAccount ?? widget.args.bankAccount;

  bool get _canUseCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _loadAccount() async {
    try {
      final account = await ref.read(paymentRepositoryProvider).bankAccount();
      if (!mounted) return;
      setState(() => _loadedAccount = account);
    } catch (_) {
      // Account details help the customer transfer. Upload still works without them.
    }
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (file == null || !mounted) return;

    final i18n = ref.i18n;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final extension = _extensionOf(file.name);
    if (extension == null || !_allowedExtensions.contains(extension)) {
      setState(() => _error = i18n.t('payment.receiptInvalid'));
      return;
    }
    if (bytes.length > _maxBytes) {
      setState(() => _error = i18n.t('payment.receiptTooLarge'));
      return;
    }

    setState(() {
      _bytes = bytes;
      _filename = 'receipt.$extension';
      _error = null;
    });
  }

  String? _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  Future<void> _submit() async {
    final i18n = ref.i18n;
    final paymentId = widget.args.paymentId;
    final bytes = _bytes;
    final filename = _filename;
    if (paymentId == null || paymentId < 1) {
      setState(() => _error = i18n.t('payment.receiptMissingPayment'));
      return;
    }
    if (bytes == null || filename == null) {
      setState(() => _error = i18n.t('payment.receiptRequired'));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).uploadReceipt(
            id: paymentId,
            bytes: bytes,
            filename: filename,
          );
      ref.invalidate(paymentsProvider);
      if (!mounted) return;
      setState(() {
        _uploaded = true;
        _bytes = null;
        _filename = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, i18n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _message(Object error, I18nBundle i18n) {
    if (error is ApiException && error.message == 'network') {
      return i18n.t('common.networkError');
    }
    if (error is ApiException) {
      return error.fieldError('receipt') ?? error.fieldError('payment') ?? error.message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final args = widget.args;
    final account = _account;
    final preview = _bytes;
    final body = i18n.t(args.invoicePayment ? 'payment.transferInvoiceBody' : 'payment.transferBody');
    final summary = AppAppear(
      index: 0,
      child: EntitySummaryCard(
        title: args.reference.isEmpty ? i18n.t('payment.transferTitle') : args.reference,
        subtitle: body,
        icon: Icons.account_balance_outlined,
        badge: StatusBadge(status: 'pending', label: i18n.status('pending')),
      ),
    );
    final receipt = AppAppear(
      index: 2,
      child: _ReceiptCard(
        i18n: i18n,
        preview: preview,
        uploaded: _uploaded,
        error: _error,
        submitting: _submitting,
        canUseCamera: _canUseCamera,
        onChoose: () => _pick(ImageSource.gallery),
        onCamera: () => _pick(ImageSource.camera),
        onSubmit: preview == null ? null : _submit,
        onViewPayments: () => context.go('/payments'),
      ),
    );
    final accountCard = account.hasDetails
        ? AppAppear(
            index: 1,
            child: SectionCard(
              title: i18n.t('payment.transferAccount'),
              icon: Icons.account_balance_outlined,
              child: Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  _AccountValue(label: i18n.t('payment.bankName'), value: account.bankName),
                  _AccountValue(label: i18n.t('payment.accountName'), value: account.accountName),
                  _AccountValue(label: i18n.t('payment.accountNumber'), value: account.accountNumber),
                  _AccountValue(label: i18n.t('payment.iban'), value: account.iban),
                ],
              ),
            ),
          )
        : null;

    return PageScaffold(
      title: i18n.t('payment.transferTitle'),
      showBack: true,
      body: ContentWidth(
        child: PageList(
          children: [
            summary,
            const SizedBox(height: 16),
            if (accountCard == null)
              receipt
            else if (context.isMobile)
              Column(
                children: [
                  accountCard,
                  const SizedBox(height: 16),
                  receipt,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: accountCard),
                  const SizedBox(width: 16),
                  Expanded(child: receipt),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountValue extends StatelessWidget {
  const _AccountValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.i18n,
    required this.preview,
    required this.uploaded,
    required this.error,
    required this.submitting,
    required this.canUseCamera,
    required this.onChoose,
    required this.onCamera,
    required this.onSubmit,
    required this.onViewPayments,
  });

  final I18nBundle i18n;
  final Uint8List? preview;
  final bool uploaded;
  final String? error;
  final bool submitting;
  final bool canUseCamera;
  final VoidCallback onChoose;
  final VoidCallback onCamera;
  final VoidCallback? onSubmit;
  final VoidCallback onViewPayments;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chooseLabel = preview != null || uploaded
        ? i18n.t('payment.changeReceipt')
        : i18n.t('payment.chooseReceipt');

    return SectionCard(
      title: i18n.t('payment.receiptLabel'),
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            i18n.t('payment.receiptHint'),
            style: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          _ReceiptFrame(
            label: chooseLabel,
            preview: preview,
            enabled: !submitting,
            cameraLabel: canUseCamera ? i18n.t('payment.takeReceiptPhoto') : null,
            onChoose: onChoose,
            onCamera: onCamera,
          ),
          if (uploaded) ...[
            const SizedBox(height: 12),
            _Notice(
              message: i18n.t('payment.receiptUploaded'),
              icon: Icons.check_rounded,
              tone: AppGlyphTone.success,
              color: AppColors.success,
              background: AppColors.successSoft,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            _Notice(
              message: error!,
              icon: Icons.error_outline,
              tone: AppGlyphTone.danger,
              color: AppColors.danger,
              background: AppColors.dangerSoft,
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: i18n.t('payment.submitReceipt'),
            expanded: true,
            loading: submitting,
            onPressed: submitting ? null : onSubmit,
          ),
          const SizedBox(height: 4),
          AppButton(
            label: i18n.t('payment.viewPayments'),
            variant: AppButtonVariant.ghost,
            expanded: true,
            onPressed: submitting ? null : onViewPayments,
          ),
        ],
      ),
    );
  }
}

class _ReceiptFrame extends StatelessWidget {
  const _ReceiptFrame({
    required this.label,
    required this.preview,
    required this.enabled,
    required this.onChoose,
    required this.onCamera,
    this.cameraLabel,
  });

  final String label;
  final Uint8List? preview;
  final bool enabled;
  final VoidCallback onChoose;
  final VoidCallback onCamera;
  final String? cameraLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final image = preview;
    return Material(
      color: image == null ? AppColors.surface : AppColors.mist,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (image == null)
            InkWell(
              onTap: enabled ? onChoose : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                child: Column(
                  children: [
                    const AppGlyph(
                      icon: Icons.add_photo_alternate_outlined,
                      size: 48,
                      iconSize: 24,
                      tone: AppGlyphTone.muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: text.labelLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Image.memory(
              image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: label,
            ),
          if (image != null || cameraLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  if (image != null)
                    TextButton.icon(
                      onPressed: enabled ? onChoose : null,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(label),
                    ),
                  if (cameraLabel != null)
                    TextButton.icon(
                      onPressed: enabled ? onCamera : null,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(cameraLabel!),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.icon,
    required this.tone,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final AppGlyphTone tone;
  final Color color;
  final Color background;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          AppGlyph(icon: icon, size: 32, iconSize: 16, tone: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
