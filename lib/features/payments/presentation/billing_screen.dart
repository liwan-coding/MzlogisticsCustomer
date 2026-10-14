import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/widgets/page_scroll.dart';
import '../../invoices/presentation/invoices_screen.dart';
import 'payments_screen.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.i18n;
    final tabs = Padding(
      padding: EdgeInsets.fromLTRB(context.isDesktop ? 40 : 16, 12, context.isDesktop ? 40 : 16, 8),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
          child: Material(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(text: i18n.t('invoice.title')),
                Tab(text: i18n.t('payment.title')),
              ],
            ),
          ),
        ),
      ),
    );

    return DefaultTabController(
      length: 2,
      child: PageScrollView(
        child: Builder(
          builder: (context) {
            if (PageScrollMark.maybeOf(context) == null) {
              return Column(
                children: [
                  tabs,
                  const Expanded(
                    child: TabBarView(
                      children: [
                        InvoicesScreen(),
                        PaymentsScreen(),
                      ],
                    ),
                  ),
                ],
              );
            }

            final controller = DefaultTabController.of(context);
            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tabs,
                    controller.index == 0 ? const InvoicesScreen() : const PaymentsScreen(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
