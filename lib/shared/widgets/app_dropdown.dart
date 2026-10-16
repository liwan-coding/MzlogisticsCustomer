import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T>? onChanged;
  final T? value;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  var _open = false;
  final _fieldKey = GlobalKey();
  double _menuWidth = 0;

  /// Width is read after layout. [AlertDialog] sizes its content with
  /// [IntrinsicWidth], and [LayoutBuilder] cannot answer that measurement.
  double? get _fieldWidth {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return null;
    return box.size.width;
  }

  void _scheduleMenuWidthSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = _fieldWidth;
      if (width == null || (width - _menuWidth).abs() < 0.5) return;
      setState(() => _menuWidth = width);
    });
  }

  void _toggle(MenuController controller) {
    final width = _fieldWidth;
    final widthChanged = width != null && (width - _menuWidth).abs() >= 0.5;
    if (widthChanged) setState(() => _menuWidth = width);
    if (controller.isOpen) {
      controller.close();
      return;
    }
    if (widthChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !controller.isOpen) controller.open();
      });
      return;
    }
    controller.open();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMenuWidthSync();
    final selected = _selected;
    final canOpen = widget.enabled && widget.onChanged != null && widget.options.isNotEmpty;
    final text = Theme.of(context).textTheme;
    final menuWidth = _menuWidth > 0 ? _menuWidth : null;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      consumeOutsideTap: true,
      onOpen: () {
        if (!_open) setState(() => _open = true);
      },
      onClose: () {
        if (_open) setState(() => _open = false);
      },
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(10),
        shadowColor: const WidgetStatePropertyAll(Color(0x1F1C2430)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6, horizontal: 6)),
        minimumSize: WidgetStatePropertyAll(Size(menuWidth ?? 0, 0)),
        maximumSize: WidgetStatePropertyAll(Size(menuWidth ?? double.infinity, 320)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      menuChildren: [
        for (final option in widget.options)
          _OptionButton(
            label: option.label,
            selected: option.value == widget.value,
            width: menuWidth ?? 0,
            onPressed: canOpen ? () => widget.onChanged!(option.value) : null,
          ),
      ],
      builder: (context, controller, _) {
        return InkWell(
          key: _fieldKey,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: canOpen ? () => _toggle(controller) : null,
          child: InputDecorator(
            isFocused: _open,
            isEmpty: selected == null,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: widget.errorText,
              enabled: canOpen,
              suffixIcon: Icon(
                _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: canOpen ? AppColors.ink : AppColors.muted,
              ),
            ),
            child: Text(
              selected?.label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  AppDropdownOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.width,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final double width;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (selected) return AppColors.navySoft;
          if (states.contains(WidgetState.hovered)) return AppColors.mist;
          return Colors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(Color(0x14F15A22)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        minimumSize: WidgetStatePropertyAll(Size(width > 12 ? width - 12 : 0, 44)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_rounded, size: 18, color: AppColors.orange),
          ],
        ],
      ),
    );
  }
}
