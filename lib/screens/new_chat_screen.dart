import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getCurrentUsername() {
    final currentUser = ApiService.getCurrentUser();
    return currentUser?['username'];
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.searchUsers(query);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            String currentUsername = _getCurrentUsername() ?? '';
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Arama yapılırken bir hata oluştu';
          _searchResults = [];
        });
      }
    }
  }

  void _startChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          otherUsername: user['username'],
        ),
      ),
    );
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
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
                  ? const Center(
                      child: Text(
                        'Sohbet başlatmak için kullanıcı arayın',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    )
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
                                onTap: () => _startChat(user),
                              ),
                            );
                          },
                        ),
    );
  }
} 