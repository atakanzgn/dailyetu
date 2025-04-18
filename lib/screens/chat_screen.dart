import 'package:dailyetu/services/web_socket_service.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';
import 'ai_screen.dart';

class ChatScreen extends StatefulWidget
{
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
{
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _searchController = TextEditingController();

  void _showNewChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMenuItem(
              icon: Icons.chat_bubble_outline,
              title: 'Yeni Sohbet',
              subtitle: 'Biriyle özel sohbet başlat',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewChatScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.group_add,
              title: 'Yeni Grup',
              subtitle: 'Birden fazla kişiyle grup sohbeti oluştur',
              onTap: () {
                Navigator.pop(context);
                // TODO: Yeni grup oluşturma işlemi
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.send,
              title: 'Toplu Mesaj',
              subtitle: 'Birden fazla kişiye aynı anda mesaj gönder',
              onTap: () {
                Navigator.pop(context);
                // TODO: Toplu mesaj gönderme işlemi
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteChatDialog(String otherUsername) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Sohbeti Sil',
          style: TextStyle(color: _primaryColor),
        ),
        content: const Text(
          'Bu sohbeti silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: _primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              
              final result = await ApiService.deleteChat(otherUsername);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose()
  {
    _searchController.dispose();
    super.dispose();
  }

  @override
void initState() {
  super.initState();
  // WebSocket bağlantısını başlat
  WebSocketService().connect();
}

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Mesajlarda ara...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: _primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            style: TextStyle(color: _primaryColor),
            cursorColor: _primaryColor,
            onChanged: (value)
            {
              setState(() {});
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatMenu,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.edit,
          color: _primaryColor,
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService.getChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
            child: CircularProgressIndicator(color: Colors.white),
            );
          }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bir hata oluştu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Yeniden yükleme
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryColor,
                  ),
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          );
        }
        
        final chats = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.isEmpty ? 1 : chats.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // ETÜ AI Asistan
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        child: Image.asset(
                          'assets/icons/ai.png',
                          width: 50,
                          height: 50,
                        )
                      ),
                      title: const Text(
                        'ETU AI Asistan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        'Her zaman yardıma hazır',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

            // Eğer sohbet listesi boşsa ve index 0'dan büyükse (ki bu durumda olmamalı)
            // veya sohbet listesi boş değilse ve normal sohbetleri gösteriyorsak
            if (chats.isEmpty) {
              // ETÜ Asistan'dan sonra boş liste durumunda mesaj göster
              if (index == 1) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white.withOpacity(0.7),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz başka sohbet yok',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Yeni bir sohbet başlatmak için + butonuna tıklayın',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink(); // Boş widget
            }

              final chat = chats[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          otherUsername: chat['otherUsername'],
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showDeleteChatDialog(chat['otherUsername']),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.getUserProfileByUsername(chat['otherUsername']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!['success'] == true) {
                          final profilResmi = snapshot.data!['data']['profilResmi'];
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profilResmi != null ? NetworkImage(profilResmi) : null,
                            child: profilResmi == null
                                ? Text(
                                    chat['otherUsername'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          );
                        }
                        return CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            chat['otherUsername'][0].toUpperCase(),
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      chat['otherUsername'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMessageTime(chat['lastMessageTime']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatMessageTime(String lastMessageTime) {
    try {
      final messageDateTime = DateTime.parse(lastMessageTime).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(messageDateTime.year, messageDateTime.month, messageDateTime.day);

      if (messageDate == today) {
        // Bugün için saat:dakika
        return '${messageDateTime.hour.toString().padLeft(2, '0')}:${messageDateTime.minute.toString().padLeft(2, '0')}';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        // Dün
        return 'Dün';
      } else if (messageDate.year == now.year) {
        // Bu yıl içinde ise gün.ay
        return '${messageDateTime.day.toString().padLeft(2, '0')}.${messageDateTime.month.toString().padLeft(2, '0')}';
      } else {
        // Geçmiş yıllar için gün.ay.yıl
        return '${messageDateTime.day.toString().padLeft(2, '0')}.${messageDateTime.month.toString().padLeft(2, '0')}.${messageDateTime.year}';
      }
    } catch (e) {
      print('Tarih formatı hatası: $e');
      return '';
    }
  }
} 