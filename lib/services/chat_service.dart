import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'web_socket_service.dart';

class ChatService {
  static final WebSocketService _webSocketService = WebSocketService();
  
  // WebSocket bağlantısını başlat ve bağlantı durumunu döndür
  static Future<bool> ensureWebSocketConnection() async {
    if (!_webSocketService.isConnected) {
      await _webSocketService.connect();
      // Bağlantının kurulması için kısa bir süre bekle
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _webSocketService.isConnected;
  }

  // Mesaj gönderme
  static Future<bool> sendMessage({
    required String receiverUsername,
    required String message,
  }) async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        return false;
      }
      
      // WebSocket bağlantısı varsa WebSocket üzerinden gönder
      if (_webSocketService.isConnected) {
        _webSocketService.sendMessage(
          receiverUsername: receiverUsername,
          message: message,
        );
        return true;
      } 
      // WebSocket bağlantısı yoksa HTTP üzerinden gönder
      else {
        return await _sendMessageHttp(receiverUsername, message);
      }
    } catch (e) {
      return false;
    }
  }
  
  // HTTP üzerinden mesaj gönderme (fallback)
  static Future<bool> _sendMessageHttp(String receiverUsername, String message) async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        return false;
      }

      final requestUrl = '${ApiService.baseUrl}/messages/send';
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': ApiService.getAuthorizationHeader()!,
      };
      final requestBody = {
        'receiverUsername': receiverUsername,
        'message': message,
      };
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: requestHeaders,
        body: jsonEncode(requestBody),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
 // Mesajları alma
  static Stream<List<Map<String, dynamic>>> getMessages(String otherUsername) async* {
    // Önce HTTP üzerinden mesaj geçmişini al
    final messages = await _getMessagesHttp(otherUsername);
    if (messages.isNotEmpty) {
      yield messages;
    }
    
    // WebSocket bağlantısını sağlamaya çalış
    final wsConnected = await ensureWebSocketConnection();
    
    if (wsConnected) {
      // Mesaj geçmişini iste
      _webSocketService.requestMessageHistory(otherUsername);
      
      // WebSocket üzerinden gelen mesajları dinle
      await for (final message in _webSocketService.messageStream) {
        if (message['senderUsername'] == otherUsername || 
            message['receiverUsername'] == otherUsername) {
          yield [message];
        }
      }
    } else {
      // WebSocket bağlantısı kurulamadıysa periyodik olarak HTTP ile kontrol et
      while (true) {
        await Future.delayed(const Duration(seconds: 3));
        final newMessages = await _getMessagesHttp(otherUsername);
        if (newMessages.isNotEmpty) {
          yield newMessages;
        }
        
        // WebSocket bağlantısı kurulduysa döngüyü sonlandır
        if (_webSocketService.isConnected) break;
      }
    }
  }

// Yeni mesajları dinlemek için stream
static Stream<Map<String, dynamic>> getMessageStream(String otherUsername) {
  // WebSocket bağlantısını başlat
  if (!_webSocketService.isConnected) {
    _webSocketService.connect();
  }
  
  // WebSocket üzerinden gelen mesajları filtrele
  return _webSocketService.messageStream
    .where((message) => 
      message['senderUsername'] == otherUsername || 
      message['receiverUsername'] == otherUsername);
}

  static Future<List<Map<String, dynamic>>> _getMessagesHttp(String otherUsername) async {
    try {
      final response = await ApiService.getMessages(otherUsername);
      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('HTTP ile mesaj geçmişi alma hatası: $e');
      return [];
    }
  }
  // Sohbet listesini alma
  static Stream<List<Map<String, dynamic>>> getChatList() async* {
    // Önce HTTP üzerinden sohbet listesini al
    final chatList = await _getChatListHttpOnce();
    if (chatList.isNotEmpty) {
      yield chatList;
    }
    
    // WebSocket bağlantısını sağlamaya çalış
    final wsConnected = await ensureWebSocketConnection();
    
    if (wsConnected) {
      // WebSocket üzerinden sohbet listesini iste
      _webSocketService.requestChatList();
      
      // WebSocket üzerinden gelen sohbet listesini dinle
      await for (final chats in _webSocketService.chatListStream) {
        yield chats;
      }
    } else {
      // WebSocket bağlantısı kurulamadıysa periyodik olarak HTTP ile kontrol et
      while (true) {
        await Future.delayed(const Duration(seconds: 3));
        final newChatList = await _getChatListHttpOnce();
        if (newChatList.isNotEmpty) {
          yield newChatList;
        }
        
        // WebSocket bağlantısı kurulduysa döngüyü sonlandır
        if (_webSocketService.isConnected) break;
      }
    }
  }
  
  // HTTP üzerinden sohbet listesini bir kez alma
  static Future<List<Map<String, dynamic>>> _getChatListHttpOnce() async {
    try {
      final response = await ApiService.getChatList();
      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('HTTP ile sohbet listesi alma hatası: $e');
      return [];
    }
  }
}