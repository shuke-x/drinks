import 'package:dio/dio.dart';

import '../../core/network/dio_controller.dart';

/// 图片上传服务端接口：`POST /upload/image`。
class UploadApi {
  UploadApi({DioController? controller})
      : _controller = controller ?? DioController();

  final DioController _controller;

  /// 返回可写入 `CocktailUpsertRequest.images` 的图片 URL。
  Future<String> uploadImage(
    MultipartFile file, {
    UploadPurpose purpose = UploadPurpose.cocktail,
  }) =>
      _controller.post(
        '/upload/image',
        queryParameters: {'purpose': purpose.name},
        data: FormData.fromMap({'file': file}),
        decoder: (data) => (data as Map<String, dynamic>)['url'] as String,
      );
}

enum UploadPurpose { avatar, cocktail }
