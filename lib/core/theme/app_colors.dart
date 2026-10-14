import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFF15A22);
  static const Color ink = Color(0xFF1C2430);
  static const Color bar = Color(0xFF101A2B);
  static const Color surface = Color(0xFFF7F8FB);
  static const Color border = Color(0xFFE7E9EF);
  static const Color muted = Color(0xFF6B7280);
  static const Color mist = Color(0xFFF3F5F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color onBar = Color(0xFFC5CDD8);

  /// Existing call sites used these names for the brand. They now follow the home orange.
  static const Color navy = orange;
  static const Color navyDeep = bar;
  static const Color headerFrom = bar;
  static const Color accentFrom = orange;
  static const Color accentTo = orange;
  static const Color amber = orange;
  static const Color onAccent = white;
  static const Color onNeon = ink;
  static const Color amberSoft = Color(0xFFFFF1EA);
  static const Color navySoft = Color(0xFFFFF1EA);
  static const Color navyMuted = Color(0xFF9AA3AF);

  static const Color info = Color(0xFF3B6FD8);
  static const Color infoSoft = Color(0xFFEEF3FF);
  static const Color success = Color(0xFF1F9D62);
  static const Color danger = Color(0xFFA33B32);
  static const Color successSoft = Color(0xFFE8F7EF);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color progress = Color(0xFFC2410C);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [orange, orange],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orange],
  );

  static Color statusBackground(String status) {
    switch (status) {
      case 'published':
      case 'assigned':
      case 'issued':
        return infoSoft;
      case 'awarded':
      case 'accepted':
      case 'completed':
      case 'delivered':
      case 'paid':
      case 'active':
        return successSoft;
      case 'submitted':
      case 'in_progress':
      case 'in_transit':
      case 'processing':
      case 'loaded':
      case 'arrived':
      case 'arrived_at_pickup':
      case 'pending_dispatch':
        return amberSoft;
      case 'cancelled':
      case 'expired':
      case 'rejected':
      case 'failed':
      case 'void':
      case 'suspended':
      case 'inactive':
        return dangerSoft;
      default:
        return mist;
    }
  }

  static Color statusForeground(String status) {
    switch (status) {
      case 'published':
      case 'assigned':
      case 'issued':
        return info;
      case 'awarded':
      case 'accepted':
      case 'completed':
      case 'delivered':
      case 'paid':
      case 'active':
        return success;
      case 'submitted':
      case 'in_progress':
      case 'in_transit':
      case 'processing':
      case 'loaded':
      case 'arrived':
      case 'arrived_at_pickup':
      case 'pending_dispatch':
        return progress;
      case 'cancelled':
      case 'expired':
      case 'rejected':
      case 'failed':
      case 'void':
      case 'suspended':
      case 'inactive':
        return danger;
      default:
        return muted;
    }
  }
}
