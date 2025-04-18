import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'firebase_storage_service.dart';
import 'package:dio/dio.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_socket_service.dart';

class ApiService
{
  static String get baseUrl
  {
    return 'http://10.0.2.2:8080';
  }

    // WebSocket URL'si (HTTP -> WS, HTTPS -> WSS)
static String get wsUrl {
  String url = baseUrl;
  if (url.startsWith('https://')) {
    url = url.replaceFirst('https://', 'wss://');
  } else if (url.startsWith('http://')) {
    url = url.replaceFirst('http://', 'ws://');
  } else {
    // Şema yoksa ws:// ekle
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      url = 'ws://$url';
    }
  }
  // WebSocket endpoint'ini ekle
  return '$url/ws/websocket';
}

  static String? _token;
  static Map<String, dynamic>? _currentUser;
  static Dio _dio = Dio();
  


  static Future<void> initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      // Token varsa kullanıcı bilgilerini al
      await getUserProfile();
    }
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static String? getToken()
  {
    return _token;
  }
  
  static String? getAuthorizationHeader()
  {
    if (_token == null) {
      return null;
    }
    final header = 'Bearer $_token';
    return header;
  }
  
  static Map<String, dynamic>? getCurrentUser()
  {
    return _currentUser;
  }
  static Future<Map<String, dynamic>> getUserProfile() async
  {
    try
    {
      if(_token == null)
      {
        return
        {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }
      final response = await http.get(
        Uri.parse('$baseUrl/user/me'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );
      if(response.body.isEmpty)
      {
        return
        {
          'success': false,
          'message': 'Sunucudan boş yanıt geldi.',
        };
      }
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));  // UTF-8 ile decode et
      if(response.statusCode == 200)
      {
        _currentUser = responseData;  // Kullanıcı bilgilerini güncelle
        return
        {
          'success': true,
          'data': responseData,
        };
      }
      else
      {
        return
        {
          'success': false,
          'message': 'Profil bilgileri alınamadı!}',
        };
      }
    }
    catch(e)
    {
      return
      {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String katilmaTarihi,
  }) async {
    try {
      final requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'katilmaTarihi': katilmaTarihi,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/user/save'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Sunucudan boş yanıt geldi.',
        };
      }

      try {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Kayıt başarılı!',
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message': 'Kayıt olma başarısız: ${response.body}',
          };
        }
      } on FormatException {
        return {
          'success': false,
          'message': 'Sunucu yanıtı geçersiz format. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> login({
  required String username,
  required String password,
}) async {
  try {
    final requestBody = {
      'username': username,
      'password': password,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.body.isEmpty) {
      return {
        'success': false,
        'message': 'Sunucudan boş yanıt geldi.',
      };
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = response.body;
      await setToken(token);
      _currentUser = {
        'username': username,
      };
      
      // WebSocket bağlantısını başlat
      try {
        await WebSocketService().connect();
      } catch (e) {
        print('WebSocket bağlantısı başlatılamadı: $e');
      }
      
      return {
        'success': true,
        'message': 'Giriş başarılı!',
        'token': token,
        'data': _currentUser,
      };
    } else {
      return {
        'success': false,
        'message': 'Giriş başarısız: ${response.body}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Bağlantı hatası: ${e.toString()}',
    };
  }
}
static Future<Map<String, dynamic>> logout() async {
  try {
    // WebSocket bağlantısını kapat
    await WebSocketService().disconnect();
    
    // Token ve kullanıcı bilgilerini temizle
    await clearToken();
    _currentUser = null;
    
    return {
      'success': true,
      'message': 'Çıkış başarılı!',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Çıkış sırasında hata: ${e.toString()}',
    };
  }
}
//Kullanıcı arama
static Future<Map<String, dynamic>> searchUsers(String query) async {
  try {
    // Boş sorgu kontrolü
    if (query.trim().isEmpty) {
      return {
        'success': true,
        'message': 'Arama sorgusu boş',
        'users': [],
      };
    }

    // Token kontrolü
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Oturum açmanız gerekiyor',
      };
    }

    // API isteği
    final requestUrl = '$baseUrl/user/search?query=${Uri.encodeComponent(query)}';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse(requestUrl),
      headers: requestHeaders,
    );

    // Yanıt kontrolü
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {
          'success': true,
          'message': 'Sonuç bulunamadı',
          'users': [],
        };
      }

      try {
        // Yanıt doğrudan bir liste olarak geliyor
        final List<dynamic> userList = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': 'Kullanıcılar başarıyla alındı',
          'users': userList,
        };
      } catch (e) {
        print('JSON parse hatası: $e');
        return {
          'success': false,
          'message': 'Yanıt işlenirken hata oluştu: $e',
        };
      }
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Oturum süresi dolmuş, lütfen tekrar giriş yapın',
      };
    } else {
      String errorMessage = 'Kullanıcılar alınamadı: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        }
      } catch (e) {
        // JSON parse hatası
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  } catch (e) {
    print('Arama hatası: $e');
    return {
      'success': false,
      'message': 'Bağlantı hatası: $e',
    };
  }
}
//Kullanıcı giriş yapmış mı
static Future<bool> isLoggedIn() async {
  try {
    // Token kontrolü
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Kullanıcı bilgisi kontrolü
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      return false;
    }
    
    // Token geçerliliği kontrolü (opsiyonel)
    // Bu kısım, token'ın geçerli olup olmadığını kontrol etmek için
    // sunucuya istek gönderebilir, ancak performans için genellikle
    // sadece token varlığı kontrol edilir
    
    return true;
  } catch (e) {
    print('Oturum durumu kontrolü sırasında hata: $e');
    return false;
  }
}


  static Future<Map<String, dynamic>> getUserProfileByUsername(String username) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Sunucudan boş yanıt geldi.',
        };
      }

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Profil bilgileri alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/check-username/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'available': true,
        };
      } else if (response.statusCode == 409) {
        return {
          'success': true,
          'available': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Kullanıcı adı kontrol edilemedi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> updateProfile({
    required String ad,
    required String soyad,
    required String biyografi,
    String? username,
  }) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      // Kullanıcı adı uzunluk kontrolü
      if (username != null && username.length < 3) {
        return {
          'success': false,
          'message': 'Kullanıcı adı en az 3 karakter olmalıdır.',
        };
      }

      // Eğer kullanıcı adı değiştirilmek isteniyorsa, önce kontrol et
      if (username != null) {
        final usernameCheck = await checkUsername(username);
        if (!usernameCheck['success']) {
          return usernameCheck;
        }
        if (!usernameCheck['available']) {
          return {
            'success': false,
            'message': 'Bu kullanıcı adı zaten kullanılıyor.',
          };
        }
      }

      final requestBody = {
        'ad': ad,
        'soyad': soyad,
        'biyografi': biyografi,
        if (username != null) 'username': username,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
        body: jsonEncode(requestBody),
      );

      // Başarılı durumda
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Profil güncellendi',
          'data': requestBody,
        };
      }

      // Hata durumları
      String errorMessage;
      try {
        final responseData = jsonDecode(response.body);
        errorMessage = responseData['message'] ?? 'Profil güncellenemedi';
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Profil güncellenemedi';
      }

      return {
        'success': false,
        'message': errorMessage,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      // Önce Firebase Storage'dan profil fotoğrafını sil
      if (_currentUser != null) {
        await FirebaseStorageService.deleteProfilePhoto(_currentUser!['username']);
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/user/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        await clearToken();
        return {
          'success': true,
          'message': 'Hesabınız başarıyla silindi',
        };
      } else {
        return {
          'success': false,
          'message': 'Hesap silinemedi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> uploadProfilePhoto(File photoFile) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      // Dosya boyutunu kontrol et (5MB)
      if (await photoFile.length() > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Dosya boyutu 5MB\'dan büyük olamaz.',
        };
      }

      // Firebase Storage'a yükle
      final downloadUrl = await FirebaseStorageService.uploadProfilePhoto(
        photoFile,
        _currentUser!['username'],
      );

      if (downloadUrl == null) {
        return {
          'success': false,
          'message': 'Fotoğraf yüklenemedi.',
        };
      }
      final requestBody =
      {
        'profilResmi': downloadUrl,
      };
      final response = await http.put(
        Uri.parse('$baseUrl/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Sunucudan boş yanıt geldi.',
        };
      }
      if (response.statusCode == 200)
      {
        return
        {
          'success': true,
          'message': 'Profil fotoğrafı güncellendi',
          'profilResmi': downloadUrl,
        };
      }
      else
      {
        return
        {
          'success': false,
          'message': 'Profil fotoğrafı güncellenemedi.',
        };
      }
    }
    catch(e)
    {
      return
      {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> requestPasswordReset(String username) async {
    try {
      final requestUrl = '$baseUrl/user/request-reset';
      final requestBody = {
        'username': username,
      };

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Bu işlem için yetkiniz yok. Lütfen daha sonra tekrar deneyin.',
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Kullanıcı bulunamadı',
        };
      }

      // Başarılı durumda, sunucu yanıtı JSON olmasa bile işlemi başarılı sayıyoruz
      if (response.statusCode == 200) {
        try {
          // Önce JSON olarak parse etmeyi dene
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': true,
            'message': responseData['message'] ?? 'Onay kodu gönderildi.',
          };
        } catch (e) {
          // JSON parse edilemezse, direkt yanıtı kullan
          return {
            'success': true,
            'message': 'Onay kodu e-posta adresinize gönderildi',
          };
        }
      }

      // Diğer hata durumları
      try {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': responseData['message'] ?? 'Şifre sıfırlama isteği başarısız.',
        };
      } catch (e) {
        return {
          'success': false,
          'message': response.body.isNotEmpty ? response.body : 'Sunucudan yanıt alınamadı.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode(String username, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/verify-reset-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'code': code,
        }),
      );

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Sunucudan boş yanıt geldi.',
        };
      }

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Kod doğrulandı.',
          'token': responseData['token'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Kod doğrulama başarısız.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      // Başarılı durumda, sunucu yanıtı JSON olmasa bile işlemi başarılı sayıyoruz
      if (response.statusCode == 200) {
        try {
          // Önce JSON olarak parse etmeyi dene
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': true,
            'message': responseData['message'] ?? 'Şifre başarıyla güncellendi.',
          };
        } catch (e) {
          // JSON parse edilemezse varsayılan başarılı mesajı dön
          return {
            'success': true,
            'message': 'Şifre başarıyla güncellendi.',
          };
        }
      }

      // Hata durumları
      try {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': responseData['message'] ?? 'Şifre güncelleme başarısız.',
        };
      } catch (e) {
        return {
          'success': false,
          'message': response.body.isNotEmpty ? response.body : 'Şifre güncelleme başarısız.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }


// Mesaj geçmişini getir
static Future<Map<String, dynamic>> getMessages(String otherUsername) async {
  try {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }
    
    final requestUrl = '$baseUrl/messages/$otherUsername';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    final response = await http.get(
      Uri.parse(requestUrl),
      headers: requestHeaders,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Mesajlar alınamadı: HTTP ${response.statusCode}',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Mesajlar alınamadı: $e'};
  }
}

// Sohbet listesini getir
static Future<Map<String, dynamic>> getChatList() async {
  try {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token bulunamadı'};
    }
    
    final requestUrl = '$baseUrl/messages/chats';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    final response = await http.get(
      Uri.parse(requestUrl),
      headers: requestHeaders,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Sohbet listesi alınamadı: HTTP ${response.statusCode}',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Sohbet listesi alınamadı: $e'};
  }
}

  static Future<Map<String, dynamic>> deleteChat(String otherUsername) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/chat/$otherUsername'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Sohbet başarıyla silindi',
        };
      } else {
        return {
          'success': false,
          'message': 'Sohbet silinirken bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir bağlantı hatası oluştu',
      };
    }
  }

  static Future<Map<String, dynamic>> chatWithAI(String message) async {
    try {
        final token = getToken();
        if (token == null) {
            return {
                'success': false,
                'message': 'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
            };
        }

        final response = await http.post(
            Uri.parse('$baseUrl/api/ai/chat'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
                'message': message,
                'model': 'gpt-3.5-turbo',
                'language': 'tr'
            }),
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return {
                'success': true,
                'response': data['response'],
            };
        } else if (response.statusCode == 403) {
            return {
                'success': false,
                'message': 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.',
            };
        } else {
            String errorMessage = 'Bir hata oluştu: ${response.statusCode}';
            try {
                final errorData = jsonDecode(response.body);
                errorMessage = errorData['message'] ?? errorMessage;
            } catch (e) {
                // Hata mesajı parse edilemedi
            }
            return {
                'success': false,
                'message': errorMessage,
            };
        }
    } catch (e) {
        return {
            'success': false,
            'message': 'Bağlantı hatası: $e',
        };
    }
  }

  static Future<Map<String, dynamic>> createTextPost({
    required String content,
    String? title,
  }) async {
    try {
      final token = getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/posts/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'baslik': title,
          'icerik': content,
          'type': 'text',
          'olusturulmaTarihi': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Gönderi başarıyla paylaşıldı',
        };
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Gönderi paylaşılırken bir hata oluştu';
        } catch (e) {
          errorMessage = 'Gönderi paylaşılırken bir hata oluştu: ${response.statusCode}';
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> createPhotoPost({
    required File photoFile,
    required String content,
    required List<String> tags,
  }) async {
    try {
      final token = getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      // Önce geçici bir post ID oluştur
      String tempPostId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Fotoğrafı Firebase'e yükle
      final photoUrl = await FirebaseStorageService.uploadPostPhoto(photoFile, tempPostId);
      
      if (photoUrl == null) {
        return {
          'success': false,
          'message': 'Fotoğraf yüklenirken bir hata oluştu.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/posts/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'icerik': content,
          'gorsel': photoUrl,
          'etiketler': tags,
          'type': 'photo',
          'olusturulmaTarihi': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Gönderi başarıyla paylaşıldı',
        };
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Gönderi paylaşılırken bir hata oluştu';
        } catch (e) {
          errorMessage = 'Gönderi paylaşılırken bir hata oluştu: ${response.statusCode}';
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUserPosts(String username) async {
    try {
      final token = getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/posts/user/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'posts': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Gönderiler alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUserPostCount(String username) async {
    try {
      final token = getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/posts/count/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'count': responseData['count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gönderi sayısı alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
//Takip etme
static Future<Map<String, dynamic>> followUser(String username) async {
  try {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
      };
    }
    
    // Önce takip durumunu kontrol et
    final checkResult = await checkFollowStatus(username);
    if (checkResult['success'] && checkResult['isFollowing']) {
      return {
        'success': false,
        'message': 'Bu kullanıcıyı zaten takip ediyorsunuz.',
      };
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/follow/takipEt/$username'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': getAuthorizationHeader()!,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': true,
        'message': 'Takip edilmeye başlandı.',
        'data': responseData,
      };
    } else {
      // Hata mesajını daha anlaşılır hale getir
      String errorMessage = 'Takip edilemedi';
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else {
          errorMessage = 'Takip edilemedi: ${response.statusCode}';
        }
      } catch (e) {
        errorMessage = 'Takip edilemedi: ${response.statusCode}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Bağlantı hatası: ${e.toString()}',
    };
  }
}

  static Future<Map<String, dynamic>> getFollowCounts(String username) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/follow/count/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Takipçi sayıları alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> checkFollowStatus(String username) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/follow/takipKontrol/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'isFollowing': responseData['isFollowing'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': 'Takip durumu kontrol edilemedi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

static Future<Map<String, dynamic>> unfollowUser(String username) async {
  try {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
      };
    }
    
    // Önce takip durumunu kontrol et
    final checkResult = await checkFollowStatus(username);
    if (checkResult['success'] && !checkResult['isFollowing']) {
      return {
        'success': false,
        'message': 'Bu kullanıcıyı zaten takip etmiyorsunuz.',
      };
    }
    
    final response = await http.delete(
      Uri.parse('$baseUrl/api/follow/takiptenCik/$username'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': getAuthorizationHeader()!,
      },
    );
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Takipten çıkıldı.',
      };
    } else {
      // Hata mesajını daha anlaşılır hale getir
      String errorMessage = 'Takipten çıkılamadı';
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else {
          errorMessage = 'Takipten çıkılamadı: ${response.statusCode}';
        }
      } catch (e) {
        errorMessage = 'Takipten çıkılamadı: ${response.statusCode}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Bağlantı hatası: ${e.toString()}',
    };
  }
}

  static Future<Map<String, dynamic>> getFeedPosts() async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/posts/feed'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Debug için tarih bilgisini yazdıralım
        if (responseData is List && responseData.isNotEmpty) {
        }
        
        return {
          'success': true,
          'posts': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Gönderiler alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getLikeCount(int postId) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/likes/count/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'count': responseData['count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Beğeni sayısı alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/likes/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'message': 'Gönderi beğenildi',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Gönderi beğenilemedi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> unlikePost(int postId) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/likes/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Gönderi beğenisi kaldırıldı',
        };
      } else {
        return {
          'success': false,
          'message': 'Gönderi beğenisi kaldırılamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> isPostLiked(int postId) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/likes/check/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'isLiked': responseData['isLiked'],
        };
      } else {
        return {
          'success': false,
          'message': 'Beğeni durumu kontrol edilemedi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  static Set<int> _processedNotificationIds = {};
  static bool _isNotificationScreenOpen = false;

  static void setNotificationScreenState(bool isOpen) {
    _isNotificationScreenOpen = isOpen;
  }

  static Future<void> _loadProcessedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('processed_notifications') ?? [];
    _processedNotificationIds = savedIds.map((id) => int.parse(id)).toSet();
  }

  static Future<void> _saveProcessedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final idsToSave = _processedNotificationIds.map((id) => id.toString()).toList();
    await prefs.setStringList('processed_notifications', idsToSave);
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      await _loadProcessedNotifications();

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': getAuthorizationHeader()!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (responseData is List && responseData.isNotEmpty) {
          final List<dynamic> newNotifications = [];
          
          for (var notification in responseData) {
            final id = notification['id'];
            if (!_processedNotificationIds.contains(id)) {
              newNotifications.add(notification);
              _processedNotificationIds.add(id);
            }
          }

          await _saveProcessedNotifications();

          if (!_isNotificationScreenOpen && newNotifications.isNotEmpty) {
            for (var notification in newNotifications) {
              String title = '';
              String body = notification['mesaj'];
              String type = notification['tur'];
              String? username;

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
            }
          }
        }

        return {
          'success': true,
          'notifications': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Bildirimler alınamadı: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bildirimler alınırken bir hata oluştu: ${e.toString()}',
      };
    }
  }

// Okunmamış bildirimleri getir
static Future<Map<String, dynamic>> getUnreadNotifications() async {
  try {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Oturum açmanız gerekiyor',
      };
    }

    final requestUrl = '$baseUrl/api/notifications/unread';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse(requestUrl),
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> notifications = jsonDecode(response.body);
      return {
        'success': true,
        'notifications': notifications,
      };
    } else {
      return {
        'success': false,
        'message': 'Bildirimler alınamadı: ${response.statusCode}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Bildirim kontrolü sırasında hata: $e',
    };
  }
}

