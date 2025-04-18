import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _userPosts = [];
  int _postCount = 0;
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;
  bool _isLoading = true;
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _biyografiController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adController.dispose();
    _soyadController.dispose();
    _biyografiController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ApiService.getCurrentUser();
      if (currentUser == null) {
        return;
      }

      // Profil bilgilerini al
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success']) {
        setState(() {
          _userProfile = profileResult['data'];
        });
      }

      // Paylaşımları al
      final postsResult = await ApiService.getUserPosts(currentUser['username']);
      if (postsResult['success']) {
        setState(() {
          _userPosts = postsResult['posts'];
        });
      }

      // Gönderi sayısını al
      final countResult = await ApiService.getUserPostCount(currentUser['username']);
      if (countResult['success']) {
        setState(() {
          _postCount = countResult['count'];
        });
      }

      // Takipçi sayılarını al
      final followResult = await ApiService.getFollowCounts(currentUser['username']);
      if (followResult['success']) {
        setState(() {
          _takipciSayisi = followResult['data']['takipci'] ?? 0;
          _takipEdilenSayisi = followResult['data']['takipEdilen'] ?? 0;
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (image != null) {
      final result = await ApiService.uploadProfilePhoto(File(image.path));
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserData(); // Profili yeniden yükle
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditDialog() {
    _adController.text = _userProfile?['ad'] ?? '';
    _soyadController.text = _userProfile?['soyad'] ?? '';
    _biyografiController.text = _userProfile?['biyografi'] ?? '';
    _usernameController.text = _userProfile?['username'] ?? '';
    _usernameError = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Profili Düzenle',
            style: TextStyle(color: _primaryColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    labelStyle: const TextStyle(color: Colors.grey),
                    errorText: _usernameError,
                  ),
                  style: const TextStyle(color: _primaryColor),
                  onChanged: (value) {
                    setState(() {
                      if (value.length < 3) {
                        _usernameError = 'Kullanıcı adı en az 3 karakter olmalıdır';
                      } else {
                        _usernameError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: _primaryColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _soyadController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: _primaryColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _biyografiController,
                  decoration: const InputDecoration(
                    labelText: 'Biyografi',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: _primaryColor),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: _primaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Kullanıcı adı değiştirildi mi kontrol et
                final newUsername = _usernameController.text;
                final oldUsername = _userProfile?['username'];
                final username = newUsername != oldUsername ? newUsername : null;

                // Kullanıcı adı uzunluk kontrolü
                if (username != null && username.length < 3) {
                  setState(() {
                    _usernameError = 'Kullanıcı adı en az 3 karakter olmalıdır';
                  });
                  return;
                }

                final result = await ApiService.updateProfile(
                  ad: _adController.text,
                  soyad: _soyadController.text,
                  biyografi: _biyografiController.text,
                  username: username,
                );

                if (mounted) {
                  if (result['success']) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUserData(); // Profili yeniden yükle
                  } else {
                    // Eğer hata kullanıcı adıyla ilgiliyse, hata mesajını göster
                    if (result['message'].toString().contains('kullanıcı adı')) {
                      setState(() {
                        _usernameError = result['message'];
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text(
                'Kaydet',
                style: TextStyle(color: _primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
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
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'ayarlar',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: _primaryColor),
                    SizedBox(width: 8),
                    Text('Ayarlar', style: TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'cikis',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: _primaryColor),
                    SizedBox(width: 8),
                    Text('Çıkış Yap', style: TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) async {
              if (value == 'cikis') {
                await ApiService.clearToken();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } else if (value == 'ayarlar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            },
          ),
        ],
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
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  children: [
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primaryColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
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
                            child: Text(
                              '${_userProfile?['ad'] ?? ''} ${_userProfile?['soyad'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '@${_userProfile?['username']?.toLowerCase() ?? 'username'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: _showEditDialog,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userProfile?['biyografi']?.isEmpty ?? true
                                ? 'Henüz bir biyografi eklenmemiş'
                                : _userProfile?['biyografi'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                height: MediaQuery.of(context).size.height - 400, // Tahmini bir yükseklik
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
    print('Tüm gönderiler: $_userPosts'); // Debug log
    final photoPosts = _userPosts.where((post) => post['type'] == 'photo').toList();
    print('Fotoğraf gönderileri: $photoPosts'); // Debug log

    if (photoPosts.isEmpty) {
      return const Center(
        child: Text(
          'Henüz paylaşım yapmadınız',
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
        print('Fotoğraf post $index: $post'); // Debug log
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(post['gorsel']),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextPosts() {
    print('Tüm gönderiler: $_userPosts'); // Debug log
    final textPosts = _userPosts.where((post) => post['type'] == 'text').toList();
    print('Metin gönderileri: $textPosts'); // Debug log

    if (textPosts.isEmpty) {
      return const Center(
        child: Text(
          'Henüz paylaşım yapmadınız',
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
        print('Metin post $index: $post'); // Debug log
        return Card(
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
                  DateTime.parse(post['olusturulmaTarihi']).toLocal().toString().split('.')[0],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventPosts() {
    return const Center(
      child: Text(
        'Henüz paylaşım yapmadınız',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
    );
  }
} 