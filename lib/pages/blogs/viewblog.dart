import 'dart:io';
import 'package:blogsite/entities/blogs.dart';
import 'package:blogsite/entities/comments.dart';
import 'package:blogsite/services/blogService.dart';
import 'package:blogsite/services/commentservice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewBlog extends StatefulWidget {
  final int? blogId;
  const ViewBlog({super.key, required this.blogId});

  @override
  State<ViewBlog> createState() => _ViewBlogState();
}

class _ViewBlogState extends State<ViewBlog> {
  int get blogId => widget.blogId!;

  final Blogservice _blogService = Blogservice();
  final Commentservice _commentService = Commentservice();

  Blogs? _blog;
  List<Comments> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final TextEditingController _commentController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  // For editing comments
  int? _editingCommentId;
  final TextEditingController _editCommentController = TextEditingController();
  File? _editImageFile;
  Uint8List? _editImageBytes;
  String? _editCurrentImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchBlogAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlogAndComments() async {
    setState(() => _isLoading = true);

    try {
      final blog = await _blogService.viewBlog(blogId);
      final comments = await _commentService.fetchComments(blogId);

      setState(() {
        _blog = blog;
        _comments = comments;
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

  Future<void> _pickImage({bool isEdit = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isEdit) {
          _editImageBytes = bytes;
          _editImageFile = null;
        } else {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
        }
      });
    } else {
      setState(() {
        if (isEdit) {
          _editImageFile = File(image.path);
          _editImageBytes = null;
        } else {
          _selectedImageFile = File(image.path);
          _selectedImageBytes = null;
        }
      });
    }
  }

  Future<String?> _uploadImage({File? imageFile, Uint8List? imageBytes}) async {
    if (imageFile == null && imageBytes == null) {
      return null;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'comments/$fileName';

      if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('blog-images')
            .uploadBinary(filePath, imageBytes!);
      } else {
        await Supabase.instance.client.storage
            .from('blog-images')
            .upload(filePath, imageFile!);
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        imageUrl = await _uploadImage(
          imageFile: _selectedImageFile,
          imageBytes: _selectedImageBytes,
        );
      }

      final comment = Comments(
        id: 0,
        blog_id: blogId,
        comment: _commentController.text.trim(),
        image_url: imageUrl,
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
        user_id: currentUserId,
        username: '',
        profile_image: null,
      );

      await _commentService.addComment(comment);

      _commentController.clear();
      setState(() {
        _selectedImageFile = null;
        _selectedImageBytes = null;
      });

      await _fetchBlogAndComments();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment added!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateComment(int commentId) async {
    if (_editCommentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_editImageFile != null || _editImageBytes != null) {
        imageUrl = await _uploadImage(
          imageFile: _editImageFile,
          imageBytes: _editImageBytes,
        );
      }

      await _commentService.updateComment(
        commentId,
        _editCommentController.text.trim(),
        imageUrl ?? _editCurrentImageUrl ?? '',
      );

      setState(() {
        _editingCommentId = null;
        _editCommentController.clear();
        _editImageFile = null;
        _editImageBytes = null;
        _editCurrentImageUrl = null;
      });

      await _fetchBlogAndComments();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating comment: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _commentService.deleteComment(commentId);
        await _fetchBlogAndComments();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Comment deleted!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
        }
      }
    }
  }

  void _startEditingComment(Comments comment) {
    setState(() {
      _editingCommentId = comment.id;
      _editCommentController.text = comment.comment;
      _editCurrentImageUrl = comment.image_url;
      _editImageFile = null;
      _editImageBytes = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCommentId = null;
      _editCommentController.clear();
      _editImageFile = null;
      _editImageBytes = null;
      _editCurrentImageUrl = null;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blog header
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _blog!.profile_images != null
                        ? NetworkImage(_blog!.profile_images!)
                        : null,
                    child: _blog!.profile_images == null
                        ? Text(_blog!.username[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _blog!.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(_blog!.created_at),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _blog!.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Image
              if (_blog!.image_url.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _blog!.image_url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              // Content
              Text(
                _blog!.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),

              // Comments section
              Text(
                'Comments (${_comments.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Add comment
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: () => _pickImage(isEdit: false),
                          ),
                          if (_selectedImageFile != null ||
                              _selectedImageBytes != null)
                            const Text('Image selected'),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _addComment,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Post'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comments list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final isOwner = comment.user_id == currentUserId;
                  final isEditing = _editingCommentId == comment.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    comment.profile_image != null &&
                                        comment.profile_image!.isNotEmpty
                                    ? NetworkImage(comment.profile_image!)
                                    : null,
                                child:
                                    comment.profile_image == null ||
                                        comment.profile_image!.isEmpty
                                    ? Text(comment.username[0].toUpperCase())
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(comment.created_at),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (isOwner && !isEditing) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      _startEditingComment(comment),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => _deleteComment(comment.id),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (isEditing)
                            Column(
                              children: [
                                TextField(
                                  controller: _editCommentController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.image),
                                      onPressed: () => _pickImage(isEdit: true),
                                    ),
                                    if (_editImageFile != null ||
                                        _editImageBytes != null)
                                      const Text('New image selected'),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _cancelEditing,
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _updateComment(comment.id),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Update'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else ...[
                            Text(comment.comment),
                            if (comment.image_url != null &&
                                comment.image_url!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  comment.image_url!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],

                          if (comment.created_at != comment.updated_at &&
                              !isEditing)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'edited ${_formatDate(comment.updated_at)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