// Bildirimleri okundu olarak işaretle
static Future<bool> markNotificationsAsRead(List<String> notificationIds) async {
  try {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    final requestUrl = '$baseUrl/api/notifications/mark-read';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    // String ID'leri Long'a çevir
    final List<int> longIds = notificationIds.map((id) => int.parse(id)).toList();
    
    final requestBody = {
      'notificationIds': longIds,
    };

    final response = await http.post(
      Uri.parse(requestUrl),
      headers: requestHeaders,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? false;
    }
    return false;
  } catch (e) {
    print('Bildirimleri okundu olarak işaretlerken hata: $e');
    return false;
  }
}

// Tüm bildirimleri okundu olarak işaretle
static Future<bool> markAllNotificationsAsRead() async {
  try {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    final requestUrl = '$baseUrl/api/notifications/mark-all-read';
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse(requestUrl),
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? false;
    }
    return false;
  } catch (e) {
    print('Tüm bildirimleri okundu olarak işaretlerken hata: $e');
    return false;
  }
}

  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      _dio.options.baseUrl = baseUrl;
      _dio.options.headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      await _dio.delete('/api/notifications/$notificationId');
      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bildirim silinirken bir hata oluştu: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'Token bulunamadı. Lütfen tekrar giriş yapın.',
        };
      }

      _dio.options.baseUrl = baseUrl;
      _dio.options.headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      await _dio.delete('/api/notifications/all');
      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bildirimler silinirken bir hata oluştu: ${e.toString()}',
      };
    }
  }
}