import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';
import 'user_profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ApiService.setNotificationScreenState(true);
    _loadNotifications();
  }

  @override
  void dispose() {
    ApiService.setNotificationScreenState(false);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Bildirimler yükleniyor...');
      final result = await ApiService.getNotifications();
      print('API yanıtı: $result');
      
      if (result['success'] && mounted) {
        if (result['notifications'] != null) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(result['notifications']);
          });
          print('Yüklenen bildirimler: $_notifications');
        } else {
          print('Bildirimler null geldi');
          setState(() {
            _notifications = [];
          });
        }
      } else {
        print('API hatası: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Bildirimler yüklenirken bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirimler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final result = await ApiService.deleteNotification(notificationId);
      if (result['success'] && mounted) {
        setState(() {
          _notifications.removeWhere((notification) => notification['id'] == notificationId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim silinirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      final result = await ApiService.deleteAllNotifications();
      if (result['success'] && mounted) {
        setState(() {
          _notifications.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirimler silinirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    IconData icon;
    Color iconColor;
    String message = notification['mesaj'];
    Widget? trailing;

    switch (notification['tur']) {
      case 'mesaj':
        icon = Icons.message;
        iconColor = Colors.blue;
        String messageContent = notification['mesaj'];
        String senderUsername = messageContent.split(" size mesaj gönderdi:")[0];
        
        trailing = TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  otherUsername: senderUsername,
                ),
              ),
            );
          },
          child: const Text(
            'Yanıtla',
            style: TextStyle(color: _primaryColor),
          ),
        );
        break;
      case 'begeni':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'takip':
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatDate(DateTime.parse(notification['tarih'])),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: trailing,
        onTap: () {
          if (notification['tur'] == 'begeni' || notification['tur'] == 'takip') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  username: notification['kullanici']['username'],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tüm Bildirimleri Sil'),
                    content: const Text('Tüm bildirimleri silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAllNotifications();
                        },
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: Colors.white,
              backgroundColor: _primaryColor,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz bildirim yok',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildNotificationItem(_notifications[index]),
                        );
                      },
                    ),
            ),
    );
  }
} 