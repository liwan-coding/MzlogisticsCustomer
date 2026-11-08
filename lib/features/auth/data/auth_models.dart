import 'dart:typed_data';

import '../../../shared/models/user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserAccount user;
}

class RegisterCustomerPayload {
  const RegisterCustomerPayload({
    required this.accountType,
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.companyName,
    this.idCard,
    this.idCardName,
    this.phone,
    this.locale = 'en',
  });

  final String accountType;
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? companyName;
  final Uint8List? idCard;
  final String? idCardName;
  final String? phone;
  final String locale;

  bool get isIndividual => accountType == 'individual';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'account_type': accountType,
      if (!isIndividual) 'company_name': companyName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'locale': locale,
    };
  }
}
