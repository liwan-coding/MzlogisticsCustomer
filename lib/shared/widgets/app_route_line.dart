import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bidi_text.dart';

class AppRouteLine extends StatelessWidget {
  const AppRouteLine({
    super.key,
    required this.from,
    required this.to,
    this.fromLabel,
    this.toLabel,
    this.compact = false,
  });

  final String from;
  final String to;
  final String? fromLabel;
  final String? toLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final style = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            height: 1.3,
          );
      return Row(
        children: [
          Flexible(
            child: _RouteName(
              value: from,
              style: style,
              textAlign: TextAlign.start,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: _RouteArrow(size: 12, color: AppColors.navyMuted),
          ),
          Flexible(
            child: _RouteName(
              value: to,
              style: style,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      );
    }

    return _StackedRoute(
      from: from,
      to: to,
      fromLabel: fromLabel,
      toLabel: toLabel,
    );
  }
}

class AppRoutePanel extends StatelessWidget {
  const AppRoutePanel({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.from,
    required this.to,
  });

  final String fromLabel;
  final String toLabel;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RouteEnd(
              icon: Icons.trip_origin_rounded,
              iconColor: AppColors.navy,
              caption: fromLabel,
              value: from,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                SizedBox(height: 14),
                _RouteArrow(size: 18, color: AppColors.navy),
              ],
            ),
          ),
          Expanded(
            child: _RouteEnd(
              icon: Icons.flag_rounded,
              iconColor: AppColors.orange,
              caption: toLabel,
              value: to,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteArrow extends StatelessWidget {
  const _RouteArrow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // arrow_forward mirrors once with Directionality. Do not swap to
    // arrow_back in RTL — that would reverse the route twice.
    return Icon(Icons.arrow_forward_rounded, size: size, color: color);
  }
}

class _StackedRoute extends StatelessWidget {
  const _StackedRoute({
    required this.from,
    required this.to,
    this.fromLabel,
    this.toLabel,
  });

  final String from;
  final String to;
  final String? fromLabel;
  final String? toLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteStop(
          pickup: true,
          label: fromLabel,
          value: from,
        ),
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 3),
          child: SizedBox(
            width: 2,
            height: 10,
            child: ColoredBox(color: AppColors.border),
          ),
        ),
        _RouteStop(
          pickup: false,
          label: toLabel,
          value: to,
        ),
      ],
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.pickup,
    required this.value,
    this.label,
  });

  final bool pickup;
  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: label == null ? 4 : 5),
          child: _RouteDot(pickup: pickup),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null && label!.isNotEmpty) ...[
                Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              _RouteName(
                value: value,
                maxLines: 2,
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.pickup});

  final bool pickup;

  @override
  Widget build(BuildContext context) {
    if (pickup) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.accentFrom,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.2),
      ),
    );
  }
}

class _RouteName extends StatelessWidget {
  const _RouteName({
    required this.value,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  final String value;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      bidiIsolate(value),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}

class _RouteEnd extends StatelessWidget {
  const _RouteEnd({
    required this.icon,
    required this.iconColor,
    required this.caption,
    required this.value,
    this.alignEnd = false,
  });

  final IconData icon;
  final Color iconColor;
  final String caption;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!alignEnd) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: text.labelSmall?.copyWith(color: AppColors.muted),
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: _RouteName(
            value: value,
            textAlign: textAlign,
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

