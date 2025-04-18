import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/web_socket_service.dart';
import 'services/api_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('$e');
  }

  await NotificationService.initialize();
  await ApiService.initializeToken();

  // Kullanıcı oturum açtıysa WebSocket bağlantısını başlat
  final isLoggedIn = await ApiService.isLoggedIn();
  if (isLoggedIn) {
    try {
      await WebSocketService().connect();
      print('WebSocket bağlantısı başlatıldı');
    } catch (e) {
      print('WebSocket bağlantısı başlatılamadı: $e');
    }
  }
  // Bildirim dinleyicilerini ayarla
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction) async {
      if (receivedAction.payload != null) {
        await NotificationService.onNotificationTap(jsonEncode(receivedAction.payload));
      }
    },
  );
  

// Periyodik olarak bildirimleri kontrol et
Timer.periodic(const Duration(minutes: 2), (timer) async {
  try {
    // Okunmamış bildirimleri al
    final result = await ApiService.getUnreadNotifications();
    if (result['success'] && result['notifications'] != null) {
      final notifications = List<dynamic>.from(result['notifications']);
      
      // Gösterilecek bildirim ID'lerini topla
      List<String> notificationIdsToMarkAsRead = [];
      
      for (var notification in notifications) {
        String title = '';
        String body = notification['mesaj'];
        String type = notification['tur'];
        String? username;
        
        // Bildirim ID'sini al
        final String notificationId = notification['id']?.toString() ?? '';
        
        switch (type) {
          case 'mesaj':
            title = 'Yeni Mesaj';
            username = body.split(" size mesaj gönderdi:")[0];
            break;
          case 'begeni':
            title = 'Yeni Beğeni';
            username = notification['kullanici']['username'];
            break;
          case 'takip':
            title = 'Yeni Takipçi';
            username = notification['kullanici']['username'];
            break;
          default:
            title = 'Yeni Bildirim';
        }
        
        await NotificationService.showNotification(
          title: title,
          body: body,
          type: type,
          username: username,
        );
        
        // Bildirim ID'sini listeye ekle
        if (notificationId.isNotEmpty) {
          notificationIdsToMarkAsRead.add(notificationId);
        }
      }
      
      // Bildirimleri okundu olarak işaretle
      if (notificationIdsToMarkAsRead.isNotEmpty) {
        await ApiService.markNotificationsAsRead(notificationIdsToMarkAsRead);
      }
    }
  } catch (e) {
    print('Bildirim kontrolü sırasında hata: $e');
  }
});

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gittiğinde bağlantıyı kapat
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _webSocketService.disconnect();
      print('Uygulama arka plana alındı, WebSocket bağlantısı kapatıldı');
    } 
    // Uygulama öne geldiğinde bağlantıyı yeniden kur
    else if (state == AppLifecycleState.resumed) {
      _reconnectIfNeeded();
      print('Uygulama öne getirildi, WebSocket bağlantısı kontrol ediliyor');
    }
  }
  
  Future<void> _reconnectIfNeeded() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn && !_webSocketService.isConnected) {
      try {
        await _webSocketService.connect();
        print('WebSocket bağlantısı yeniden kuruldu');
      } catch (e) {
        print('WebSocket yeniden bağlantı hatası: $e');
      }
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webSocketService.dispose();
    print('Uygulama kapatıldı, WebSocket servisi temizlendi');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETU Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B7FCE)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}