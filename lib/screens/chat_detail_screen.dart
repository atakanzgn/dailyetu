import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_profile_screen.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String otherUsername;
  const ChatDetailScreen({
    super.key,
    required this.otherUsername,
  });
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _messageController = TextEditingController();
  
  // Mesaj listesi ve controller
  final List<Map<String, dynamic>> _messages = [];
  final StreamController<List<Map<String, dynamic>>> _messagesController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  
  StreamSubscription? _messageSubscription;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _subscribeToNewMessages();
    _loadUserProfile();
  }
  
  // İlk mesaj geçmişini yükle
  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await ApiService.getMessages(widget.otherUsername);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> messageData = response['data'];
        
        setState(() {
          _messages.clear();
          _messages.addAll(List<Map<String, dynamic>>.from(messageData));
          _messagesController.add(_messages);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Mesaj geçmişi yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Yeni mesajları dinle
  void _subscribeToNewMessages() {
    // WebSocket üzerinden gelen yeni mesajları dinle
    _messageSubscription = ChatService.getMessageStream(widget.otherUsername).listen((newMessage) {
      setState(() {
        // Yeni mesajı mevcut listeye ekle (eğer zaten yoksa)
        if (!_messages.any((m) => m['id'] == newMessage['id'])) {
          _messages.insert(0, newMessage); // Yeni mesajı listenin başına ekle (reverse: true için)
          _messagesController.add(_messages);
        }
      });
    });
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/profile/${widget.otherUsername}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            // Profil bilgilerini güncelle
          });
        }
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messagesController.close();
    _messageSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text;
    _messageController.clear();
    
    // Mesajı gönder
    final success = await ChatService.sendMessage(
      receiverUsername: widget.otherUsername,
      message: message,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj gönderilemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Not: Yeni mesaj WebSocket üzerinden geldiğinde _subscribeToNewMessages() 
    // tarafından otomatik olarak listeye eklenecek
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: ApiService.getUserProfileByUsername(widget.otherUsername),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['success'] == true) {
                  final userData = snapshot.data!['data'];
                  final profilResmi = userData['profilResmi'];
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: profilResmi != null ? NetworkImage(profilResmi) : null,
                    child: profilResmi == null
                        ? Text(
                            widget.otherUsername[0].toUpperCase(),
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  );
                }
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.otherUsername[0].toUpperCase(),
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        username: widget.otherUsername,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.getUserProfileByUsername(widget.otherUsername),
                      builder: (context, snapshot) {
                        String displayName = widget.otherUsername;
                        if (snapshot.hasData && snapshot.data!['success'] == true) {
                          final userData = snapshot.data!['data'];
                          if (userData['ad'] != null) {
                            displayName = '${userData['ad']} ${userData['soyad'] ?? ''}'.trim();
                          }
                        }
                        return Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      '@${widget.otherUsername}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Sohbet ayarları menüsü
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesController.stream,
                    initialData: _messages,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('StreamBuilder hatası: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Bir hata oluştu: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      
                      final messages = snapshot.data ?? [];
                      
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz mesaj yok',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          
                          final currentUser = ApiService.getCurrentUser();
                          final isMe = message['senderUsername'] == currentUser?['username'];
                          
                          final timestamp = message['timestamp'];
                          final time = timestamp != null 
                              ? DateTime.parse(timestamp).toLocal()
                              : DateTime.now();
                          final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'] ?? message['icerik'] as String,
                                    style: TextStyle(
                                      color: isMe ? _primaryColor : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isMe
                                          ? _primaryColor.withOpacity(0.7)
                                          : Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: ImageIcon(
                    const AssetImage('assets/icons/add.png'),
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    // TODO: Medya ekleme menüsü
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
                ),
                IconButton(
                  icon: ImageIcon(
                    const AssetImage('assets/icons/send.png'),
                    color: Colors.white,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}