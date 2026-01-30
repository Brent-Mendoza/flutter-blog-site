class Comments {
  int id;
  int blog_id;
  String comment;
  String? image_url;
  DateTime created_at;
  DateTime updated_at;
  String user_id;
  String username;
  String? profile_image;

  Comments({
    required this.id,
    required this.blog_id,
    required this.comment,
    this.image_url,
    required this.created_at,
    required this.updated_at,
    required this.user_id,
    required this.username,
    this.profile_image,
  });

  factory Comments.fromMap(Map<String, dynamic> map) => Comments(
    id: map['id'],
    blog_id: map['blog_id'],
    comment: map['comment'],
    image_url: map['image_url'] ?? '',
    created_at: DateTime.parse(map['created_at']),
    updated_at: DateTime.parse(map['updated_at']),
    user_id: map['user_id'],
    username: map['profiles']['username'],
    profile_image: map['profiles']?['profile_image'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'blog_id': blog_id,
    'comment': comment,
    'image_url': image_url,
    'created_at': created_at.toIso8601String(),
    'updated_at': updated_at.toIso8601String(),
    'user_id': user_id,
  };
}
