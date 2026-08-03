import 'package:drinks/components/app_loading_view.dart';
import 'package:drinks/components/app_toast_overlay.dart';
import 'package:drinks/core/auth/token_storage.dart';
import 'package:drinks/core/network/api_exception.dart';
import 'package:drinks/data/apis/api_providers.dart';
import 'package:drinks/data/apis/auth_api.dart';
import 'package:drinks/l10n/generated/app_localizations.dart';
import 'package:drinks/views/user/auth_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login error closes loading and shows global toast',
      (tester) async {
    await _pumpAuth(tester, _FailingAuthApi(Duration.zero));
    await _submitLogin(tester);
    await tester.pump();

    expect(find.byType(AppLoadingView), findsNothing);
    expect(find.text('测试网络异常'), findsOneWidget);
  });

  testWidgets('login timeout closes loading when request completes',
      (tester) async {
    await _pumpAuth(tester, _FailingAuthApi(const Duration(seconds: 8)));
    await _submitLogin(tester);
    await tester.pump();
    expect(find.byType(AppLoadingView), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(find.byType(AppLoadingView), findsNothing);
    expect(find.text('测试网络异常'), findsOneWidget);
  });
}

Future<void> _pumpAuth(WidgetTester tester, AuthApi api) => tester.pumpWidget(
      ProviderScope(
        overrides: [authApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AppToastOverlay(child: child!),
          home: const AuthGateView(),
        ),
      ),
    );

Future<void> _submitLogin(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'test@example.com');
  await tester.enterText(fields.at(1), 'Test123!');
  await tester.tap(find.text('继续探索今晚'));
}

class _FailingAuthApi extends AuthApi {
  _FailingAuthApi(this.delay);

  final Duration delay;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    throw const ApiException(message: '测试网络异常');
  }
}
