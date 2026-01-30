import 'dart:io';
import 'package:blogsite/entities/blogs.dart';
import 'package:blogsite/pages/blog_layout.dart';
import 'package:blogsite/pages/blogs/blogpage.dart';
import 'package:blogsite/services/blogService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBlog extends StatefulWidget {
  const AddBlog({super.key});

  @override
  State<AddBlog> createState() => _AddBlogState();
}

class _AddBlogState extends State<AddBlog> {
  final Blogservice _blogservice = Blogservice();
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Image handling
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFile = null;
      });
    } else {
      setState(() {
        _selectedImageFile = File(image.path);
        _selectedImageBytes = null;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
      return null;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'blog/$fileName';

      if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('blog-images')
            .uploadBinary(filePath, _selectedImageBytes!);
      } else {
        await Supabase.instance.client.storage
            .from('blog-images')
            .upload(filePath, _selectedImageFile!);
      }

      final imageUrl = Supabase.instance.client.storage
          .from('blog-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $error')));
      }
      return null;
    }
  }

  Future<void> _createBlog() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageFile == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image
      final imageUrl = await _uploadImage();

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Create blog
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final blog = Blogs(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        user_id: userId,
        image_url: imageUrl,
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
        commentCount: 0,
        username: '',
        profile_images: null,
      );

      await _blogservice.createBlog(blog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog created successfully!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogLayout(child: BlogPage()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating blog: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _selectedImageFile != null
                            ? Image.file(
                                _selectedImageFile!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 50),
                                    SizedBox(height: 8),
                                    Text('Tap to add image'),
                                  ],
                                ),
                              ),
                      ),
                      if (_selectedImageBytes != null ||
                          _selectedImageFile != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title field
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content field
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create button
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBlog,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Blog'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
