import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/i18n_controller.dart';
import '../../core/router/section_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_header.dart';
import 'hero_title_scope.dart';
import 'inner_hero_band.dart';

class ShellDestination {
  const ShellDestination({
    required this.location,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.shortLabelKey,
    this.mobile = true,
  });

  final String location;
  final String labelKey;
  final String? shortLabelKey;
  final IconData icon;
  final IconData selectedIcon;
  final bool mobile;

  String label(I18nBundle i18n, {bool compact = false}) {
    if (compact && shortLabelKey != null) return i18n.t(shortLabelKey!);
    return i18n.t(labelKey);
  }
}

const shellDestinations = [
  ShellDestination(
    location: '/home',
    labelKey: 'nav.home',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard,
  ),
  ShellDestination(
    location: '/shipments',
    labelKey: 'nav.shipments',
    shortLabelKey: 'nav.shipmentsShort',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  ShellDestination(
    location: '/jobs',
    labelKey: 'nav.jobs',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
  ),
  ShellDestination(
    location: '/invoices',
    labelKey: 'nav.invoices',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    mobile: false,
  ),
  ShellDestination(
    location: '/payments',
    labelKey: 'nav.payments',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    mobile: false,
  ),
  ShellDestination(
    location: '/billing',
    labelKey: 'nav.billing',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
  ShellDestination(
    location: '/profile',
    labelKey: 'nav.profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.navigationShell,
    required this.i18n,
    required this.userName,
    this.unreadCount = 0,
  });

  final StatefulNavigationShell navigationShell;
  final I18nBundle i18n;
  final String userName;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppConstants.desktopBreakpoint;
    final destinations = isDesktop
        ? shellDestinations
              .where((item) => item.location != '/billing')
              .toList()
        : shellDestinations.where((item) => item.mobile).toList();

    final location = normalizeLocation(GoRouterState.of(context).uri.path);
    final selected = _selectedIndex(destinations, isDesktop: isDesktop);
    final sectionRoot = isShellSectionRoot(location);
    final headerDestination = _headerDestination(
      location,
      destinations[selected],
    );

    final header = AppHeader(
      title: i18n.t(headerDestination.labelKey),
      subtitle: _subtitle(headerDestination.location),
      showBack: false,
      actions: [_NotificationButton(i18n: i18n, unreadCount: unreadCount)],
    );

    final isHome = location == '/home';
    final topBar = Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        20,
        0,
      ),
      child: _TopBar(
        i18n: i18n,
        destinations: destinations,
        selectedIndex: selected,
        userName: userName,
        unreadCount: unreadCount,
        onSelect: (index) => _openDestination(destinations, index),
      ),
    );
    final scaffold = isDesktop
        ? Scaffold(
            backgroundColor: const Color(0xFFF7F8FB),
            body: isHome
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      navigationShell,
                      PositionedDirectional(
                        top: 0,
                        start: 0,
                        end: 0,
                        child: topBar,
                      ),
                    ],
                  )
                : HeroBandHost(
                    location: location,
                    header: topBar,
                    pinned: sectionRoot
                        ? HeroTitleData(
                            title: i18n.t(headerDestination.labelKey),
                            subtitle: _subtitle(headerDestination.location),
                            showBack: false,
                          )
                        : null,
                    child: navigationShell,
                  ),
          )
        : Scaffold(
            appBar: sectionRoot ? header : null,
            body: navigationShell,
            bottomNavigationBar: _BottomNavBar(
              i18n: i18n,
              destinations: destinations,
              selectedIndex: selected,
              onSelect: (index) => _openDestination(destinations, index),
            ),
          );

    return BackButtonListener(
      onBackButtonPressed: () => _handleSystemBack(context),
      child: scaffold,
    );
  }

  int _selectedIndex(
    List<ShellDestination> destinations, {
    required bool isDesktop,
  }) {
    final branch = shellDestinations[navigationShell.currentIndex];
    var selected = destinations.indexWhere(
      (item) => item.location == branch.location,
    );
    if (selected < 0 &&
        !isDesktop &&
        (branch.location == '/invoices' || branch.location == '/payments')) {
      selected = destinations.indexWhere((item) => item.location == '/billing');
    }
    if (selected < 0) return 0;
    return selected;
  }

  ShellDestination _headerDestination(
    String location,
    ShellDestination selected,
  ) {
    for (final item in shellDestinations) {
      if (item.location == location) return item;
    }
    return selected;
  }

  String? _subtitle(String location) {
    if (location == '/home' && userName.isNotEmpty) {
      return i18n.t('home.greeting', {'name': userName});
    }
    if (location == '/profile') return i18n.t('profile.headerSubtitle');
    if (location == '/shipments') return i18n.t('shipment.headerSubtitle');
    if (location == '/jobs') return i18n.t('job.headerSubtitle');
    return null;
  }

  void _openDestination(List<ShellDestination> destinations, int index) {
    final branchIndex = shellDestinations.indexWhere(
      (item) => item.location == destinations[index].location,
    );
    if (branchIndex < 0) return;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  Future<bool> _handleSystemBack(BuildContext context) async {
    final router = GoRouter.of(context);
    if (router.canPop()) return false;
    final path = GoRouterState.of(context).uri.path;
    if (!isShellSectionRoot(path)) {
      router.go(sectionFallback(path));
      return true;
    }
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return true;
    }
    return false;
  }
}

