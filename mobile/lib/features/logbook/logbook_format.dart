import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Numbers stay in Latin digits in both languages, matching the rest of the app.
final _grouped = NumberFormat('#,##0', 'en');
final _grouped2 = NumberFormat('#,##0.00', 'en');
final _oneDecimal = NumberFormat('#,##0.0', 'en');

String formatAed(double amount, {bool cents = false}) => 'AED ${(cents ? _grouped2 : _grouped).format(amount)}';
String formatKm(AppLocalizations l10n, num km) => l10n.unitKm(_grouped.format(km));
String formatInt(num n) => _grouped.format(n);
String formatOneDecimal(double n) => _oneDecimal.format(n);

/// Localized month names, but Latin digits in every language, like the rest of the app.
String formatDay(BuildContext context, DateTime d) =>
    (DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())..useNativeDigits = false).format(d);

String formatMonthShort(BuildContext context, String yyyyMm) {
  final parts = yyyyMm.split('-');
  final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat.MMM(Localizations.localeOf(context).toLanguageTag()).format(d);
}

String categoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'service':
      return l10n.categoryService;
    case 'repair':
      return l10n.categoryRepair;
    case 'upgrade':
      return l10n.categoryUpgrade;
    case 'fee':
      return l10n.categoryFee;
    case 'fuel':
      return l10n.categoryFuel;
    case 'car_nanny':
      return l10n.categoryCarNanny;
    default:
      return category;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'service':
      return Icons.oil_barrel_outlined;
    case 'repair':
      return Icons.build_outlined;
    case 'upgrade':
      return Icons.auto_awesome_outlined;
    case 'fee':
      return Icons.receipt_long_outlined;
    case 'fuel':
      return Icons.local_gas_station_outlined;
    default:
      return Icons.verified_outlined;
  }
}

/// Categorical colours for the cost chart, stepped for the dark navy surface.
/// Assigned in [costCategories] order and never cycled, so each category keeps
/// one colour everywhere; brand gold stays reserved for UI, not data.
const categoryColors = <String, Color>{
  'service': Color(0xFF3987E5),
  'repair': Color(0xFFD95926),
  'upgrade': Color(0xFF199E70),
  'fee': Color(0xFFC98500),
  'fuel': Color(0xFFD55181),
  'car_nanny': Color(0xFF9085E9),
};

/// Maps reminder urgency onto the app's existing green/amber/red status badge.
String urgencyStatus(String urgency) {
  switch (urgency) {
    case 'overdue':
      return 'red';
    case 'due_soon':
    case 'upcoming':
      return 'amber';
    default:
      return 'green';
  }
}

String urgencyLabel(AppLocalizations l10n, String urgency) {
  switch (urgency) {
    case 'overdue':
      return l10n.reminderOverdue;
    case 'due_soon':
      return l10n.reminderDueSoon;
    case 'upcoming':
      return l10n.reminderUpcoming;
    case 'done':
      return l10n.reminderDone;
    default:
      return l10n.reminderLater;
  }
}

/// "12 days left · 300 km to go" — whichever targets the reminder has.
String reminderDueText(BuildContext context, AppLocalizations l10n, {int? daysLeft, int? kmLeft, DateTime? dueDate, int? dueOdometerKm}) {
  final parts = <String>[];
  if (dueDate != null) {
    final when = formatDay(context, dueDate);
    if (daysLeft == null) {
      parts.add(when);
    } else {
      parts.add('$when · ${daysLeft < 0 ? l10n.reminderDaysOverdue(-daysLeft) : l10n.reminderDaysLeft(daysLeft)}');
    }
  }
  if (dueOdometerKm != null) {
    final at = formatKm(l10n, dueOdometerKm);
    if (kmLeft == null) {
      parts.add(at);
    } else {
      parts.add('$at · ${kmLeft <= 0 ? l10n.reminderKmOver(formatInt(-kmLeft)) : l10n.reminderKmLeft(formatInt(kmLeft))}');
    }
  }
  return parts.join('\n');
}

/// A small coloured square used as a legend/category key.
class CategorySwatch extends StatelessWidget {
  const CategorySwatch({super.key, required this.category, this.size = 10});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: categoryColors[category] ?? AppColors.textSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
