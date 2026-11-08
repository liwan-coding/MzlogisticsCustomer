import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import 'auth_controller.dart';
import 'auth_layout.dart';

class AccountReviewScreen extends ConsumerStatefulWidget {
  const AccountReviewScreen({super.key});

  @override
  ConsumerState<AccountReviewScreen> createState() => _AccountReviewScreenState();
}

class _AccountReviewScreenState extends ConsumerState<AccountReviewScreen> {
  var _refreshing = false;
  String? _notice;

  String _titleKey(String? status) {
    return switch (status) {
      'rejected' => 'auth.restrictedRejectedTitle',
      'suspended' => 'auth.restrictedSuspendedTitle',
      _ => 'auth.pendingReviewTitle',
    };
  }

  String _bodyKey(String? status) {
    return switch (status) {
      'rejected' => 'auth.restrictedRejected',
      'suspended' => 'auth.restrictedSuspended',
      _ => 'auth.pendingReview',
    };
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      if (ref.read(authControllerProvider).isAccountRestricted) {
        setState(() => _notice = ref.i18n.t('auth.statusUnchanged'));
      }
    } catch (error) {
      if (!mounted) return;
      final i18n = ref.i18n;
      final message = error is ApiException && error.message == 'network'
          ? i18n.t('common.networkError')
          : error.toString();
      setState(() => _notice = message);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    final i18n = ref.i18n;
    final ok = await showConfirmDialog(
      context,
      i18n: i18n,
      title: i18n.t('common.logout'),
      message: i18n.t('common.logoutConfirm'),
      danger: true,
    );
    if (!ok || !mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final user = ref.watch(authControllerProvider).user;
    final status = user?.organization?.status ?? 'pending';
    final name = user?.organization?.displayName(i18n.locale.languageCode) ?? user?.name ?? '';

    return AuthLayout(
      title: i18n.t(_titleKey(status)),
      subtitle: i18n.t(_bodyKey(status)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: status, label: i18n.status(status)),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Text(
              i18n.t('auth.pendingReviewHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.45),
            ),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(_notice!, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: i18n.t('auth.refreshStatus'),
            loading: _refreshing,
            expanded: true,
            onPressed: _refresh,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: i18n.t('common.logout'),
            variant: AppButtonVariant.ghost,
            expanded: true,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}
