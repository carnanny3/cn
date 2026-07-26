import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_nanny/main.dart';
import 'package:car_nanny/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('App boots to the auth screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const CarNannyApp());
    await tester.pumpAndSettle();

    expect(find.text('Car Nanny'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('Arabic locale renders translated text with RTL directionality', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(body: Text(l10n.appTagline));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سيارتك. مسؤوليتنا.'), findsOneWidget);

    final directionality = Directionality.of(tester.element(find.byType(Scaffold)));
    expect(directionality, TextDirection.rtl);
  });
}
