import '../../../core/utils/json_utils.dart';

class TruckTypeOption {
  const TruckTypeOption({
    required this.code,
    required this.name,
    this.nameAr,
    this.imageUrl,
    this.isActive = true,
  });

  final String code;
  final String name;
  final String? nameAr;
  final String? imageUrl;
  final bool isActive;

  String displayName(String locale) {
    if (locale == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  factory TruckTypeOption.fromJson(Map<String, dynamic> json) {
    return TruckTypeOption(
      code: asString(json['code']) ?? '',
      name: asString(json['name']) ?? asString(json['label']) ?? '',
      nameAr: asString(json['name_ar']),
      imageUrl: asString(json['image_url']) ?? asString(json['image']),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
