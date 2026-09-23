import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'logbook_format.dart';
import 'logbook_models.dart';

/// Twelve monthly bars, each stacked by cost category. Built from plain
/// widgets rather than a chart package: this chart needs nothing fancier, and
/// the project's Android toolchain has already rejected several plugins.
///
/// Tapping a bar shows that month's breakdown. Categories are identified by a
/// legend (never colour alone), and the all-time breakdown table beside this
/// chart carries the exact figures.
class CostChart extends StatefulWidget {
  const CostChart({super.key, required this.months});

  final List<MonthlyCosts> months;

  @override
  State<CostChart> createState() => _CostChartState();
}

class _CostChartState extends State<CostChart> {
  int? _selected;

  static const _chartHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = widget.months;
    final maxTotal = months.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final used = costCategories.where((c) => months.any((m) => (m.byCategory[c] ?? 0) > 0)).toList();
    final selected = _selected == null ? null : months[_selected!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: selected == null
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${l10n.costsLast12Months} · ${formatAed(months.fold(0, (s, m) => s + m.total))}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : _SelectedMonth(month: selected),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _chartHeight + 22,
          child: LayoutBuilder(builder: (context, constraints) {
            // Month names that don't fit their bar (Arabic has no short forms)
            // are thinned to every other month, always keeping the newest.
            final labelStyle = DefaultTextStyle.of(context).style.copyWith(fontSize: 10);
            final widest = months
                .map((m) => (TextPainter(
                      text: TextSpan(text: formatMonthShort(context, m.month), style: labelStyle),
                      textDirection: Directionality.of(context),
                      maxLines: 1,
                    )..layout())
                        .width)
                .fold<double>(0, (a, b) => a > b ? a : b);
            final thin = widest + 4 > constraints.maxWidth / months.length;
            bool showLabel(int i) => !thin || _selected == i || (months.length - 1 - i).isEven;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: '${formatMonthShort(context, months[i].month)}: ${formatAed(months[i].total)}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selected = _selected == i ? null : i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _Bar(
                              month: months[i],
                              maxTotal: maxTotal,
                              height: _chartHeight,
                              dimmed: _selected != null && _selected != i,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              showLabel(i) ? formatMonthShort(context, months[i].month) : '',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 10,
                                color: _selected == i ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: _selected == i ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        if (used.length > 1) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final c in used)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategorySwatch(category: c),
                    const SizedBox(width: 6),
                    Text(categoryLabel(l10n, c), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.month, required this.maxTotal, required this.height, required this.dimmed});

  final MonthlyCosts month;
  final double maxTotal;
  final double height;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (final c in costCategories)
        if ((month.byCategory[c] ?? 0) > 0) MapEntry(c, month.byCategory[c]!),
    ];
    if (maxTotal <= 0 || segments.isEmpty) {
      return Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        color: AppColors.glassBorder,
      );
    }
    final barHeight = height * (month.total / maxTotal);
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Container(
        height: barHeight.clamp(3, height),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
        // First category sits on the baseline, matching the legend order.
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: (segments[i].value * 1000).round().clamp(1, 1 << 30),
                child: Container(
                  margin: EdgeInsets.only(top: i == segments.length - 1 ? 0 : 1.5),
                  color: categoryColors[segments[i].key],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMonth extends StatelessWidget {
  const _SelectedMonth({required this.month});

  final MonthlyCosts month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parts = [
      for (final c in costCategories)
        if ((month.byCategory[c] ?? 0) > 0) (c, month.byCategory[c]!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${formatMonthShort(context, month.month)} · ${l10n.costsMonthTotal} ${formatAed(month.total)}',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        if (parts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (c, amount) in parts) ...[
                  CategorySwatch(category: c, size: 8),
                  const SizedBox(width: 4),
                  Text('${categoryLabel(l10n, c)} ${formatAed(amount)}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
