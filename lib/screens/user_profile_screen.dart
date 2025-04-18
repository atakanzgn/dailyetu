import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _userPosts = [];
  int _postCount = 0;
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;
  bool _isLoading = true;
  bool _isFollowing = false;
  Map<int, int> _likeCounts = {};
  Map<int, bool> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Profil bilgilerini al
      final profileResult = await ApiService.getUserProfileByUsername(widget.username);
      
      if (profileResult['success']) {
        setState(() {
          _userProfile = profileResult['data'];
        });
      }

      // Paylaşımları al
      final postsResult = await ApiService.getUserPosts(widget.username);

      if (postsResult['success']) {
        setState(() {
          _userPosts = postsResult['posts'];
        });
        // Her post için beğeni sayısını ve beğeni durumunu al
        for (var post in _userPosts) {
          _loadLikeCount(post['id']);
          _checkLikeStatus(post['id']);
        }
      }

      // Gönderi sayısını al
      final countResult = await ApiService.getUserPostCount(widget.username);

      if (countResult['success']) {
        setState(() {
          _postCount = countResult['count'];
        });
      }

      // Takipçi sayılarını al
      final followResult = await ApiService.getFollowCounts(widget.username);

      if (followResult['success']) {
        setState(() {
          _takipciSayisi = followResult['data']['takipci'] ?? 0;
          _takipEdilenSayisi = followResult['data']['takipEdilen'] ?? 0;
        });
      }

      // Takip durumunu kontrol et
      final followStatus = await ApiService.checkFollowStatus(widget.username);
      if (followStatus['success']) {
        setState(() {
          _isFollowing = followStatus['isFollowing'];
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
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
    } catch (e) {
      print('Beğeni durumu kontrol edilirken hata: $e');
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

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _primaryColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: Colors.white,
        backgroundColor: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _userProfile?['profilResmi'] != null
                    ? NetworkImage(_userProfile!['profilResmi'])
                    : null,
                child: _userProfile?['profilResmi'] == null
                    ? const Icon(Icons.person, size: 50, color: _primaryColor)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
Center(
  child: ElevatedButton.icon(
    onPressed: () async {
      try {
        Map<String, dynamic> result;
        
        // Buton tıklandığında önce UI'ı güncelle (daha iyi kullanıcı deneyimi için)
        setState(() {
          _isLoading = true; // İşlem sırasında yükleniyor göster
        });
        
        if (_isFollowing) {
          // Takipten çık
          result = await ApiService.unfollowUser(widget.username);
        } else {
          // Takip et
          result = await ApiService.followUser(widget.username);
        }
        
        if (mounted) {
          // İşlem sonucunu göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: result['success'] ? Colors.green : Colors.red,
            ),
          );
          
          if (result['success']) {
            // İşlem başarılıysa, takip durumunu güncelle
            // Ancak API'den gerçek durumu tekrar kontrol et
            final followStatus = await ApiService.checkFollowStatus(widget.username);
            
            setState(() {
              _isFollowing = followStatus['success'] ? followStatus['isFollowing'] : !_isFollowing;
              _takipciSayisi = _isFollowing ? _takipciSayisi + 1 : _takipciSayisi - 1;
              _isLoading = false;
            });
          } else {
            // İşlem başarısızsa, yükleniyor durumunu kapat
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    },
    icon: _isLoading 
        ? const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 2,
            )
          )
        : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
    label: Text(_isLoading ? 'İşleniyor...' : (_isFollowing ? 'Takipten Çık' : 'Takip Et')),
    style: ElevatedButton.styleFrom(
      foregroundColor: _primaryColor,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  ),
),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Gönderi', '$_postCount'),
                    _buildStatColumn('Takipçi', '$_takipciSayisi'),
                    _buildStatColumn('Takip', '$_takipEdilenSayisi'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.text_fields)),
                  Tab(icon: Icon(Icons.event)),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsGrid(),
                    _buildTextPosts(),
                    _buildEventPosts(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    final photoPosts = _userPosts.where((post) => post['type'] == 'photo').toList();

    if (photoPosts.isEmpty) {
      return const Center(
        child: Text(
          'Henüz paylaşım yapmadı',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photoPosts.length,
      itemBuilder: (context, index) {
        final post = photoPosts[index];
        return GestureDetector(
          onTap: () => _showPostDetail(post),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(post['gorsel']),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPostDetail(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı bilgileri
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primaryColor,
                    backgroundImage: _userProfile?['profilResmi'] != null
                        ? NetworkImage(_userProfile!['profilResmi'])
                        : null,
                    child: _userProfile?['profilResmi'] == null
                        ? Text(
                            _userProfile?['username']?[0].toUpperCase() ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    '@${_userProfile?['username'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _formatDate(DateTime.parse(post['olusturulmaTarihi'])),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Fotoğraf
                if (post['gorsel'] != null)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post['gorsel'],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                // İçerik
                if (post['icerik'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      post['icerik'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                // Etiketler
                if (post['etiketler'] != null && (post['etiketler'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const Divider(height: 1),
                // Etkileşim butonları
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
                        onPressed: () {
                          _toggleLike(post['id']);
                          setState(() {}); // Dialog içindeki state'i güncelle
                        },
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
                          // TODO: Yorum yapma
                        },
                      ),
                      Text(
                        '0', // TODO: Yorum sayısı
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
                          // TODO: Paylaşma işlemi
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPosts() {
    final textPosts = _userPosts.where((post) => post['type'] == 'text').toList();

    if (textPosts.isEmpty) {
      return const Center(
        child: Text(
          'Henüz paylaşım yapmadı',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: textPosts.length,
      itemBuilder: (context, index) {
        final post = textPosts[index];
        return GestureDetector(
          onTap: () => _showPostDetail(post),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post['baslik'] != null && post['baslik'].isNotEmpty)
                    Text(
                      post['baslik'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (post['baslik'] != null && post['baslik'].isNotEmpty)
                    const SizedBox(height: 8),
                  Text(
                    post['icerik'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(DateTime.parse(post['olusturulmaTarihi'])),
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
  }

  Widget _buildEventPosts() {
    return const Center(
      child: Text(
        'Henüz paylaşım yapmadı',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
} 