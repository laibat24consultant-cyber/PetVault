import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petvault/main.dart';

void main() {
  testWidgets('welcome layout adapts from phones through laptop widths',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    const viewports = <Size>[
      Size(320, 568),
      Size(375, 667),
      Size(600, 800),
      Size(768, 1024),
      Size(840, 600),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(const PetVaultApp());
      await tester.pumpAndSettle();

      expect(find.text('Care for every part of their life.'), findsOneWidget,
          reason: 'Welcome content at $viewport');
      expect(
        find.byKey(const ValueKey<String>('welcome-desktop-layout')),
        viewport.width >= 840 ? findsOneWidget : findsNothing,
        reason: 'Responsive welcome composition at $viewport',
      );
      expect(tester.takeException(), isNull, reason: 'Viewport $viewport');
    }
  });

  testWidgets('main navigation switches between mobile bar and desktop rail',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    const viewports = <Size>[
      Size(390, 640),
      Size(768, 1024),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        const MaterialApp(home: VaultPageView(page: AppPage.home)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('petvault-desktop-navigation')),
        viewport.width >= 1024 ? findsOneWidget : findsNothing,
        reason: 'Desktop navigation at $viewport',
      );
      expect(
        find.byKey(const ValueKey<String>('petvault-bottom-navigation')),
        viewport.width >= 1024 ? findsNothing : findsOneWidget,
        reason: 'Mobile navigation at $viewport',
      );
      expect(tester.takeException(), isNull, reason: 'Viewport $viewport');
    }
  });
}
