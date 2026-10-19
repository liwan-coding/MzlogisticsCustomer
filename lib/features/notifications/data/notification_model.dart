import '../../../core/utils/json_utils.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    this.type,
    this.title,
    this.body,
    this.titleAr,
    this.titleEn,
    this.bodyAr,
    this.bodyEn,
    this.targetType,
    this.targetId,
    this.readAt,
    this.createdAt,
    this.data = const {},
  });

  final String id;
  final String? type;
  final String? title;
  final String? body;
  final String? titleAr;
  final String? titleEn;
  final String? bodyAr;
  final String? bodyEn;
  final String? targetType;
  final String? targetId;
  final DateTime? readAt;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  bool get isUnread => readAt == null;

  String textTitle(String languageCode) {
    if (languageCode == 'en') {
      return titleEn ?? title ?? '';
    }
    return titleAr ?? title ?? '';
  }

  String textBody(String languageCode) {
    if (languageCode == 'en') {
      return bodyEn ?? body ?? '';
    }
    return bodyAr ?? body ?? '';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final payload = asMap(json['data']);
    return AppNotification(
      id: asString(json['id']) ?? '',
      type: asString(json['type']),
      title: asString(payload['title'] ?? json['title']),
      body: asString(payload['body'] ?? payload['message'] ?? json['body']),
      titleAr: asString(payload['title_ar']),
      titleEn: asString(payload['title_en']),
      bodyAr: asString(payload['body_ar']),
      bodyEn: asString(payload['body_en']),
      targetType: asString(payload['target_type']),
      targetId: asString(payload['target_id']),
      readAt: asDateTime(json['read_at']),
      createdAt: asDateTime(json['created_at']),
      data: payload,
    );
  }
}
