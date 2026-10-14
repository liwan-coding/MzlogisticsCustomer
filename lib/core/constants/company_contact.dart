import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Temporary public contact details until the real phone and Instagram are confirmed.
class CompanyContact {
  const CompanyContact._();

  static const phoneDisplay = '+968 9123 4567';
  static const phoneTel = '+96891234567';
  static const whatsapp = '96891234567';
  static const instagram = 'movex.om';

  static Uri get phoneUri => Uri(scheme: 'tel', path: phoneTel);

  static Uri get whatsappUri => Uri.parse('https://wa.me/$whatsapp');

  static Uri get instagramUri => Uri.parse('https://instagram.com/$instagram');

  static String get instagramHandle => '@$instagram';

  static Future<void> open(Uri uri) async {
    try {
      await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
