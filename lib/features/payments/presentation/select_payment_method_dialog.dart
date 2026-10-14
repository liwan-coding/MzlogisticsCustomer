import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../data/payment_method_model.dart';
import 'payment_providers.dart';

Future<String?> showSelectPaymentMethodDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String titleKey,
  required String confirmHintKey,
}) async {
  final i18n = ref.i18n;
  final methods = await ref.read(activePaymentMethodsProvider.future);
  if (!context.mounted) return null;
  if (methods.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(i18n.t('quotation.noPaymentMethods'))),
    );
    return null;
  }

  var selected = methods.first.code;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(i18n.t(titleKey)),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i18n.t(confirmHintKey), style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: i18n.t('quotation.paymentMethod'),
                  value: selected,
                  options: [
                    for (final method in methods)
                      AppDropdownOption(
                        value: method.code,
                        label: _methodLabel(i18n, method),
                      ),
                  ],
                  onChanged: (value) => setLocal(() => selected = value),
                ),
              ],
            );
          },
        ),
        actions: [
          AppButton(
            label: i18n.t('common.cancel'),
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: i18n.t('common.confirm'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return null;
  return selected;
}

String _methodLabel(I18nBundle i18n, PaymentMethod method) {
  return method.displayName(i18n.locale.languageCode);
}
