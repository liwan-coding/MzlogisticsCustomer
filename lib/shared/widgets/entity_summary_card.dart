import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_glyph.dart';

class EntityFact {
  const EntityFact(this.label, this.value, {this.icon});

  final String label;
  final String value;
  final IconData? icon;
}

class EntitySummaryCard extends StatelessWidget {
  const EntitySummaryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inventory_2_rounded,
    this.tone = AppGlyphTone.navy,
    this.accent,
    this.badge,
    this.facts = const [],
    this.footer,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final AppGlyphTone tone;
  final Color? accent;
  final Widget? badge;
  final List<EntityFact> facts;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null)
            ColoredBox(
              color: accent!,
              child: const SizedBox(height: 3),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppGlyph(icon: icon, size: 48, iconSize: 24, tone: tone),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      for (final fact in facts)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fact.icon != null) ...[
                                Icon(fact.icon, size: 16, color: AppColors.navy),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fact.label,
                                      style: text.labelSmall?.copyWith(color: AppColors.muted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fact.value,
                                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
