import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PhotoPostScreen extends StatefulWidget {
  const PhotoPostScreen({super.key});

  @override
  State<PhotoPostScreen> createState() => _PhotoPostScreenState();
}

class _PhotoPostScreenState extends State<PhotoPostScreen> {
  static const Color _primaryColor = Color(0xFF6B7FCE);
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _sharePost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fotoğraf seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.createPhotoPost(
        photoFile: _selectedImage!,
        content: _contentController.text.trim(),
        tags: _tags,
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
          'Fotoğraf Paylaş',
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: _primaryColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Fotoğraf Seç',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Bir açıklama ekleyin...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 16,
                ),
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Etiket ekle',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) => Chip(
                backgroundColor: Colors.white,
                label: Text(
                  tag,
                  style: TextStyle(color: _primaryColor),
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                ),
                onDeleted: () => _removeTag(tag),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 