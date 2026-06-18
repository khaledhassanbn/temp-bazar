import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SupportImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// اختيار صورة من المعرض
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// اختيار صورة من الكاميرا
  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// رفع صورة إلى Firebase Storage
  Future<String> uploadImage(File file, String conversationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('support_images/$conversationId/$fileName');
    
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await uploadTask.ref.getDownloadURL();
  }
}
