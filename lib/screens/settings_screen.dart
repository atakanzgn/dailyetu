import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _primaryColor = Color(0xFF6B7FCE);

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Hesabı Sil',
          style: TextStyle(color: _primaryColor),
        ),
        content: const Text(
          'Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
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
              final result = await ApiService.deleteAccount();
              if (context.mounted) {
                Navigator.pop(context); // Dialog'u kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
                if (result['success']) {
                  // Hesap silindiyse login ekranına yönlendir
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
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
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _buildSettingSection(
            'Hesap',
            [
              _buildSettingTile(
                icon: Icons.delete_forever,
                title: 'Hesabımı Sil',
                subtitle: 'Hesabınızı kalıcı olarak silin',
                iconColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 