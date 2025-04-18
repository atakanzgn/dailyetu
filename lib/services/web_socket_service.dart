import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  
  StompClient? _stompClient;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatListController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _historyController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  bool _isConnected = false;
  bool _isConnecting = false;
  
  // Stream getters
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<Map<String, dynamic>>> get chatListStream => _chatListController.stream;
  Stream<List<Map<String, dynamic>>> get historyStream => _historyController.stream;
  
  bool get isConnected => _isConnected;
  
  // WebSocket bağlantısını başlat
  Future<bool> connect() async {
    if (_isConnecting) return _isConnected;
    _isConnecting = true;
    
    if (_stompClient != null) {
      await disconnect();
    }
    
    final token = await ApiService.getToken();
    if (token == null) {
      _isConnecting = false;
      return false;
    }
    
    final String socketUrl = 'ws://10.0.2.2:8080/ws/websocket';
    
      // Bağlantı tamamlandığında çözülecek bir Completer
      final completer = Completer<bool>();

    _stompClient = StompClient(
      config: StompConfig(
        url: socketUrl,
        onConnect: (frame)
        {
        _isConnected = true;
        _isConnecting = false;
        _subscribeToUserChannels();
        completer.complete(true);
        },
        onDisconnect: (frame)
        {
        _isConnected = false;
        _isConnecting = false;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        },
        onWebSocketError: (error) {
        print('WebSocket Error: $error');
        _isConnecting = false;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onStompError: (frame) {
        _isConnecting = false;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      stompConnectHeaders: {
        'Authorization': 'Bearer $token',
      },
      webSocketConnectHeaders: {
        'Authorization': 'Bearer $token',
      },
      connectionTimeout: Duration(seconds: 10),
    ),
  );
    
  try {
    _stompClient!.activate();
    // Bağlantı için maksimum 5 saniye bekle
    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('WebSocket bağlantı zaman aşımı');
        _isConnecting = false;
        return false;
      },
    );
  } catch (e) {
    print('WebSocket bağlantı hatası: $e');
    _isConnecting = false;
    return false;
  }
  }
  
  // Bağlantı kesildiğinde
  Future<void> disconnect() async {
    try {
      _stompClient?.deactivate();
    } catch (e) {//
    } finally {
      _isConnected = false;
      _isConnecting = false;
    }
  }
  // Kullanıcı kanallarına abone ol
  void _subscribeToUserChannels() {
    // ÖNEMLİ: Spring Boot'un beklediği format /user/queue/messages şeklinde
    // username prefix'i Spring tarafında otomatik ekleniyor
    
    // Yeni mesajlar için abone ol
    _stompClient!.subscribe(
      destination: '/user/queue/messages',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final message = jsonDecode(frame.body!);
            _messageController.add(message);
          } catch (e) {//
          }
        }
      },
    );
    
    // Sohbet listesi için abone ol
    _stompClient!.subscribe(
      destination: '/user/queue/chatList',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final List<dynamic> chatList = jsonDecode(frame.body!);
            _chatListController.add(chatList.cast<Map<String, dynamic>>());
          } catch (e) {//
          }
        }
      },
    );
    
    // Mesaj geçmişi için abone ol
    _stompClient!.subscribe(
      destination: '/user/queue/history',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          print('Mesaj geçmişi alındı: ${frame.body}');
          try {
            final List<dynamic> history = jsonDecode(frame.body!);
            _historyController.add(history.cast<Map<String, dynamic>>());
          } catch (e) {
            print('Mesaj geçmişi işlenirken hata: $e');
          }
        }
      },
    );
    
    // Sohbet listesini iste
    requestChatList();
  }
  // Sohbet listesini iste
void requestChatList() {
  if (!_isConnected) {
    print('Sohbet listesi istenemedi: Bağlantı yok');
    return;
  }
  
  try {
    print('Sohbet listesi isteniyor...');
    _stompClient!.send(
      destination: '/app/chat.getChatList',
      body: '',
    );
    print('Sohbet listesi istendi');
  } catch (e) {
    print('Sohbet listesi istenirken hata: $e');
  }
}


  // Mesaj gönderme
  Future<void> sendMessage({required String receiverUsername, required String message}) async {
    if (!_isConnected) {
      connect().then((_) => _sendMessageInternal(receiverUsername, message));
      return;
      }
      _sendMessageInternal(receiverUsername, message);  
  }
  
  void _sendMessageInternal(String receiverUsername, String message) {
  try {
    final chatMessage = {
      'receiverUsername': receiverUsername,
      'message': message,
    };
    
    _stompClient!.send(
      destination: '/app/chat.sendMessage',
      body: jsonEncode(chatMessage),
    );
    print('Mesaj gönderildi: $chatMessage');
    
    // Not: Mesaj başarıyla gönderildiğinde, sunucu tarafından
    // /user/queue/messages kanalına gönderilen yanıt zaten dinleniyor
  } catch (e) {
    print('Mesaj gönderilirken hata: $e');
  }
}
  // Mesaj geçmişini iste
  Future<void> requestMessageHistory(String otherUsername) async {
    if (!_isConnected) {
      await connect();
      if (!_isConnected) {
        print('Mesaj geçmişi istenemedi: WebSocket bağlantısı yok');
        return;
      }
    }
    
    try {
      _stompClient!.send(
        destination: '/app/chat.getHistory',
        body: otherUsername,
      );
      print('Mesaj geçmişi istendi: $otherUsername');
    } catch (e) {
      print('Mesaj geçmişi istenirken hata: $e');
    }
  }
  
  // Servisi kapat
  void dispose() {
    disconnect();
    _messageController.close();
    _chatListController.close();
    _historyController.close();
  }
}