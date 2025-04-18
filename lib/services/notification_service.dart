import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final Int64List highVibrationPattern = Int64List.fromList([255]);
  static final Int64List lowVibrationPattern = Int64List.fromList([128]);
  
  // Gösterilen bildirimleri takip etmek için
  static Future<bool> isNotificationShown(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownNotifications = prefs.getStringList('shown_notifications') ?? [];
    return shownNotifications.contains(notificationId);
  }

  // Gösterilen bildirimleri kaydetmek için
  static Future<void> markNotificationAsShown(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownNotifications = prefs.getStringList('shown_notifications') ?? [];
    
    // Listede çok fazla bildirim birikmesin diye, en fazla 100 bildirim tutalım
    if (shownNotifications.length >= 100) {
      shownNotifications.removeAt(0); // En eski bildirimi kaldır
    }
    
    shownNotifications.add(notificationId);
    await prefs.setStringList('shown_notifications', shownNotifications);
  }
  
  // Eski bildirimleri temizle (24 saatten eski)
  static Future<void> cleanOldNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final shownNotifications = prefs.getStringList('shown_notifications') ?? [];
    
    if (shownNotifications.isEmpty) return;
    
    // Bugünün tarihini al
    final today = DateTime.now().day;
    
    // Bugünün tarihini içermeyen bildirimleri temizle
    // (Bildirim ID'si içinde gün bilgisi varsa)
    final updatedList = shownNotifications.where((id) {
      // Eğer ID'de tarih bilgisi yoksa koru
      if (!id.contains(':')) return true;
      
      final parts = id.split(':');
      if (parts.length < 3) return true;
      
      // Son kısım tarih ise kontrol et
      try {
        final day = int.parse(parts.last);
        return day == today; // Sadece bugünün bildirimlerini tut
      } catch (e) {
        return true; // Parse hatası varsa koru
      }
    }).toList();
    
    if (updatedList.length != shownNotifications.length) {
      await prefs.setStringList('shown_notifications', updatedList);
      print('${shownNotifications.length - updatedList.length} eski bildirim temizlendi');
    }
  }

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Temel Bildirimler',
          channelDescription: 'ETU Daily bildirimleri',
          defaultColor: const Color(0xFF6B7FCE),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          vibrationPattern: highVibrationPattern,
        ),
        NotificationChannel(
          channelKey: 'message_channel',
          channelName: 'Mesaj Bildirimleri',
          channelDescription: 'Mesaj bildirimleri',
          defaultColor: const Color(0xFF6B7FCE),
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          vibrationPattern: lowVibrationPattern,
        ),
      ],
    );
    
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    
    // Eski bildirimleri temizle
    await cleanOldNotifications();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    String? username,
  }) async {
    // Bildirim için benzersiz bir ID oluştur
    final String notificationId = '$type:$body:${DateTime.now().day}';
    
    // Bu bildirim daha önce gösterilmiş mi kontrol et
    final bool alreadyShown = await isNotificationShown(notificationId);
    if (alreadyShown) {
      print('Bu bildirim zaten gösterilmiş: $notificationId');
      return;
    }
    
    String channelKey;
    Map<String, String> payload = {'type': type};
    
    if (username != null) {
      payload['username'] = username;
    }
    
    switch (type) {
      case 'mesaj':
        channelKey = 'message_channel';
        break;
      default:
        channelKey = 'basic_channel';
    }
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 100000, // Daha güvenilir bir ID
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
      ),
    );
    
    // Bildirimi gösterildi olarak işaretle
    await markNotificationAsShown(notificationId);
  }

  static Future<void> onNotificationTap(String? payload) async {
    if (payload == null) return;
    
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      String? type = data['type'];
      String? username = data['username'];
      if (type != null && username != null) {
        // TODO: Bildirime tıklandığında ilgili ekrana yönlendirme yapılacak
        // Bu işlem için global navigator key kullanılmalı
        print('Bildirim tıklandı: Tür=$type, Kullanıcı=$username');
      }
    } catch (e) {
      print('Bildirim işleme hatası: $e');
    }
  }
}