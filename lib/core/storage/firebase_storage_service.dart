import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final FirebaseStorage storage;

  FirebaseStorageService(this.storage);

  Future<String?> uploadParticipantImage(
    String imagePath, {
    required Function(double progress) onProgress,
  }) async {
    try {
      final file = File(imagePath);

      final extension = imagePath.split('.').last;

      final fileName = '${const Uuid().v4()}.$extension';

      final ref = storage.ref().child('participants').child(fileName);

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;

          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        return null;
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print("STORAGE ERROR: $e");
      return null;
    }
  }

  Future<String?> uploadMessageImage(
    String imagePath, {
    required String messageId,
    required Function(double progress) onProgress,
  }) async {
    try {
      final file = File(imagePath);

      final extension = imagePath.split('.').last;

      final fileName = '$messageId.$extension';

      final ref = storage.ref().child('messages').child(fileName);

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;

          onProgress(progress);
        }
      });

      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        return null;
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('MESSAGE IMAGE STORAGE ERROR: $e');
      return null;
    }
  }
}
