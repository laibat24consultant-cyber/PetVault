import 'package:flutter_test/flutter_test.dart';
import 'package:petvault/main.dart';

void main() {
  testWidgets('PetVault app starts without a framework exception',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PetVaultApp());
    await tester.pumpAndSettle();

    expect(find.text('Care for every part of their life.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
