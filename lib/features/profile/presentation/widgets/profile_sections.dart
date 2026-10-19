import 'package:flutter/material.dart';

import '../../../../core/constants/company_contact.dart';
import '../../../../core/i18n/i18n_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/organization.dart';
import '../../../../shared/models/user.dart';
import '../profile_helpers.dart';

class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    super.key,
    required this.i18n,
    required this.user,
  });

  final I18nBundle i18n;
  final UserAccount user;

  @override
  Widget build(BuildContext context) {
    final email = user.email.trim();
    final name = user.name.isEmpty ? i18n.t('profile.title') : user.name;
    final company = user.organization?.displayName(i18n.locale.languageCode);
    final accountStatus = user.isActive ? 'active' : 'inactive';
    final text = Theme.of(context).textTheme;

    return _GroupCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
        child: Row(
          children: [
            _Avatar(name: name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      name,
                      maxLines: 1,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        email,
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                  if (company != null && company.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        company,
                        maxLines: 1,
                        style: text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    [
                      i18n.t('app.customer'),
                      i18n.status(accountStatus),
                    ].join(' · '),
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            if (email.isNotEmpty)
              IconButton(
                tooltip: i18n.t('profile.copy'),
                onPressed: () => copyProfileValue(context, i18n, email),
                icon: const Icon(
                  Icons.copy_outlined,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    super.key,
    required this.i18n,
    required this.user,
    required this.onEdit,
  });

  final I18nBundle i18n;
  final UserAccount user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final phone = user.phone?.trim() ?? '';

    return _SettingsSection(
      title: i18n.t('profile.account'),
      children: [
        _SettingRow(
          icon: Icons.person_outline,
          title: i18n.t('profile.name'),
          value: displayOrDash(i18n, user.name),
          onTap: onEdit,
        ),
        _SettingRow(
          icon: Icons.phone_outlined,
          title: i18n.t('common.phone'),
          value: displayOrDash(i18n, phone),
          ltr: phone.isNotEmpty,
          onTap: onEdit,
        ),
        _SettingRow(
          icon: Icons.mail_outline,
          title: i18n.t('common.email'),
          value: displayOrDash(i18n, user.email),
          ltr: user.email.trim().isNotEmpty,
          copyable: user.email.trim().isNotEmpty,
          onTap: user.email.trim().isEmpty
              ? null
              : () => copyProfileValue(context, i18n, user.email.trim()),
        ),
      ],
    );
  }
}

class ProfileOrganizationCard extends StatelessWidget {
  const ProfileOrganizationCard({
    super.key,
    required this.i18n,
    required this.organization,
  });

  final I18nBundle i18n;
  final Organization? organization;

  @override
  Widget build(BuildContext context) {
    final org = organization;
    if (org == null) {
      return _SettingsSection(
        title: i18n.t('profile.organization'),
        children: [
          _SettingRow(
            icon: Icons.domain_disabled_outlined,
            title: i18n.t('profile.organization'),
            subtitle: i18n.t('profile.noOrganization'),
            showChevron: false,
          ),
        ],
      );
    }

    final locale = i18n.locale.languageCode;
    final location = [
      if (org.city != null && org.city!.trim().isNotEmpty) org.city!.trim(),
      if (org.country != null && org.country!.trim().isNotEmpty)
        org.country!.trim(),
    ].join(' · ');
    final phone = org.phone?.trim() ?? '';
    final email = org.email?.trim() ?? '';
    final cr = org.commercialRegister?.trim() ?? '';
    final tax = org.taxNumber?.trim() ?? '';
    final address = org.address?.trim() ?? '';

    return _SettingsSection(
      title: i18n.t('profile.organization'),
      footer: i18n.t('profile.orgHint'),
      children: [
        _SettingRow(
          icon: Icons.apartment_outlined,
          title: i18n.t('common.name'),
          value: displayOrDash(i18n, org.displayName(locale)),
          showChevron: false,
        ),
        if (cr.isNotEmpty)
          _SettingRow(
            icon: Icons.badge_outlined,
            title: i18n.t('profile.cr'),
            value: cr,
            ltr: true,
            copyable: true,
            onTap: () => copyProfileValue(context, i18n, cr),
          ),
        if (tax.isNotEmpty)
          _SettingRow(
            icon: Icons.receipt_long_outlined,
            title: i18n.t('profile.tax'),
            value: tax,
            ltr: true,
            copyable: true,
            onTap: () => copyProfileValue(context, i18n, tax),
          ),
        if (email.isNotEmpty)
          _SettingRow(
            icon: Icons.mail_outline,
            title: i18n.t('common.email'),
            value: email,
            ltr: true,
            copyable: true,
            onTap: () => copyProfileValue(context, i18n, email),
          ),
        if (phone.isNotEmpty)
          _SettingRow(
            icon: Icons.phone_outlined,
            title: i18n.t('common.phone'),
            value: phone,
            ltr: true,
            copyable: true,
            onTap: () => copyProfileValue(context, i18n, phone),
          ),
        if (location.isNotEmpty)
          _SettingRow(
            icon: Icons.place_outlined,
            title: i18n.t('profile.location'),
            value: location,
            showChevron: false,
          ),
        if (address.isNotEmpty)
          _SettingRow(
            icon: Icons.home_outlined,
            title: i18n.t('common.address'),
            value: address,
            copyable: true,
            onTap: () => copyProfileValue(context, i18n, address),
          ),
      ],
    );
  }
}

class ProfileContactCard extends StatelessWidget {
  const ProfileContactCard({super.key, required this.i18n});

  final I18nBundle i18n;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: i18n.t('profile.contact'),
      footer: i18n.t('profile.contactHint'),
      children: [
        _SettingRow(
          icon: Icons.phone_outlined,
          title: i18n.t('footer.phone'),
          value: CompanyContact.phoneDisplay,
          ltr: true,
          onTap: () => CompanyContact.open(CompanyContact.phoneUri),
        ),
        _SettingRow(
          icon: Icons.chat_outlined,
          title: i18n.t('profile.whatsapp'),
          value: CompanyContact.phoneDisplay,
          ltr: true,
          onTap: () => CompanyContact.open(CompanyContact.whatsappUri),
        ),
        _SettingRow(
          icon: Icons.photo_camera_outlined,
          title: i18n.t('profile.instagram'),
          value: CompanyContact.instagramHandle,
          ltr: true,
          onTap: () => CompanyContact.open(CompanyContact.instagramUri),
        ),
      ],
    );
  }
}

class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({
    super.key,
    required this.i18n,
    required this.selectedLanguage,
    required this.onLanguageSelected,
    required this.onChangePassword,
    required this.onLogout,
  });

  final I18nBundle i18n;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageSelected;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: i18n.t('profile.settings'),
      children: [
        _LanguageRow(
          i18n: i18n,
          selected: selectedLanguage,
          onSelected: onLanguageSelected,
        ),
        _SettingRow(
          icon: Icons.lock_outline,
          title: i18n.t('profile.password'),
          subtitle: i18n.t('profile.passwordSectionHint'),
          onTap: onChangePassword,
        ),
        _SettingRow(
          icon: Icons.logout_rounded,
          title: i18n.t('common.logout'),
          subtitle: i18n.t('profile.sessionHint'),
          iconColor: AppColors.danger,
          titleColor: AppColors.danger,
          showChevron: false,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.i18n,
    required this.selected,
    required this.onSelected,
  });

  final I18nBundle i18n;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      icon: Icons.translate_outlined,
      title: i18n.t('profile.preferences'),
      value: selected == 'ar'
          ? i18n.t('profile.arabicNative')
          : i18n.t('profile.englishNative'),
      ltr: selected == 'en',
      onTap: () => _openLanguageSheet(context),
    );
  }

  Future<void> _openLanguageSheet(BuildContext context) async {
    final next = await showProfileSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  i18n.t('profile.preferences'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t('profile.languageHint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 16),
                _LanguageChoice(
                  code: 'ar',
                  title: i18n.t('profile.arabicNative'),
                  selected: selected == 'ar',
                  onTap: () => Navigator.pop(context, 'ar'),
                ),
                const SizedBox(height: 10),
                _LanguageChoice(
                  code: 'en',
                  title: i18n.t('profile.englishNative'),
                  selected: selected == 'en',
                  onTap: () => Navigator.pop(context, 'en'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (next != null) onSelected(next);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _GroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(
              title,
              style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 68),
                child: Divider(height: 1),
              ),
          ],
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                footer!,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0E1B3D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.ltr = false,
    this.showChevron = true,
    this.copyable = false,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final bool ltr;
  final bool showChevron;
  final bool copyable;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.navy;
    final hasValue = value != null && value!.isNotEmpty;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? AppColors.ink,
                        ),
                      ),
                      if (hasValue) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Directionality(
                              textDirection: ltr
                                  ? TextDirection.ltr
                                  : Directionality.of(context),
                              child: Text(
                                value!,
                                maxLines: 1,
                                softWrap: false,
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: text.labelSmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.copy_outlined,
                color: AppColors.muted,
                size: 18,
              ),
            ] else if (showChevron) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.navySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsFor(name),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.code,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? AppColors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.navy : AppColors.border,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
