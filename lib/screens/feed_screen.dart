import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_profile_screen.dart';
import 'notification_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  List<dynamic> _feedPosts = [];
  bool _isLoading = true;
  Map<int, int> _likeCounts = {};
  Map<int, bool> _likedPosts = {}; // Beğenilen gönderileri tutmak için yeni map

  @override
  void initState() {
    super.initState();
    _loadFeedPosts();
  }

  Future<void> _loadFeedPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getFeedPosts();
      if (result['success']) {
        setState(() {
          _feedPosts = result['posts'];
        });
        // Her post için beğeni sayısını ve beğeni durumunu al
        for (var post in _feedPosts) {
          _loadLikeCount(post['id']);
          _checkLikeStatus(post['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderiler yüklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLikeCount(int postId) async {
    try {
      final result = await ApiService.getLikeCount(postId);
      if (result['success'] && mounted) {
        setState(() {
          _likeCounts[postId] = result['count'];
        });
      }
    } catch (e) {
      print('Beğeni sayısı alınırken hata: $e');
    }
  }

  Future<void> _checkLikeStatus(int postId) async {
    try {
      final result = await ApiService.isPostLiked(postId);
      if (result['success'] && mounted) {
        setState(() {
          _likedPosts[postId] = result['isLiked'];
        });
      }
    }
    catch(e)
    {//
    }
  }

  Future<void> _toggleLike(int postId) async {
    try {
      final isLiked = _likedPosts[postId] ?? false;
      final result = isLiked 
          ? await ApiService.unlikePost(postId)
          : await ApiService.likePost(postId);

      if (result['success'] && mounted) {
        setState(() {
          _likedPosts[postId] = !isLiked;
          // Beğeni sayısını güncelle
          final currentCount = _likeCounts[postId] ?? 0;
          _likeCounts[postId] = isLiked ? currentCount - 1 : currentCount + 1;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Daily ETU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'PlaywriteAUSA',
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
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
              onRefresh: _loadFeedPosts,
              color: Colors.white,
              backgroundColor: _primaryColor,
              child: _feedPosts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 64,
                            color: Colors.white70,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Henüz bir paylaşım yok',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _feedPosts.length,
                      itemBuilder: (context, index) {
                        final post = _feedPosts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kullanıcı bilgileri
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                        username: post['kullanici']['username'],
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _primaryColor,
                                        backgroundImage: post['kullanici']['profilResmi'] != null
                                            ? NetworkImage(post['kullanici']['profilResmi'])
                                            : null,
                                        child: post['kullanici']['profilResmi'] == null
                                            ? Text(
                                                post['kullanici']['username'][0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '@${post['kullanici']['username']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${post['kullanici']['ad']} ${post['kullanici']['soyad']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(DateTime.parse(post['olusturulmaTarihi']).toLocal()),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Başlık (varsa)
                              if (post['baslik'] != null && post['baslik'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    post['baslik'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              // Fotoğraf (varsa)
                              if (post['type'] == 'photo' && post['gorsel'] != null)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 400,
                                  ),
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post['gorsel'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              // İçerik
                              if (post['icerik'] != null)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    post['icerik'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              // Etiketler
                              if (post['etiketler'] != null &&
                                  (post['etiketler'] as List).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (post['etiketler'] as List)
                                        .map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '#$tag',
                                                style: const TextStyle(
                                                  color: _primaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              // Etkileşim butonları
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _likedPosts[post['id']] ?? false
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _likedPosts[post['id']] ?? false
                                            ? _primaryColor
                                            : null,
                                      ),
                                      onPressed: () => _toggleLike(post['id']),
                                    ),
                                    Text(
                                      _likeCounts[post['id']]?.toString() ?? '0',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: Image.asset(
                                        'assets/icons/comment.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        // TODO: Yorum yapma sayfasına yönlendirilecek
                                      },
                                    ),
                                    Text(
                                      '0', // TODO: Yorum sayısı eklenecek
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Image.asset(
                                        'assets/icons/share.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        // TODO: Paylaşma işlemi eklenecek
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    try {
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
    } catch (e) {
      print('Tarih formatlanırken hata: $e');
      return 'Tarih bilinmiyor';
    }
  }
} 