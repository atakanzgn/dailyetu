import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TextPostScreen extends StatefulWidget {
  const TextPostScreen({super.key});

  @override
  State<TextPostScreen> createState() => _TextPostScreenState();
}

class _TextPostScreenState extends State<TextPostScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sharePost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir şeyler yazın'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.createTextPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gönderi paylaşıldı'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
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
          'Yazı Paylaş',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _sharePost,
                  child: const Text(
                    'Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Başlık (isteğe bağlı)',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height - 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Düşüncelerinizi paylaşın...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 16,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 