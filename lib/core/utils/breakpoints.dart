import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

extension Breakpoints on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isDesktop => screenWidth >= AppConstants.desktopBreakpoint;

  bool get isWide => screenWidth >= AppConstants.wideBreakpoint;

  bool get isTablet =>
      screenWidth >= AppConstants.tabletBreakpoint &&
      screenWidth < AppConstants.desktopBreakpoint;

  bool get isMobile => screenWidth < AppConstants.tabletBreakpoint;

  double get contentMaxWidth => 1180;

  /// Gutters sit outside the content column, matching the home sections.
  EdgeInsets get contentPadding {
    if (isDesktop) return const EdgeInsets.fromLTRB(40, 16, 40, 32);
    return const EdgeInsets.fromLTRB(16, 12, 16, 28);
  }
}
