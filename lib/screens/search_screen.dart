import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  final List<Map<String, dynamic>> _recentProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mevcut kullanıcının username'ini al
  String? _getCurrentUsername() {
    final currentUser = ApiService.getCurrentUser();
    return currentUser?['username'];
  }

  // Son profilleri yükleme fonksiyonu
  Future<void> _loadRecentProfiles() async {
    final username = _getCurrentUsername();
    if (username == null) return;

    final prefs = await SharedPreferences.getInstance();
    final recentProfilesJson = prefs.getString('recent_profiles_$username');
    if (recentProfilesJson != null) {
      final List<dynamic> decoded = jsonDecode(recentProfilesJson);
      setState(() {
        _recentProfiles.clear();
        _recentProfiles.addAll(decoded.cast<Map<String, dynamic>>());
      });
    }
  }

  // Son profilleri kaydetme fonksiyonu
  Future<void> _saveRecentProfiles() async {
    final username = _getCurrentUsername();
    if (username == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_profiles_$username', jsonEncode(_recentProfiles));
  }

  // Son profillerden kaldırma fonksiyonu
  void _removeProfile(int index) {
    setState(() {
      _recentProfiles.removeAt(index);
      _saveRecentProfiles();
    });
  }

  // Profil geçmişine ekleme fonksiyonu
  void _addToRecentProfiles(Map<String, dynamic> user) {
    setState(() {
      // Eğer kullanıcı zaten varsa, önce onu kaldır
      _recentProfiles.removeWhere((profile) => profile['username'] == user['username']);
      // Yeni profili listenin başına ekle
      _recentProfiles.insert(0, user);
      // Maksimum 5 profil tut
      if (_recentProfiles.length > 10) {
        _recentProfiles.removeLast();
      }
      _saveRecentProfiles();
    });
  }

  // Tüm profilleri temizleme fonksiyonu
  void _clearRecentProfiles() {
    setState(() {
      _recentProfiles.clear();
      _saveRecentProfiles();
    });
  }

  // Kullanıcı arama fonksiyonu
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(()
    {
      _isLoading = true;
      _errorMessage = '';
    });
  try{
  final result = await ApiService.searchUsers(query);
  if (mounted) {
    setState(() {
      _isLoading = false;
      if (result['success']) {
        String currentUsername = _getCurrentUsername() ?? '';
        // API'den dönen yanıt doğrudan bir liste olduğu için 'users' alanını kullanın
        _searchResults = List<Map<String, dynamic>>.from(result['users'])
            .where((user) => user['username'] != currentUsername)
            .toList();
      } else {
        _errorMessage = result['message'];
        _searchResults = [];
      }
    });
  }
} catch (e) {
  print('Arama hatası: $e'); // Hatayı konsola yazdırın
  if (mounted) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Arama yapılırken bir hata oluştu: $e';
      _searchResults = [];
    });
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
              hintText: 'Kullanıcı ara...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: _primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            style: TextStyle(color: _primaryColor),
            cursorColor: _primaryColor,
            onChanged: _searchUsers,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                )
              : _searchResults.isEmpty && _searchController.text.isEmpty
                  ? _buildRecentProfiles()
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Kullanıcı bulunamadı',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage: user['profilResmi'] != null
                                      ? NetworkImage(user['profilResmi'])
                                      : null,
                                  child: user['profilResmi'] == null
                                      ? Text(
                                          user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: TextStyle(
                                            color: _primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  '${user['ad'] ?? ''} ${user['soyad'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${user['username']?.toLowerCase() ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () {
                                  // Profili son ziyaret edilenlere ekle
                                  _addToRecentProfiles(user);
                                  // Profil sayfasına git
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                        username: user['username'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
    );
  }

  Widget _buildRecentProfiles() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Ziyaret Edilenler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_recentProfiles.isNotEmpty)
                TextButton(
                  onPressed: _clearRecentProfiles,
                  child: const Text(
                    'Tümünü Temizle',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _recentProfiles.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz profil ziyareti yok',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentProfiles.length,
                    itemBuilder: (context, index) {
                      final profile = _recentProfiles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: profile['profilResmi'] != null
                                ? NetworkImage(profile['profilResmi'])
                                : null,
                            child: profile['profilResmi'] == null
                                ? Text(
                                    profile['username']?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            '${profile['ad'] ?? ''} ${profile['soyad'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '@${profile['username']?.toLowerCase() ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () => _removeProfile(index),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                  username: profile['username'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 