import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_controller.dart';
import '../models/flavor_direction.dart';

final flavorDirectionsProvider =
    FutureProvider.autoDispose<List<FlavorDirection>>((ref) => DioController()
        .get('/flavor-directions',
            decoder: (data) => (data as List)
                .map((item) => FlavorDirection.fromJson(
                    Map<String, dynamic>.from(item as Map)))
                .toList(growable: false)));
