import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/push/push_notifications.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.token,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final UserAccount? user;
  final String? token;

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen<int>(unauthorizedTickProvider, (previous, next) {
      if (next > (previous ?? 0) && state.isAuthenticated) {
        state = const AuthState.unauthenticated();
      }
    });
    Future<void>.microtask(bootstrap);
    return const AuthState.unknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  Future<void> bootstrap() async {
    try {
      await _restoreSession().timeout(AppConstants.bootstrapTimeout);
    } catch (_) {
      if (state.status == AuthStatus.unknown) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> _restoreSession() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (_) {
      await _tokens.clear();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _repo.login(email, password);
    await _tokens.write(session.token);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: session.token,
      user: session.user,
    );
  }

  Future<void> register(RegisterCustomerPayload payload) async {
    final session = await _repo.register(payload);
    await _tokens.write(session.token);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: session.token,
      user: session.user,
    );
  }

  Future<void> logout() async {
    await PushNotifications.unregister();
    try {
      await _repo.logout();
    } catch (_) {
      // Always clear the local session.
    }
    await _tokens.clear();
    state = const AuthState.unauthenticated();
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    final user = await _repo.me();
    state = AuthState(
      status: AuthStatus.authenticated,
      token: state.token,
      user: user,
    );
  }

  Future<void> updateProfile({String? name, String? phone, String? locale}) async {
    final user = await _repo.updateMe(name: name, phone: phone, locale: locale);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: state.token,
      user: user,
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _repo.updatePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  void onUnauthorized() {
    if (state.isAuthenticated) {
      state = const AuthState.unauthenticated();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
