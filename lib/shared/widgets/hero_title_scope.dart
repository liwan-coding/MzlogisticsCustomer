import 'package:flutter/material.dart';

class HeroTitleData {
  const HeroTitleData({
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool? showBack;
  final VoidCallback? onBack;

  bool sameAs(HeroTitleData other) {
    return title == other.title && subtitle == other.subtitle && showBack == other.showBack;
  }
}

class HeroTitleController extends ChangeNotifier {
  HeroTitleData? registered;

  void publish(HeroTitleData data) {
    final current = registered;
    if (current != null && current.sameAs(data)) return;
    registered = data;
    notifyListeners();
  }

  void reset() {
    if (registered == null) return;
    registered = null;
    notifyListeners();
  }
}

class HeroTitleScope extends InheritedWidget {
  const HeroTitleScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final HeroTitleController controller;

  static HeroTitleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HeroTitleScope>();
  }

  @override
  bool updateShouldNotify(HeroTitleScope oldWidget) => controller != oldWidget.controller;
}
