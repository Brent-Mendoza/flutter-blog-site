import 'dart:io';
import 'package:blogsite/entities/blogs.dart';
import 'package:blogsite/services/blogservice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditBlog extends StatefulWidget {
  final int? blogId;
  const EditBlog({super.key, required this.blogId});

  @override
  State<EditBlog> createState() => _EditBlogState();
}

class _EditBlogState extends State<EditBlog> {
  int get blogId => widget.blogId!;

  final Blogservice _blogservice = Blogservice();
  Blogs? _blog;
  bool _isLoading = true;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // Image handling
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _fetchBlog();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlog() async {
    try {
      final blog = await _blogservice.fetchBlog(blogId);
      setState(() {
        _blog = blog;
        _titleController.text = blog.title;
        _contentController.text = blog.content;
        _currentImageUrl = blog.image_url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading blog: $e')));
      }
    }
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

  Future<void> _updateBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new image if selected, otherwise use existing
      String? imageUrl;
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        imageUrl = await _uploadImage();
      }

      await _blogservice.updateBlog(
        blogId,
        _titleController.text.trim(),
        _contentController.text.trim(),
        imageUrl ?? _currentImageUrl ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating blog: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blog == null) {
      return const Center(child: Text('Blog not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
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
                            : _currentImageUrl != null &&
                                  _currentImageUrl!.isNotEmpty
                            ? Image.network(
                                _currentImageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
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

            // Update button
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBlog,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Blog'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
