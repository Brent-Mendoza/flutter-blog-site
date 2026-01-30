import 'package:blogsite/entities/comments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Commentservice {
  final _db = Supabase.instance.client.from('comments');

  Future<void> addComment(Comments comment) async {
    await _db.insert(comment.toMap());
  }

  Future<List<Comments>> fetchComments(int blogId) async {
    final response = await _db
        .select('''
      id,
      blog_id, comment, created_at, updated_at, image_url, user_id, profiles:profiles!inner(username, profileImage)
      ''')
        .eq("blog_id", blogId)
        .order("created_at", ascending: false);

    return response.map<Comments>((e) => Comments.fromMap(e)).toList();
  }

  Future<void> deleteComment(int id) async {
    final res = await _db.delete().eq("id", id).select();

    if (res.isEmpty) {
      throw Exception('Comment not found or already deleted');
    }
  }

  Future<void> updateComment(int id, String comment, String imageUrl) async {
    final res = await _db
        .update({
          "comment": comment,
          "image_url": imageUrl,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id)
        .select();

    if (res.isEmpty) {
      throw Exception('Comment not found.');
    }
  }
}
