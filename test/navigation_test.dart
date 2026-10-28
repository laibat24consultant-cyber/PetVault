import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petvault/main.dart';

void main() {
  testWidgets('main navigation menu opens and shows app destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const PetVaultApp(),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Browse pets and products'));
    await tester.tap(find.text('Browse pets and products'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('ThePetsVault'), findsOneWidget);
    expect(find.text('MAIN MENU'), findsOneWidget);
    expect(find.text('Home'), findsNWidgets(2));
    expect(find.text('Pets Marketplace'), findsNWidgets(3));
    expect(find.text('YOUR ACCOUNT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page navigator is available from the app bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const PetVaultApp(),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Browse pets and products'));
    await tester.tap(find.text('Browse pets and products'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open page navigator'));
    await tester.pumpAndSettle();

    expect(find.text('Page navigator'), findsOneWidget);
    expect(find.text('Find a PetVault screen by name or category.'),
        findsOneWidget);
    expect(find.byWidgetPredicate((widget) {
      return widget is TextField &&
          widget.decoration?.hintText == 'Search pages';
    }), findsOneWidget);
    expect(find.text('Pet profiles & care'), findsOneWidget);
    await tester.enterText(
      find.byWidgetPredicate((widget) {
        return widget is TextField &&
            widget.decoration?.hintText == 'Search pages';
      }),
      'health',
    );
    await tester.pumpAndSettle();
    expect(find.text('Health records'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pet visit request page is rendered from the page navigator',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PetVaultApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Browse pets and products'));
    await tester.tap(find.text('Browse pets and products'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open page navigator'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate((widget) {
        return widget is TextField &&
            widget.decoration?.hintText == 'Search pages';
      }),
      'Pet visit requests',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pet visit requests').last);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to view your visit requests.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
