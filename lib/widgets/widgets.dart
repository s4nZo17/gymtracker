// lib/widgets/widgets.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';

// â”€â”€â”€ SECTION TITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11, letterSpacing: 2, color: kText3, fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// â”€â”€â”€ SERIES BADGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class SeriesBadge extends StatelessWidget {
  final SeriesType type;
  const SeriesBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    if (type == SeriesType.normal) return const SizedBox();
    final isHelp = type == SeriesType.help;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHelp ? kOrange.withValues(alpha: 0.12) : kBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isHelp ? '* aiuto' : 'drop',
        style: TextStyle(
          fontSize: 10,
          color: isHelp ? kOrange : kBlue,
        ),
      ),
    );
  }
}

// â”€â”€â”€ DROPS DISPLAY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class DropsDisplay extends StatelessWidget {
  final List<DropEntry> drops;
  const DropsDisplay(this.drops, {super.key});

  @override
  Widget build(BuildContext context) {
    if (drops.isEmpty) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: drops.map((d) => Text(
        ' -> ${d.weight}x${d.reps}',
        style: TextStyle(fontSize: 11, color: kBlue),
      )).toList(),
    );
  }
}

// â”€â”€â”€ SERIES NUMBER BADGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class SeriesNumBadge extends StatelessWidget {
  final int num;
  const SeriesNumBadge(this.num, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$num',
          style: TextStyle(fontSize: 11, color: kText2, fontWeight: FontWeight.w600),
        ),
      );
}

// â”€â”€â”€ LAST SESSION CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class LastSessionCard extends StatelessWidget {
  final String date;
  final List<Series> series;
  final VoidCallback? onUseSeries;
  final int currentSeriesIndex;

  const LastSessionCard({
    super.key,
    required this.date,
    required this.series,
    this.onUseSeries,
    this.currentSeriesIndex = 0,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kAccent.withValues(alpha: 0.05),
          border: Border.all(color: kAccent.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: kAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ULTIMA VOLTA - $date',
                  style: TextStyle(fontSize: 10, color: kAccent, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: series.asMap().entries.map((e) {
                final isHighlighted = e.key == currentSeriesIndex;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighlighted ? kAccent.withValues(alpha: 0.15) : kSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: isHighlighted ? Border.all(color: kAccent.withValues(alpha: 0.4)) : null,
                  ),
                  child: Text(
                    'S${e.key + 1}: ${e.value.summary}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted ? kAccent : kText2,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (onUseSeries != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onUseSeries,
                child: Text(
                  'Usa stessi valori ->',
                  style: TextStyle(fontSize: 12, color: kAccent, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ],
        ),
      );
}

// â”€â”€â”€ STAT CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const StatCard({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSurface3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
                color: valueColor ?? kAccent,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: kText2)),
          ],
        ),
      );
}

// â”€â”€â”€ EMPTY STATE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji.trim().isNotEmpty) ...[
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: kText2, height: 1.5),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kText3),
                ),
              ],
            ],
          ),
        ),
      );
}

// â”€â”€â”€ CATEGORY CHIP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kAccent.withValues(alpha: 0.15) : kSurface2,
            border: Border.all(color: selected ? kAccent : kSurface3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? kAccent : kText2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}

