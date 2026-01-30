import 'package:blogsite/pages/blog_layout.dart';
import 'package:blogsite/pages/blogs/editblog.dart';
import 'package:blogsite/pages/blogs/viewblog.dart';
import 'package:flutter/material.dart';
import 'package:blogsite/entities/blogs.dart';
import 'package:blogsite/services/blogservice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final Blogservice _blogService = Blogservice();
  final ScrollController _scrollController = ScrollController();

  final List<Blogs> _blogs = [];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchBlogs();
      }
    });
  }

  Future<void> _fetchBlogs() async {
    setState(() => _isLoading = true);

    final newBlogs = await _blogService.fetchBlogs(_page);

    if (newBlogs.isEmpty) {
      _hasMore = false;
    } else {
      _page++;
      _blogs.addAll(newBlogs);
    }

    setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Blog'),
        content: const Text('Are you sure you want to delete this blog?'),
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
      await _blogService.deleteBlog(id);
      setState(() => _blogs.removeWhere((b) => b.id == id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Blog deleted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _blogs.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _blogs.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final blog = _blogs[index];
        final isOwner = blog.user_id == currentUserId;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BlogLayout(child: ViewBlog(blogId: blog.id)),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// USER ROW
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: blog.profile_images != null
                            ? NetworkImage(blog.profile_images as String)
                            : null,
                        child: blog.profile_images == null
                            ? Text(blog.username[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        blog.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isOwner) ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlogLayout(
                                  child: EditBlog(blogId: blog.id),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(blog.id!),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// TITLE
                  Text(
                    blog.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 8),

                  /// IMAGE
                  if (blog.image_url.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 800,
                        ), // Adjust as needed
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            blog.image_url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  /// DESCRIPTION
                  Text(
                    blog.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  /// META
                  Row(
                    children: [
                      Text('${blog.commentCount} comments'),
                      const Spacer(),
                      Column(
                        children: [
                          Text(_formatDate(blog.created_at)),
                          if (blog.created_at != blog.updated_at)
                            Text(
                              ' • edited ${_formatDate(blog.updated_at)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
