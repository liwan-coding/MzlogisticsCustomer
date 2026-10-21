class AppConstants {
  AppConstants._();

  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static const String _storageBaseUrlFromEnv = String.fromEnvironment('STORAGE_BASE_URL');

  /// Local MoveX API. Override with `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrlDefault = 'http://192.168.100.94:8000/api/v1';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
    return apiBaseUrlDefault;
  }

  static String get apiOrigin => Uri.parse(apiBaseUrl).origin;

  static const String appScheme = 'mzlogistics';

  static String get storageBaseUrl {
    if (_storageBaseUrlFromEnv.isNotEmpty) return _storageBaseUrlFromEnv;
    return '$apiOrigin/storage';
  }

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration bootstrapTimeout = Duration(seconds: 8);

  static const String tokenKey = 'mz_customer_token';
  static const String localeKey = 'mz_customer_locale';

  static const String demoEmail = 'customer@gulfmaterials.om';
  static const String demoPassword = 'Password123!';

  static const double mapDefaultLat = 23.5880;
  static const double mapDefaultLng = 58.3829;
  static const double mapCountryZoom = 7;
  static const double mapPlaceZoom = 15;

  static const double desktopBreakpoint = 1024;
  static const double tabletBreakpoint = 768;
  static const double compactBreakpoint = 400;
  static const double wideBreakpoint = 1440;

  static const List<String> supportedLocales = ['en', 'ar'];

  /// Temporarily hidden until live tracking is ready to ship.
  static const bool liveTrackingEnabled = false;
}
