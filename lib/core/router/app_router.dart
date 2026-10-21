import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_list_screen.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/payments/data/checkout_args.dart';
import '../../features/payments/data/transfer_pending_args.dart';
import '../../features/payments/presentation/transfer_pending_screen.dart';
import '../../features/payments/presentation/billing_screen.dart';
import '../../features/payments/presentation/payment_checkout_screen.dart';
import '../../features/payments/presentation/payment_result_screens.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/shipments/presentation/create_shipment_screen.dart';
import '../../features/shipments/presentation/shipment_detail_screen.dart';
import '../../features/shipments/presentation/shipments_list_screen.dart';
import '../../features/trips/presentation/pod_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../constants/app_constants.dart';
import '../i18n/i18n_controller.dart';
import 'page_transitions.dart';

class RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh();
  ref.listen(authControllerProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);
  return refresh;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      const authRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};
      if (auth.status == AuthStatus.unknown) {
        if (location.startsWith('/payment')) return null;
        return location == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return authRoutes.contains(location) ? null : '/login';
      }
      if (authRoutes.contains(location) || location == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: customerRoutes(rootNavigatorKey: rootNavigatorKey),
  );
});

List<RouteBase> customerRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  Page<void> section(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  Page<void> forward(GoRouterState state, Widget child) {
    return forwardPage(key: state.pageKey, child: child);
  }

  int routeId(GoRouterState state, [String name = 'id']) {
    return int.parse(state.pathParameters[name]!);
  }

  return [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  section(state, const HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shipments',
              pageBuilder: (context, state) =>
                  section(state, const ShipmentsListScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => forward(
                    state,
                    _WithHeader(
                      child: CreateShipmentScreen(
                        initialTruckType: state.uri.queryParameters['truck'],
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) => forward(
                    state,
                    ShipmentDetailScreen(shipmentId: routeId(state)),
                  ),
                  routes: [
                    GoRoute(
                      path: 'quotations',
                      pageBuilder: (context, state) => forward(
                        state,
                        QuotationsScreen(shipmentId: routeId(state)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/quotations/:id',
              pageBuilder: (context, state) => forward(
                state,
                QuotationDetailScreen(quotationId: routeId(state)),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/jobs',
              pageBuilder: (context, state) =>
                  section(state, const JobsListScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) =>
                      forward(state, JobDetailScreen(jobId: routeId(state))),
                ),
              ],
            ),
            GoRoute(
              path: '/trips/:id',
              pageBuilder: (context, state) =>
                  forward(state, TripDetailScreen(tripId: routeId(state))),
              routes: [
                GoRoute(
                  path: 'tracking',
                  redirect: (context, state) {
                    if (!AppConstants.liveTrackingEnabled) {
                      return '/trips/${state.pathParameters['id']}';
                    }
                    return null;
                  },
                  pageBuilder: (context, state) => forward(
                    state,
                    TripTrackingScreen(tripId: routeId(state)),
                  ),
                ),
                GoRoute(
                  path: 'pod',
                  pageBuilder: (context, state) =>
                      forward(state, PodScreen(tripId: routeId(state))),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/invoices',
              pageBuilder: (context, state) =>
                  section(state, const InvoicesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/payments',
              pageBuilder: (context, state) =>
                  section(state, const PaymentsScreen()),
              routes: [
                GoRoute(
                  path: 'transfer',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => forward(
                    state,
                    _WithHeader(
                      child: TransferPendingScreen(
                        args: TransferPendingArgs.fromExtra(state.extra),
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'checkout/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final args = CheckoutArgs.fromExtra(state.extra);
                    return forward(
                      state,
                      _WithHeader(
                        child: PaymentCheckoutScreen(
                          paymentId: routeId(state),
                          paymentLink: args.paymentLink,
                          jobId: args.jobId,
                          invoicePayment: args.invoicePayment,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/billing',
              pageBuilder: (context, state) =>
                  section(state, const BillingScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  section(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          forward(state, const _WithHeader(child: NotificationsScreen())),
    ),
    GoRoute(
      path: '/payment/success',
      pageBuilder: (context, state) => forward(
        state,
        _WithHeader(
          child: PaymentSuccessScreen(
            paymentId: int.tryParse(
              state.uri.queryParameters['payment_id'] ?? '',
            ),
            jobId: int.tryParse(state.uri.queryParameters['job_id'] ?? ''),
            success: state.uri.queryParameters['success'] != '0',
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/payment/cancel',
      pageBuilder: (context, state) => forward(
        state,
        _WithHeader(
          child: PaymentCancelScreen(
            paymentId: int.tryParse(
              state.uri.queryParameters['payment_id'] ?? '',
            ),
            jobId: int.tryParse(state.uri.queryParameters['job_id'] ?? ''),
            invoicePayment: state.uri.queryParameters['invoice'] == '1',
          ),
        ),
      ),
    ),
  ];
}

class _WithHeader extends ConsumerWidget {
  const _WithHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(notificationsProvider)
        .maybeWhen(
          data: (page) => page.items.where((item) => item.isUnread).length,
          orElse: () => 0,
        );
    return DesktopHeaderFrame(
      i18n: ref.i18n,
      userName: ref.watch(authControllerProvider).user?.name ?? '',
      unreadCount: unread,
      child: child,
    );
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final user = ref.watch(authControllerProvider).user;
    final unread = ref
        .watch(notificationsProvider)
        .maybeWhen(
          data: (page) => page.items.where((item) => item.isUnread).length,
          orElse: () => 0,
        );
    return ResponsiveScaffold(
      navigationShell: navigationShell,
      i18n: i18n,
      userName: user?.name ?? '',
      unreadCount: unread,
    );
  }
}
