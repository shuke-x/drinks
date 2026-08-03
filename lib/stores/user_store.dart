import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/token_storage.dart';
import '../core/network/dio_client.dart';
import '../core/query/query_cache.dart';
import '../data/apis/api_providers.dart';
import '../data/apis/auth_api.dart';
import '../data/apis/user_api.dart';
import '../models/cocktail.dart';
import 'cocktail_store.dart';
import 'my_cocktails_store.dart';
import 'settings_store.dart';

class UserState {
  const UserState({
    this.ready = false,
    this.isLoggedIn = false,
    this.isBusy = false,
    this.id,
    this.email,
    this.name = '今晚的调酒师',
    this.avatarUrl,
    this.avatarBase64,
    this.favoriteIds = const {},
    this.language,
    this.sessionExpiredEvent = 0,
  });

  final bool ready;
  final bool isLoggedIn;
  final bool isBusy;
  final String? id;
  final String? email;
  final String name;
  final String? avatarUrl;

  /// 兼容旧版本本地头像缓存；新头像统一上传后保存 [avatarUrl]。
  final String? avatarBase64;
  final Set<String> favoriteIds;

  /// null 表示跟随系统；当前仅允许 zh / en。
  final String? language;
  final int sessionExpiredEvent;

  UserState copyWith({
    bool? ready,
    bool? isLoggedIn,
    bool? isBusy,
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? avatarBase64,
    bool clearProfile = false,
    bool clearAvatar = false,
    Set<String>? favoriteIds,
    String? language,
    bool clearLanguage = false,
    int? sessionExpiredEvent,
  }) =>
      UserState(
        ready: ready ?? this.ready,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isBusy: isBusy ?? this.isBusy,
        id: clearProfile ? null : id ?? this.id,
        email: clearProfile ? null : email ?? this.email,
        name: name ?? this.name,
        avatarUrl:
            clearAvatar || clearProfile ? null : avatarUrl ?? this.avatarUrl,
        avatarBase64: clearAvatar || clearProfile
            ? null
            : avatarBase64 ?? this.avatarBase64,
        favoriteIds: favoriteIds ?? this.favoriteIds,
        language: clearLanguage ? null : language ?? this.language,
        sessionExpiredEvent: sessionExpiredEvent ?? this.sessionExpiredEvent,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(
    this._authApi,
    this._userApi,
    this._appData,
    this._dioClient,
    this._resetSessionCaches,
  ) : super(const UserState()) {
    _dioClient.onSessionExpired = handleSessionExpired;
    _restore();
  }

  static const _key = 'tonight-drinks-user-v1';
  static const _languageKey = 'tonight-drinks-language-v1';

  final AuthApi _authApi;
  final UserApi _userApi;
  final AppDataNotifier _appData;
  final DioClient _dioClient;
  final void Function() _resetSessionCaches;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final localLanguage = prefs.getString(_languageKey);
    final cached = _decodeCachedUser(prefs.getString(_key));
    final tokens = await TokenStorage.instance.read();
    if (tokens == null) {
      state = UserState(ready: true, language: localLanguage);
      await prefs.remove(_key);
      return;
    }

    state = cached.copyWith(
      ready: false,
      isLoggedIn: true,
      language: localLanguage,
      clearLanguage: localLanguage == null,
    );
    try {
      await synchronizeRemote();
    } catch (_) {
      // 网络暂时不可用时保留已验证过的本地会话；401 会由拦截器清除会话。
      state = state.copyWith(ready: true);
    }
  }

