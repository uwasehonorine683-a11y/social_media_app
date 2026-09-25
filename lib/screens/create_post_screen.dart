import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/post_service.dart';
import '../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  File? _selectedImage;
  bool _isPosting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _submit() async {
    final String text = _textController.text.trim();

    if (text.isEmpty && _selectedImage == null) {
      setState(() {
        _errorMessage = 'Please write something or add an image.';
      });
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'You must be signed in to post.';
      });
      return;
    }

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadPostImage(
          userId: user.uid,
          imageFile: _selectedImage!,
        );
      }

      await _postService.createPost(text: text, imageUrl: imageUrl);

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } on PostException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textController,
                maxLines: 6,
                enabled: !_isPosting,
                decoration: const InputDecoration(
                  hintText: 'What is on your mind?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      color: Colors.white,
                      onPressed: _isPosting
                          ? null
                          : () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isPosting ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedImage == null ? 'Add image' : 'Change image',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isPosting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
