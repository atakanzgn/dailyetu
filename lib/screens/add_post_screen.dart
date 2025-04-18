import 'package:flutter/material.dart';
import 'text_post_screen.dart';
import 'photo_post_screen.dart';

class AddPostScreen extends StatelessWidget {
  const AddPostScreen({super.key});

  static const Color _primaryColor = Color(0xFF6B7FCE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Yeni Gönderi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPostOption(
              context,
              icon: Icons.photo_camera,
              title: 'Fotoğraf Paylaş',
              subtitle: 'Galeriden fotoğraf seç veya yeni fotoğraf çek',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoPostScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPostOption(
              context,
              icon: Icons.text_fields,
              title: 'Yazı Paylaş',
              subtitle: 'Düşüncelerini paylaş',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TextPostScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPostOption(
              context,
              icon: Icons.auto_stories,
              title: 'Hikaye Paylaş',
              subtitle: '24 saat görünen hikaye paylaş',
              color: Colors.purple,
              onTap: () {
                // TODO: Hikaye paylaşma işlemi
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
      ),
    );
  }
} 