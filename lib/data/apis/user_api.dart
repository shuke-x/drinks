import '../../core/network/dio_controller.dart';
import '../../core/network/api_page.dart';
import '../../models/cocktail.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.language,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? language;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        language: json['language'] as String?,
      );
}

class UserApi {
  UserApi({DioController? controller})
      : _controller = controller ?? DioController();

  final DioController _controller;

  Future<UserProfile> me() => _controller.get(
        '/users/me',
        decoder: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );

  Future<UserProfile> updateProfile({String? name, String? avatarUrl}) =>
      _controller.patch(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
        decoder: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );

  Future<UserProfile> updateLanguage(String? language) => _controller.patch(
        '/users/me',
        data: {'language': language},
        decoder: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );

  Future<ApiPage<Cocktail>> myCocktailsPage({
    int page = 1,
    int limit = 20,
    CocktailStatus? status,
  }) =>
      _controller.getPage(
        '/users/me/cocktails',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status.name,
        },
        decoder: (data) => (data as List)
            .map((item) => Cocktail.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Future<List<Cocktail>> myCocktails() async =>
      (await myCocktailsPage(limit: 50)).items;

  Future<Set<String>> favoriteIds() => _controller.get(
        '/users/me/favorites',
        decoder: (data) => (data as List)
            .map((item) => item as Map<String, dynamic>)
            .map((item) => item['cocktail'] as Map<String, dynamic>)
            .map((cocktail) => cocktail['id'] as String)
            .toSet(),
      );

  Future<void> addFavorite(String cocktailId) => _controller.post(
        '/users/me/favorites',
        data: {'cocktailId': cocktailId},
        decoder: (_) {},
      );

  Future<void> removeFavorite(String cocktailId) => _controller.delete(
        '/users/me/favorites',
        data: {'cocktailId': cocktailId},
        decoder: (_) {},
      );

  Future<void> deleteAccount() => _controller.delete(
        '/users/me',
        decoder: (_) {},
      );
}
