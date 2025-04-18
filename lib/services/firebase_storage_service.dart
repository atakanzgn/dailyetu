import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadProfilePhoto(File photoFile, String username) async {
    try {
      // Dosya uzantısını al
      String extension = path.extension(photoFile.path);
      
      // Profil fotoğrafı için referans oluştur
      final ref = _storage.ref().child('profile_photos/$username$extension');
      
      // Dosyayı yükle
    final uploadTask = ref.putFile(photoFile);
      
    // Yükleme durumunu izle
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      print('Yükleme durumu: ${snapshot.state}');
      print('Yüklenen: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}');
    });
    
      // İndirme URL'sini al
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteProfilePhoto(String username) async {
    try {
      // Olası dosya uzantıları
      final extensions = ['.jpg', '.jpeg', '.png'];
      
      for (var extension in extensions) {
        try {
          final ref = _storage.ref().child('profile_photos/$username$extension');
          await ref.delete();
        } catch (e) {
          // Dosya bulunamadıysa veya başka bir hata olduysa devam et
          continue;
        }
      }
    } catch (e) {
      print('Profil fotoğrafı silinirken hata: $e');
    }
  }

  static Future<String?> uploadPostPhoto(File photoFile, String postId) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final photoRef = storageRef.child('posts/$postId');
      
      final uploadTask = await photoRef.putFile(photoFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Post fotoğrafı yükleme hatası: $e');
      return null;
    }
  }
} 