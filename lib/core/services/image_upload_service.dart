import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../network/api_service.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ApiService _apiService = ApiService();

  /// Upload multiple images to the server
  Future<List<String>> uploadImages(List<File> images) async {
    try {
      List<String> uploadedUrls = [];

      for (File image in images) {
        final url = await _uploadSingleImage(image);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    }
  }

  /// Upload a single image to the server
  Future<String?> _uploadSingleImage(File image) async {
    try {
      print('Starting image upload for: ${image.path}');

      // Create form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: path.basename(image.path),
        ),
        'type': 'product', // Specify the type for different upload folders
      });

      print('FormData created, sending to server...');

      // Upload to server
      final response = await _apiService.post('/upload/image', data: formData);

      print('Server response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data['success']) {
        final imageUrl = response.data['image_url'];
        print('Upload successful, image URL: $imageUrl');
        return imageUrl;
      } else {
        print('Upload failed: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete an image from the server
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final response = await _apiService.delete('/upload/image', data: {
        'image_url': imageUrl,
      });

      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get image dimensions and file size
  Future<Map<String, dynamic>> getImageInfo(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final size = bytes.length;

      // For basic image info without loading the full image
      return {
        'size': size,
        'size_mb': (size / (1024 * 1024)).toStringAsFixed(2),
        'extension': path.extension(image.path).toLowerCase(),
        'filename': path.basename(image.path),
      };
    } catch (e) {
      print('Error getting image info: $e');
      return {};
    }
  }

  /// Validate image file
  bool isValidImage(File image) {
    final extension = path.extension(image.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    return validExtensions.contains(extension);
  }

  /// Compress image if needed (basic implementation)
  Future<File> compressImageIfNeeded(File image, {int maxSizeMB = 5}) async {
    try {
      final info = await getImageInfo(image);
      final sizeMB = double.tryParse(info['size_mb'] ?? '0') ?? 0;

      if (sizeMB <= maxSizeMB) {
        return image; // No compression needed
      }

      // For now, return the original image
      // In a production app, you'd implement actual image compression
      print(
          'Image size ${sizeMB}MB exceeds ${maxSizeMB}MB limit. Consider compressing.');
      return image;
    } catch (e) {
      print('Error checking image size: $e');
      return image;
    }
  }
}
