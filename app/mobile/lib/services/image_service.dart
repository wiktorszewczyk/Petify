import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'api/initial_api.dart';

class ImageResponse {
  final int id;
  final int entityId;
  final String entityType;
  final String imageUrl;
  final DateTime createdAt;

  ImageResponse({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    // Handle image URL and replace localhost with proper IP
    String imageUrl = json['imageUrl']?.toString() ?? '';
    if (imageUrl.contains('localhost')) {
      imageUrl = imageUrl.replaceAll('localhost', '192.168.1.12');
    }

    return ImageResponse(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] as num).toInt(),
      entityId: json['entityId'] is String ? int.parse(json['entityId']) : (json['entityId'] as num).toInt(),
      entityType: json['entityType']?.toString() ?? '',
      imageUrl: imageUrl,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ImageService {
  final _api = InitialApi().dio;
  static ImageService? _instance;

  factory ImageService() => _instance ??= ImageService._();
  ImageService._();

  /// Pobiera obraz po ID
  Future<ImageResponse> getImageById(int imageId) async {
    try {
      dev.log('🖼️ ImageService: Pobieranie obrazu ID=$imageId');
      final response = await _api.get('/images/$imageId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ImageResponse.fromJson(response.data);
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('❌ ImageService: Błąd podczas pobierania obrazu $imageId: ${e.message}');
      throw Exception('Nie udało się pobrać obrazu: ${e.message}');
    }
  }

  /// Pobiera obrazy po listie ID
  Future<List<ImageResponse>> getImagesByIds(List<int> imageIds) async {
    final images = <ImageResponse>[];

    for (final imageId in imageIds) {
      try {
        final image = await getImageById(imageId);
        images.add(image);
      } catch (e) {
        dev.log('⚠️ ImageService: Nie udało się pobrać obrazu ID=$imageId: $e');
        // Kontynuuj z pozostałymi obrazami
      }
    }

    return images;
  }

  /// Pobiera obrazy dla encji (np. dla posta)
  Future<List<ImageResponse>> getEntityImages(int entityId, String entityType) async {
    try {
      dev.log('🖼️ ImageService: Pobieranie obrazów dla $entityType ID=$entityId');
      final response = await _api.get('/images/$entityType/$entityId/images');

      if (response.statusCode == 200 && response.data is List) {
        final imagesData = response.data as List;
        return imagesData.map((imageJson) => ImageResponse.fromJson(imageJson)).toList();
      }

      throw Exception('Nieprawidłowa odpowiedź serwera');
    } on DioException catch (e) {
      dev.log('❌ ImageService: Błąd podczas pobierania obrazów dla $entityType $entityId: ${e.message}');
      throw Exception('Nie udało się pobrać obrazów: ${e.message}');
    }
  }
}