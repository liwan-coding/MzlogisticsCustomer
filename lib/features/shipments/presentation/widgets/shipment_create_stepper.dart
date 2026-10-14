import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ShipmentCreateStep {
  const ShipmentCreateStep({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Visual route for the shipment request wizard.
///
/// [current] is the active stage index. Pass `steps.length` when every stage
/// is already complete so the track fills and each node shows a check.
class ShipmentCreateStepper extends StatefulWidget {
  const ShipmentCreateStepper({
    super.key,
    required this.steps,
    required this.current,
    this.progressLabel,
    this.onSelect,
    this.canSelect,
  });

  final List<ShipmentCreateStep> steps;
  final int current;
  final String? progressLabel;
  final ValueChanged<int>? onSelect;
  final bool Function(int index)? canSelect;

  @override
  State<ShipmentCreateStepper> createState() => _ShipmentCreateStepperState();
}

class _ShipmentCreateStepperState extends State<ShipmentCreateStepper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    if (_enter.value == 0 && !_enter.isAnimating) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motion = reduced ? Duration.zero : const Duration(milliseconds: 480);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = steps.length;
          final slot = constraints.maxWidth / count;
          final span = constraints.maxWidth - slot;
          final last = count - 1;
          final clamped = widget.current.clamp(0, count);
          final fraction = last == 0 ? 1.0 : (clamped / last).clamp(0.0, 1.0);

          return Semantics(
            container: true,
            label: widget.progressLabel,
            explicitChildNodes: true,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: slot / 2,
                  width: span,
                  top: 22.5,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: slot / 2,
                  top: 22.5,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: span * fraction),
                    duration: motion,
                    curve: Curves.easeInOutCubic,
                    builder: (context, width, _) {
                      return Container(
                        width: width,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < count; index++)
                      Expanded(
                        child: _EnterMotion(
                          animation: _enter,
                          index: index,
                          child: _StageNode(
                            step: steps[index],
                            done: index < widget.current,
                            current: index == widget.current,
                            enabled:
                                widget.onSelect != null &&
                                (widget.canSelect?.call(index) ?? true),
                            onTap: widget.onSelect == null
                                ? null
                                : () => widget.onSelect!(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnterMotion extends StatelessWidget {
  const _EnterMotion({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.12).clamp(0.0, 0.4);
    final end = (begin + 0.6).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ShipmentStageHeading extends StatelessWidget {
  const ShipmentStageHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.navySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _StageNode extends StatefulWidget {
  const _StageNode({
    required this.step,
    required this.done,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  final ShipmentCreateStep step;
  final bool done;
  final bool current;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      value: widget.current ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _StageNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current || !widget.current) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pop.value = 1;
      return;
    }
    _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motion = reduced ? Duration.zero : const Duration(milliseconds: 320);
    final icon = widget.done ? Icons.check_rounded : widget.step.icon;
    final iconColor = widget.current
        ? AppColors.white
        : widget.done
        ? AppColors.white
        : AppColors.muted;
    final labelColor = widget.current
        ? AppColors.navy
        : widget.done
        ? AppColors.ink
        : AppColors.muted;
    final scale = widget.current
        ? Tween<double>(begin: 0.72, end: 1).animate(
            CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
          )
        : const AlwaysStoppedAnimation<double>(1);
    final ring = CurvedAnimation(parent: _pop, curve: Curves.easeOut);

    return Semantics(
      button: widget.enabled,
      selected: widget.current,
      enabled: widget.enabled,
      label: widget.step.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          customBorder: const CircleBorder(),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _pop,
                      builder: (context, child) {
                        final ringScale = 1 + (ring.value * 0.7);
                        final ringOpacity = widget.current ? (1 - ring.value) * 0.45 : 0.0;
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Transform.scale(
                              scale: ringScale,
                              child: Opacity(
                                opacity: ringOpacity,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.navy,
                                  ),
                                  child: SizedBox.square(dimension: 40),
                                ),
                              ),
                            ),
                            Transform.scale(scale: scale.value, child: child),
                          ],
                        );
                      },
                      child: AnimatedContainer(
                        duration: motion,
                        curve: Curves.easeOutCubic,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.current
                              ? AppColors.orange
                              : widget.done
                              ? AppColors.success
                              : AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.current
                                ? AppColors.navy
                                : widget.done
                                ? AppColors.success
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: motion,
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            );
                          },
                          child: Icon(
                            icon,
                            key: ValueKey(
                              widget.done
                                  ? 'done'
                                  : widget.current
                                  ? 'current'
                                  : 'idle-${widget.step.label}',
                            ),
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: motion,
                    curve: Curves.easeOutCubic,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: widget.current || widget.done
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: labelColor,
                      height: 1.25,
                    ),
                    child: Text(widget.step.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
