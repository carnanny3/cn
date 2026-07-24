import 'package:flutter_test/flutter_test.dart';

import 'package:car_nanny/main.dart';

void main() {
  testWidgets('App boots to the auth screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const CarNannyApp());
    await tester.pumpAndSettle();

    expect(find.text('Car Nanny'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
