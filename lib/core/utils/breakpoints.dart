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

  /// Phones narrower than a typical modern handset, including small Androids.
  bool get isCompact => screenWidth < AppConstants.compactBreakpoint;

  double get contentMaxWidth => 1180;

  /// Vertical rhythm between stacked cards on operational screens.
  double get stackGap => isCompact ? 14 : (isMobile ? 16 : 22);

  /// Gutters sit outside the content column, matching the home sections.
  EdgeInsets get contentPadding {
    if (isDesktop) return const EdgeInsets.fromLTRB(40, 16, 40, 32);
    if (!isMobile) return const EdgeInsets.fromLTRB(24, 14, 24, 28);
    if (isCompact) return const EdgeInsets.fromLTRB(14, 8, 14, 20);
    return const EdgeInsets.fromLTRB(16, 10, 16, 24);
  }
}