/// The home header, kept above pages that open outside the shell.
class DesktopHeaderFrame extends StatelessWidget {
  const DesktopHeaderFrame({
    super.key,
    required this.child,
    required this.i18n,
    required this.userName,
    this.unreadCount = 0,
  });

  final Widget child;
  final I18nBundle i18n;
  final String userName;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < AppConstants.desktopBreakpoint) {
      return child;
    }

    final destinations = shellDestinations
        .where((item) => item.location != '/billing')
        .toList();
    final location = normalizeLocation(GoRouterState.of(context).uri.path);
    final section = sectionFallback(location);
    var selected = destinations.indexWhere(
      (item) => item.location == location || item.location == section,
    );
    if (selected < 0) selected = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: HeroBandHost(
        location: location,
        header: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 14,
            20,
            0,
          ),
          child: _TopBar(
            i18n: i18n,
            destinations: destinations,
            selectedIndex: selected,
            userName: userName,
            unreadCount: unreadCount,
            onSelect: (index) => context.go(destinations[index].location),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.i18n,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final I18nBundle i18n;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: _BottomNavItem(
                      destination: destinations[index],
                      label: destinations[index].label(i18n, compact: true),
                      selected: index == selectedIndex,
                      onTap: () => onSelect(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < 36) return const SizedBox.expand();
            return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 3,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navySoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        size: 22,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.i18n,
    required this.destinations,
    required this.selectedIndex,
    required this.userName,
    required this.unreadCount,
    required this.onSelect,
  });

  final I18nBundle i18n;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final String userName;
  final int unreadCount;
  final ValueChanged<int> onSelect;

  static const _ink = Color(0xFF1C2430);
  static const _orange = Color(0xFFF15A22);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241C2430),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xD4FFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _Wordmark(name: i18n.t('app.name')),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        _TopNavItem(
                          label: i18n.t(destinations[index].labelKey),
                          selected: index == selectedIndex,
                          onTap: () => onSelect(index),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LanguageControl(i18n: i18n),
                            _NotificationButton(
                              i18n: i18n,
                              unreadCount: unreadCount,
                            ),
                            const SizedBox(width: 4),
                            _UserChip(name: userName, role: i18n.t('app.customer')),
                          ],
                        ),
                      ),
                    ),
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

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final index = name.lastIndexOf('X');
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: _TopBar._ink,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );
    if (index < 0) return Text(name, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name.substring(0, index)),
          TextSpan(
            text: name.substring(index, index + 1),
            style: const TextStyle(color: _TopBar._orange),
          ),
          TextSpan(text: name.substring(index + 1)),
        ],
      ),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  const _TopNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _TopBar._orange : Colors.black;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: selected ? 28 : 0,
                decoration: BoxDecoration(
                  color: _TopBar._orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageControl extends ConsumerWidget {
  const _LanguageControl({required this.i18n});

  final I18nBundle i18n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arabic = i18n.locale.languageCode == 'ar';
    return TextButton.icon(
      onPressed: () {
        ref.read(i18nControllerProvider.notifier).setLocale(arabic ? 'en' : 'ar');
      },
      icon: const Icon(Icons.language, size: 18, color: Colors.black),
      label: Text(
        arabic ? 'العربية' : 'English',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'C' : name.trim().substring(0, 1).toUpperCase();
    return InkWell(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1F8A70),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.trim().isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _TopBar._ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.i18n, required this.unreadCount});

  final I18nBundle i18n;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: i18n.t('nav.notifications'),
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.notifications_outlined, color: Colors.black),
      ),
    );
  }
}
