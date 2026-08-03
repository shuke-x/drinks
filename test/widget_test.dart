import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drinks/components/app_loading_view.dart';

void main() {
  testWidgets('loading view communicates pending data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoadingView())),
    );

    expect(find.byType(AppLoadingView), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    expect(find.textContaining('加载'), findsNothing);
  });
}
