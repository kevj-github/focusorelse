import 'dart:io';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageServiceException implements Exception {
  final String code;
  final String message;

  const StorageServiceException({required this.code, required this.message});

  @override
  String toString() => 'StorageServiceException($code): $message';
}

class StorageService {
  final Uuid _uuid = const Uuid();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim() ?? '';

  String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim() ?? '';

  void _validateCloudinaryConfig() {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw const StorageServiceException(
        code: 'config-missing',
        message:
            'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env.',
      );
    }
  }

  Future<String> _uploadFile({
    required File file,
    required String folder,
    required String fileName,
    required bool isVideo,
  }) async {
    _validateCloudinaryConfig();

    final resourceType = isVideo ? 'video' : 'image';
    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = fileName
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw StorageServiceException(
        code: 'upload-failed',
        message:
            'Cloudinary upload failed (${streamedResponse.statusCode}): $responseBody',
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const StorageServiceException(
        code: 'invalid-response',
        message: 'Cloudinary returned an invalid response format.',
      );
    }

    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw const StorageServiceException(
        code: 'missing-url',
        message: 'Cloudinary response did not include secure_url.',
      );
    }

    return secureUrl;
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final fileName = 'profile_$userId';
      return await _uploadFile(
        file: imageFile,
        folder: 'focusorelse/profile_pictures',
        fileName: fileName,
        isVideo: false,
      );
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Upload pact evidence photo
  Future<String> uploadPactPhoto(String pactId, File imageFile) async {
    try {
      final fileName = _uuid.v4();
      return await _uploadFile(
        file: imageFile,
        folder: 'focusorelse/pact_evidence/$pactId',
        fileName: fileName,
        isVideo: false,
      );
    } catch (e) {
      print('Error uploading pact photo: $e');
      rethrow;
    }
  }

  // Upload pact evidence video
  Future<String> uploadPactVideo(String pactId, File videoFile) async {
    try {
      final fileName = _uuid.v4();
      return await _uploadFile(
        file: videoFile,
        folder: 'focusorelse/pact_evidence/$pactId',
        fileName: fileName,
        isVideo: true,
      );
    } catch (e) {
      print('Error uploading pact video: $e');
      rethrow;
    }
  }

  // Upload post image
  Future<String> uploadPostImage(String userId, File imageFile) async {
    try {
      final fileName = _uuid.v4();
      return await _uploadFile(
        file: imageFile,
        folder: 'focusorelse/posts/$userId',
        fileName: fileName,
        isVideo: false,
      );
    } catch (e) {
      print('Error uploading post image: $e');
      rethrow;
    }
  }

  // Delete by URL is not supported with unsigned Cloudinary uploads.
  Future<void> deleteFile(String fileUrl) async {
    throw const StorageServiceException(
      code: 'not-supported',
      message: 'deleteFile is not supported with unsigned Cloudinary uploads.',
    );
  }

  // Cloudinary returns full download URLs at upload time.
  Future<String> getDownloadUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    throw const StorageServiceException(
      code: 'invalid-url',
      message: 'Expected a direct Cloudinary URL.',
    );
  }
}
