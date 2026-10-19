import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/widgets/app_appear.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../auth/presentation/auth_controller.dart';
import 'widgets/profile_edit_sheets.dart';
import 'widgets/profile_sections.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return PageScrollView(child: LoadingState(label: i18n.t('common.loading')));
    }

    final account = ProfileAccountCard(
      i18n: i18n,
      user: user,
      onEdit: () => _editAccount(context, ref, i18n, user.name, user.phone ?? ''),
    );
    final organization = ProfileOrganizationCard(
      i18n: i18n,
      organization: user.organization,
    );
    final contact = ProfileContactCard(i18n: i18n);
    final settings = ProfileSettingsCard(
      i18n: i18n,
      selectedLanguage: i18n.locale.languageCode,
      onLanguageSelected: (code) => _changeLocale(context, ref, i18n, code),
      onChangePassword: () => _changePassword(context, ref, i18n),
      onLogout: () => _logout(context, ref, i18n),
    );
    final wide = !context.isMobile;

    const gap = 22.0;

    return PageScrollView(
      child: ContentWidth(
      child: PageList(
          physics: const AlwaysScrollableScrollPhysics(),
          onRefresh: () async {
            await ref.read(authControllerProvider.notifier).refreshProfile();
          },
          children: [
            AppAppear(
              index: 0,
              child: ProfileIdentityHeader(i18n: i18n, user: user),
            ),
            const SizedBox(height: gap),
            if (wide) ...[
              AppAppear(
                index: 1,
                child: EqualCardRow(
                  gap: 16,
                  children: [account, contact],
                ),
              ),
              const SizedBox(height: gap),
              AppAppear(
                index: 2,
                child: EqualCardRow(
                  gap: 16,
                  children: [organization, settings],
                ),
              ),
            ]
            else ...[
              AppAppear(index: 1, child: account),
              const SizedBox(height: gap),
              AppAppear(index: 2, child: organization),
              const SizedBox(height: gap),
              AppAppear(index: 3, child: contact),
              const SizedBox(height: gap),
              AppAppear(index: 4, child: settings),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref,
    I18nBundle i18n,
    String name,
    String phone,
  ) async {
    final saved = await showEditAccountSheet(
      context: context,
      i18n: i18n,
      name: name,
      phone: phone,
      onSave: (nextName, nextPhone) {
        return ref.read(authControllerProvider.notifier).updateProfile(
              name: nextName,
              phone: nextPhone,
            );
      },
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(i18n.t('profile.saved'))));
  }

  Future<void> _changePassword(
    BuildContext context,
    WidgetRef ref,
    I18nBundle i18n,
  ) async {
    final saved = await showChangePasswordSheet(
      context: context,
      i18n: i18n,
      onSave: ({
        required currentPassword,
        required password,
        required passwordConfirmation,
      }) {
        return ref.read(authControllerProvider.notifier).updatePassword(
              currentPassword: currentPassword,
              password: password,
              passwordConfirmation: passwordConfirmation,
            );
      },
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(i18n.t('profile.passwordSaved'))),
    );
  }

  Future<void> _changeLocale(
    BuildContext context,
    WidgetRef ref,
    I18nBundle i18n,
    String code,
  ) async {
    if (code == i18n.locale.languageCode) return;
    await ref.read(i18nControllerProvider.notifier).setLocale(code);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(locale: code);
    } catch (_) {
      // Local language still updates even if the profile sync fails.
    }
    if (!context.mounted) return;
    final next = ref.read(i18nControllerProvider).asData?.value ?? i18n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.t('profile.localeSaved'))),
    );
  }

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
    I18nBundle i18n,
  ) async {
    final ok = await showConfirmDialog(
      context,
      i18n: i18n,
      title: i18n.t('common.logout'),
      message: i18n.t('common.logoutConfirm'),
      danger: true,
    );
    if (!ok) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}
