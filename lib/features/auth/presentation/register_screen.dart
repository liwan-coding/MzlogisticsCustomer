import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _maxBytes = 5 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _picker = ImagePicker();

  var _accountType = 'company';
  var _obscure = true;
  var _submitting = false;
  Uint8List? _idCard;
  String? _idCardName;
  String? _error;

  bool get _individual => _accountType == 'individual';

  bool get _canUseCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickIdCard(ImageSource source) async {
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
      setState(() => _error = i18n.t('auth.idCardInvalid'));
      return;
    }
    if (bytes.length > _maxBytes) {
      setState(() => _error = i18n.t('auth.idCardTooLarge'));
      return;
    }

    setState(() {
      _idCard = bytes;
      _idCardName = 'id-card.$extension';
      _error = null;
    });
  }

  String? _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    final i18n = ref.i18n;
    if (_individual && _idCard == null) {
      setState(() => _error = i18n.t('auth.idCardRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            RegisterCustomerPayload(
              accountType: _accountType,
              name: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              passwordConfirmation: _confirm.text,
              companyName: _individual ? null : _company.text.trim(),
              idCard: _individual ? _idCard : null,
              idCardName: _individual ? _idCardName : null,
              phone: _phone.text.trim(),
              locale: ref.read(i18nControllerProvider).value?.locale.languageCode ?? 'en',
            ),
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      if (error.message == 'network') {
        return ref.i18n.t('common.networkError');
      }
      return error.fieldError('email') ??
          error.fieldError('password') ??
          error.fieldError('company_name') ??
          error.fieldError('id_card') ??
          error.fieldError('account_type') ??
          error.message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    return AuthLayout(
      title: i18n.t('auth.registerTitle'),
      subtitle: i18n.t('auth.registerSubtitle'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(i18n.t('auth.accountType'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _typeChoice('company', i18n.t('auth.company'))),
                const SizedBox(width: 8),
                Expanded(child: _typeChoice('individual', i18n.t('auth.individual'))),
              ],
            ),
            const SizedBox(height: 14),
            if (!_individual) ...[
              AppTextField(
                label: i18n.t('auth.companyName'),
                controller: _company,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? i18n.t('auth.companyRequired') : null,
              ),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: i18n.t('auth.fullName'),
              controller: _name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? i18n.t('auth.nameRequired') : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: i18n.t('auth.email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return i18n.t('auth.emailRequired');
                if (!value.contains('@')) return i18n.t('auth.emailInvalid');
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: i18n.t('auth.phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            if (_individual) ...[
              const SizedBox(height: 14),
              _IdCardPicker(
                label: i18n.t('auth.idCard'),
                hint: i18n.t('auth.idCardHint'),
                filename: _idCardName,
                chooseLabel: i18n.t('auth.chooseIdPhoto'),
                cameraLabel: _canUseCamera ? i18n.t('auth.takeIdPhoto') : null,
                onChoose: () => _pickIdCard(ImageSource.gallery),
                onCamera: _canUseCamera ? () => _pickIdCard(ImageSource.camera) : null,
              ),
            ],
            const SizedBox(height: 14),
            AppTextField(
              label: i18n.t('auth.password'),
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
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
              controller: _confirm,
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
            const SizedBox(height: 18),
            AppButton(
              label: _submitting ? i18n.t('auth.creatingAccount') : i18n.t('auth.register'),
              loading: _submitting,
              expanded: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(i18n.t('auth.hasAccount'), style: const TextStyle(color: AppColors.muted)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(i18n.t('auth.login')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChoice(String value, String label) {
    final selected = _accountType == value;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? AppColors.amberSoft : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            _accountType = value;
            _error = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.orange : AppColors.ink,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdCardPicker extends StatelessWidget {
  const _IdCardPicker({
    required this.label,
    required this.hint,
    required this.chooseLabel,
    required this.onChoose,
    this.cameraLabel,
    this.onCamera,
    this.filename,
  });

  final String label;
  final String hint;
  final String chooseLabel;
  final String? cameraLabel;
  final VoidCallback onChoose;
  final VoidCallback? onCamera;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          filename ?? hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: filename == null ? AppColors.muted : AppColors.ink,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              label: chooseLabel,
              variant: AppButtonVariant.secondary,
              icon: Icons.photo_outlined,
              onPressed: onChoose,
            ),
            if (cameraLabel != null && onCamera != null)
              AppButton(
                label: cameraLabel!,
                variant: AppButtonVariant.ghost,
                icon: Icons.photo_camera_outlined,
                onPressed: onCamera,
              ),
          ],
        ),
      ],
    );
  }
}
