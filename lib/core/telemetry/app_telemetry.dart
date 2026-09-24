import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// Allowlisted diagnostic events. Never pass exception messages, URLs, headers,
/// user identity, breadcrumbs, widget trees, photographs or form data here.
class AppTelemetry {
  static final _transport = Dio(BaseOptions(
    baseUrl: Env.baseUrl,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  ));
  static final Map<String, DateTime> _lastSent = {};
  static int _inFlight = 0;

  static void install() {
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.presentError(details);
      capture('flutter', details.stack);
    };
    PlatformDispatcher.instance.onError = (_, stack) {
      capture('unhandled', stack);
      return true;
    };
  }

  static void network(DioException error) {
    if (error.type == DioExceptionType.cancel) return;
    final status = error.response?.statusCode;
    if (status != null && status < 500) return;
    capture(status == null ? 'network_unavailable' : 'network_server', null);
  }

  static void capture(String category, StackTrace? stack) {
    if (!const bool.fromEnvironment('TELEMETRY_ENABLED', defaultValue: true)) {
      return;
    }
    if (!const {'flutter', 'unhandled', 'network_unavailable', 'network_server'}
        .contains(category)) {
      return;
    }
    final now = DateTime.now();
    final last = _lastSent[category];
    if (_inFlight >= 2 ||
        (last != null && now.difference(last) < const Duration(minutes: 1))) {
      return;
    }
    _lastSent[category] = now;
    // Only hash source locations belonging to this app, never the raw stack.
    var fingerprint = 0x811c9dc5;
    final locations = RegExp(r'package:drinks/[a-zA-Z0-9_/.]+\.dart:\d+')
        .allMatches(stack?.toString() ?? '')
        .take(8)
        .map((match) => match.group(0)!)
        .join('|');
    for (final code in locations.codeUnits) {
      fingerprint = ((fingerprint ^ code) * 0x01000193) & 0xffffffff;
    }
    _inFlight++;
    unawaited(_transport
        .post<void>('/telemetry/client-errors', data: {
          'category': category,
          'fingerprint': fingerprint.toRadixString(16).padLeft(8, '0'),
          'platform': defaultTargetPlatform.name,
        })
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .whenComplete(() => _inFlight--));
  }
}
