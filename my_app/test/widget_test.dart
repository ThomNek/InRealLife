import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_irl/core/theme/app_theme.dart';
import 'package:treasure_irl/features/home/presentation/home_page.dart';

void main() {
  testWidgets('Home renders Treasure IRL content', (tester) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(
          profileStream: Stream.value({'display_name': 'Test User'}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TREASURE\nIRL'), findsOneWidget);
    expect(find.text('Kho báu & Hoạt động gần bạn'), findsOneWidget);
    expect(find.text('Hoạt động gần đây'), findsOneWidget);
  });
}