  UserState _decodeCachedUser(String? raw) {
    if (raw == null) return const UserState();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserState(
        id: map['id'] as String?,
        email: map['email'] as String?,
        name: map['name'] as String? ?? '今晚的调酒师',
        avatarUrl: map['avatarUrl'] as String?,
        avatarBase64: map['avatarBase64'] as String?,
        favoriteIds: ((map['favoriteIds'] as List?) ?? const [])
            .whereType<String>()
            .toSet(),
        language: map['language'] as String?,
      );
    } catch (_) {
      return const UserState();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!state.isLoggedIn) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode({
        'id': state.id,
        'email': state.email,
        'name': state.name,
        'avatarUrl': state.avatarUrl,
        'favoriteIds': state.favoriteIds.toList(),
        'language': state.language,
      }),
    );
  }

  Future<void> establishSession({required String fallbackName}) async {
    state = state.copyWith(
      ready: true,
      isLoggedIn: true,
      name: fallbackName,
    );
    await _persist();
    try {
      await synchronizeRemote();
    } catch (_) {
      if (!state.isLoggedIn) rethrow;
      state = state.copyWith(ready: true);
      await _persist();
    }
  }

  Future<void> synchronizeRemote() async {
    final values = await Future.wait<dynamic>([
      _userApi.me(),
      _userApi.favoriteIds(),
      _userApi.myCocktails(),
    ]);
    final profile = values[0] as UserProfile;
    final favoriteIds = values[1] as Set<String>;
    final cocktails = values[2] as List<Cocktail>;
    final prefs = await SharedPreferences.getInstance();
    final hasLocalLanguage = prefs.containsKey(_languageKey);
    final effectiveLanguage =
        hasLocalLanguage ? state.language : profile.language;
    state = state.copyWith(
      ready: true,
      isLoggedIn: true,
      id: profile.id,
      email: profile.email,
      name: profile.name,
      avatarUrl: profile.avatarUrl,
      clearAvatar: profile.avatarUrl == null,
      favoriteIds: favoriteIds,
      language: effectiveLanguage,
      clearLanguage: effectiveLanguage == null,
    );
    if (!hasLocalLanguage && profile.language != null) {
      await prefs.setString(_languageKey, profile.language!);
    } else if (hasLocalLanguage && profile.language != state.language) {
      await _userApi.updateLanguage(state.language);
    }
    _appData.replaceMine(cocktails);
    await _persist();
  }

  Future<void> updateProfile({required String name, String? avatarUrl}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;
    state = state.copyWith(isBusy: true);
    try {
      final profile = await _userApi.updateProfile(
        name: normalizedName,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        isBusy: false,
        id: profile.id,
        email: profile.email,
        name: profile.name,
        avatarUrl: profile.avatarUrl,
        clearAvatar: profile.avatarUrl == null,
      );
      await _persist();
    } catch (_) {
      state = state.copyWith(isBusy: false);
      rethrow;
    }
  }

  Future<bool> toggleFavorite(String cocktailId) async {
    if (!state.isLoggedIn) return false;
    final previous = {...state.favoriteIds};
    final next = {...previous};
    final adding = !next.remove(cocktailId);
    if (adding) next.add(cocktailId);
    state = state.copyWith(favoriteIds: next);
    await _persist();
    try {
      if (adding) {
        await _userApi.addFavorite(cocktailId);
      } else {
        await _userApi.removeFavorite(cocktailId);
      }
      return adding;
    } catch (_) {
      state = state.copyWith(favoriteIds: previous);
      await _persist();
      rethrow;
    }
  }

  Future<void> setLanguage(String? language) async {
    if (language != null && language != 'zh' && language != 'en') return;
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      language: language,
      clearLanguage: language == null,
    );
    if (language == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, language);
    }
    await _persist();
    if (state.isLoggedIn) await _userApi.updateLanguage(language);
  }

  Future<void> logout() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true);
    final refreshToken = await TokenStorage.instance.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authApi.logout(refreshToken);
      }
    } catch (_) {
      // 离线或令牌已失效时仍允许用户安全退出本机。
    } finally {
      await _clearLocalSession();
    }
  }

  Future<void> deleteAccount() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      await _userApi.deleteAccount();
      await _clearLocalSession();
    } catch (_) {
      state = state.copyWith(isBusy: false);
      rethrow;
    }
  }

  Future<void> handleSessionExpired() async {
    await _clearLocalSession(sessionExpired: true);
  }

  Future<void> _clearLocalSession({bool sessionExpired = false}) async {
    final nextSessionExpiredEvent = state.sessionExpiredEvent + 1;
    await TokenStorage.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _appData.clear();
    _resetSessionCaches();
    state = UserState(
      ready: true,
      language: prefs.getString(_languageKey),
      sessionExpiredEvent:
          sessionExpired ? nextSessionExpiredEvent : state.sessionExpiredEvent,
    );
  }

  @override
  void dispose() {
    _dioClient.onSessionExpired = null;
    super.dispose();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(
    ref.watch(authApiProvider),
    ref.watch(userApiProvider),
    ref.read(appDataProvider.notifier),
    DioClient.instance,
    () {
      ref.read(queryClientProvider).clear();
      ref.invalidate(cocktailFeedProvider);
      ref.invalidate(myCocktailsProvider);
    },
  );
});
