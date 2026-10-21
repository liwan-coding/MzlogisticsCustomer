import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/user.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> login(String email, String password) async {
    final envelope = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _session(envelope.map);
  }

  Future<AuthSession> register(RegisterCustomerPayload payload) async {
    final envelope = await _api.post(
      '/auth/register/customer',
      data: payload.toJson(),
    );
    return _session(envelope.map);
  }

  Future<UserAccount> me() async {
    final envelope = await _api.get('/auth/me');
    return UserAccount.fromJson(envelope.map);
  }

  Future<UserAccount> updateMe({
    String? name,
    String? phone,
    String? locale,
  }) async {
    final envelope = await _api.patch('/auth/me', data: {
      'name': ?name,
      'phone': ?phone,
      'locale': ?locale,
    });
    return UserAccount.fromJson(envelope.map);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _api.patch('/auth/password', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout() => _api.post('/auth/logout');

  Future<void> forgotPassword(String email) {
    return _api.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) {
    return _api.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  AuthSession _session(Map<String, dynamic> json) {
    return AuthSession(
      token: asString(json['token']) ?? '',
      user: UserAccount.fromJson(asMap(json['user'])),
    );
  }
}
