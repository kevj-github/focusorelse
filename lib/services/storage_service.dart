import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload profile picture
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Upload pact evidence photo
  Future<String> uploadPactPhoto(String pactId, File imageFile) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('pact_evidence')
          .child(pactId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading pact photo: $e');
      rethrow;
    }
  }

  // Upload pact evidence video
  Future<String> uploadPactVideo(String pactId, File videoFile) async {
    try {
      final String fileName = '${_uuid.v4()}.mp4';
      final Reference storageRef = _storage
          .ref()
          .child('pact_evidence')
          .child(pactId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading pact video: $e');
      rethrow;
    }
  }

  // Delete file by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  // Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = _storage.ref(path);
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error getting download URL: $e');
      rethrow;
    }
  }
}
