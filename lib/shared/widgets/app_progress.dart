import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_glyph.dart';

class AppStepItem {
  const AppStepItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class AppTimelineEvent {
  const AppTimelineEvent({
    required this.label,
    required this.value,
    required this.icon,
    this.done = false,
    this.current = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool done;
  final bool current;
}

class AppStatusStepper extends StatelessWidget {
  const AppStatusStepper({
    super.key,
    required this.steps,
    required this.currentId,
    this.failed = false,
  });

  final List<AppStepItem> steps;
  final String currentId;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((step) => step.id == currentId);
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: index <= activeIndex && !failed
                      ? AppColors.success
                      : index <= activeIndex && failed
                          ? AppColors.danger
                          : AppColors.border,
                ),
              ),
            ),
          _StepGlyph(
            step: steps[index],
            done: !failed && index < activeIndex,
            current: index == activeIndex,
            failed: failed && index == activeIndex,
          ),
        ],
      ],
    );
  }
}

class _StepGlyph extends StatelessWidget {
  const _StepGlyph({
    required this.step,
    required this.done,
    required this.current,
    required this.failed,
  });

  final AppStepItem step;
  final bool done;
  final bool current;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final tone = failed
        ? AppGlyphTone.danger
        : done
            ? AppGlyphTone.neon
            : current
                ? AppGlyphTone.inverse
                : AppGlyphTone.muted;
    final icon = failed
        ? Icons.close_rounded
        : done
            ? Icons.check_rounded
            : step.icon;

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          AppGlyph(icon: icon, size: 40, iconSize: 20, tone: tone),
          const SizedBox(height: 8),
          Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: current || done ? FontWeight.w700 : FontWeight.w500,
                  color: failed
                      ? AppColors.danger
                      : current
                          ? AppColors.navy
                          : AppColors.muted,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class AppTimeline extends StatelessWidget {
  const AppTimeline({super.key, required this.events});

  final List<AppTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _TimelineRow(
            event: events[index],
            isLast: index == events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final AppTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = event.current
        ? AppGlyphTone.inverse
        : event.done
            ? AppGlyphTone.neon
            : AppGlyphTone.muted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AppGlyph(icon: event.icon, size: 36, iconSize: 18, tone: tone),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: event.done ? AppColors.success : AppColors.border,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      event.label,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: event.current || event.done ? FontWeight.w700 : FontWeight.w500,
                        color: event.done || event.current ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.value,
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: event.done || event.current ? AppColors.navy : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppMetricChip extends StatelessWidget {
  const AppMetricChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGlyph(icon: icon, size: 36, iconSize: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelSmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
