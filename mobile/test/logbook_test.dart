import 'package:car_nanny/features/logbook/cost_chart.dart';
import 'package:car_nanny/features/logbook/logbook_format.dart';
import 'package:car_nanny/features/logbook/logbook_models.dart';
import 'package:car_nanny/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _localized(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

List<MonthlyCosts> _months() => [
      for (var m = 1; m <= 12; m++)
        MonthlyCosts(
          month: '2026-${m.toString().padLeft(2, '0')}',
          byCategory: {for (final c in costCategories) c: 0}
            ..['fuel'] = m * 10
            ..['service'] = m == 9 ? 350 : 0,
        ),
    ];

void main() {
  group('dates', () {
    test('parseDay keeps the calendar day the API stored, whatever the device time zone', () {
      final d = parseDay('2026-09-01T00:00:00.000Z');
      expect([d.year, d.month, d.day], [2026, 9, 1]);
    });

    test('formatApiDay produces YYYY-MM-DD', () {
      expect(formatApiDay(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  group('parsing API responses', () {
    test('a Car Nanny booking in the records list is read-only', () {
      final r = LogRecord.fromJson({
        'id': 'b1',
        'source': 'booking',
        'type': 'service',
        'date': '2026-08-10T09:30:00.000Z',
        'title': 'oil_change',
        'partnerName': 'Al Quoz Garage',
        'cost': 420,
        'odometerKm': null,
        'photos': [],
      });
      expect(r.isBooking, isTrue);
      expect(r.cost, 420.0);
    });

    test('fuel log keeps null economy for partial fills', () {
      final log = FuelLog.fromJson({
        'averageKmPerLiter': 14,
        'averageLitersPer100Km': 7.142857,
        'totalLiters': 100,
        'totalCost': 300,
        'entries': [
          {'id': 'f2', 'date': '2026-09-15T00:00:00.000Z', 'odometerKm': 41700, 'liters': 30, 'cost': 90, 'fullTank': true, 'missedPrevious': false, 'kmPerLiter': 14, 'distanceKm': 400},
          {'id': 'f1', 'date': '2026-09-10T00:00:00.000Z', 'odometerKm': 41300, 'liters': 20, 'cost': 60, 'fullTank': false, 'missedPrevious': false, 'kmPerLiter': null},
        ],
      });
      expect(log.entries.first.kmPerLiter, 14.0);
      expect(log.entries.last.kmPerLiter, isNull);
      expect(log.averageKmPerLiter, 14.0);
    });

    test('attention items carry their vehicle', () {
      final r = Reminder.fromJson({
        'id': 'r1',
        'title': 'Registration',
        'urgency': 'overdue',
        'dueDate': '2026-09-01T00:00:00.000Z',
        'daysLeft': -22,
        'kmLeft': null,
        'vehicle': {'id': 'v1', 'make': 'Toyota', 'model': 'Camry', 'year': 2021, 'plateNumber': 'D 1'},
      });
      expect(r.vehicleId, 'v1');
      expect(r.vehicleLabel, '2021 Toyota Camry');
    });
  });

  testWidgets('cost chart shows a month breakdown when a bar is tapped', (tester) async {
    await tester.pumpWidget(_localized(const Locale('en'), CostChart(months: _months())));
    await tester.pumpAndSettle();

    expect(find.text('Service'), findsOneWidget); // legend
    await tester.tap(find.text('Sep'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Total AED 440'), findsOneWidget);
  });

  testWidgets('cost chart renders right-to-left in Arabic without overflow', (tester) async {
    await tester.pumpWidget(_localized(const Locale('ar'), CostChart(months: _months())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('وقود'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(CostChart)));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('reminder due text uses Arabic plural forms', (tester) async {
    late String twoDays;
    late String elevenDaysOverdue;
    await tester.pumpWidget(_localized(
      const Locale('ar'),
      Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        twoDays = l10n.reminderDaysLeft(2);
        elevenDaysOverdue = reminderDueText(context, l10n, dueDate: DateTime(2026, 9, 1), daysLeft: -11);
        return const SizedBox();
      }),
    ));
    expect(twoDays, 'متبقٍّ يومان');
    expect(elevenDaysOverdue, contains('متأخر 11 يومًا'));
  });
}
