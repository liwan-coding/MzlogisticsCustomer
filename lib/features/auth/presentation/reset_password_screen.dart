import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'auth_layout.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  bool _obscure = true;
  bool _updated = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String get _address => _email.text.trim();

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _address,
            code: _code.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirmation.text,
          );
      if (!mounted) return;
      setState(() => _updated = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _address.isEmpty) return;
    setState(() {
      _resending = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_address);
      if (!mounted) return;
      setState(() => _notice = ref.i18n.t('auth.codeResent'));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _message(Object error) {
    final i18n = ref.i18n;
    if (error is ApiException && error.message == 'network') {
      return i18n.t('common.networkError');
    }
    if (error is ApiException && error.statusCode == 429) {
      return i18n.t('auth.tooManyAttempts');
    }
    if (error is ApiException) {
      return error.fieldError('code') ?? error.fieldError('password') ?? error.message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    return AuthLayout(
      title: i18n.t('auth.resetTitle'),
      subtitle: _address.isEmpty
          ? i18n.t('auth.forgotSubtitle')
          : i18n.t('auth.resetSubtitle', {'email': _address}),
      child: _updated ? _success(i18n) : _form(i18n),
    );
  }

  Widget _success(I18nBundle i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(i18n.t('auth.passwordUpdated'), style: const TextStyle(color: AppColors.success)),
        const SizedBox(height: 18),
        AppButton(
          label: i18n.t('auth.login'),
          expanded: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _form(I18nBundle i18n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.email.trim().isEmpty) ...[
            AppTextField(
              label: i18n.t('auth.email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return i18n.t('auth.emailRequired');
                if (!value.contains('@')) return i18n.t('auth.emailInvalid');
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],
          AppTextField(
            label: i18n.t('auth.code'),
            controller: _code,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if ((value ?? '').trim().length != 6) return i18n.t('auth.codeInvalid');
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: i18n.t('auth.password'),
            controller: _password,
            obscureText: _obscure,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return i18n.t('auth.passwordRequired');
              if (value.length < 8) return i18n.t('auth.passwordShort');
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: i18n.t('auth.passwordConfirm'),
            controller: _confirmation,
            obscureText: _obscure,
            validator: (value) {
              if (value != _password.text) return i18n.t('auth.passwordMismatch');
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(_notice!, style: const TextStyle(color: AppColors.success)),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: _submitting ? i18n.t('auth.savingPassword') : i18n.t('auth.savePassword'),
            loading: _submitting,
            expanded: true,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: _resending ? i18n.t('auth.sending') : i18n.t('auth.resendCode'),
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: _resending ? null : _resend,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: i18n.t('auth.useDifferentEmail'),
            variant: AppButtonVariant.ghost,
            onPressed: () => context.canPop() ? context.pop() : context.go('/forgot-password'),
          ),
        ],
      ),
    );
  }
}
