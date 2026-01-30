import 'package:blogsite/entities/blogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Blogservice {
  final _db = Supabase.instance.client.from("blogs");

  Future<void> createBlog(Blogs blog) async {
    await _db.insert(blog.toMap());
  }

  Future<List<Blogs>> fetchBlogs(int page) async {
    final response = await _db
        .select('''
          id,
          title,
          content,
          user_id,
          image_url,
          created_at,
          updated_at,
          profiles:profiles!inner(username, profileImage),
          comments(count)
          ''')
        .range(page * 3, page * 3 + 2)
        .order('created_at', ascending: false);

    return response.map<Blogs>((e) => Blogs.fromMap(e)).toList();
  }

  Future<Blogs> fetchBlog(int id) async {
    final response = await _db
        .select('''
          id,
          title,
          content,
          image_url
          ''')
        .eq("id", id)
        .single();

    return Blogs.fromMapPartial(response);
  }

  Future<Blogs> viewBlog(int id) async {
    final response = await _db
        .select('''
          id,
          title,
          content,
          user_id,
          image_url,
          created_at,
          updated_at,
          profiles:profiles!inner(username, profileImage),
          comments(count)
          ''')
        .eq("id", id)
        .single();

    return Blogs.fromMap(response);
  }

  Future<void> updateBlog(
    int id,
    String title,
    String content,
    String imageUrl,
  ) async {
    final res = await _db
        .update({
          "title": title,
          "content": content,
          "image_url": imageUrl,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id)
        .select();

    if (res.isEmpty) {
      throw Exception('Blog not found.');
    }
  }

  Future<void> deleteBlog(int id) async {
    final res = await _db.delete().eq("id", id).select();

    if (res.isEmpty) {
      throw Exception('Blog not found or already deleted');
    }
  }
}
