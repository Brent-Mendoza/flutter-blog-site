class Blogs {
  int? id;
  String title;
  String content;
  DateTime created_at;
  DateTime updated_at;
  String user_id;
  String image_url;
  int commentCount;
  String username;
  String? profile_images;

  Blogs({
    this.id,
    required this.title,
    required this.content,
    required this.user_id,
    required this.image_url,
    required this.created_at,
    required this.updated_at,
    required this.commentCount,
    required this.username,
    required this.profile_images,
  });

  factory Blogs.fromMap(Map<String, dynamic> map) {
    return Blogs(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      user_id: map['user_id'],
      image_url: map['image_url'] ?? '',
      created_at: DateTime.parse(map['created_at']),
      updated_at: DateTime.parse(map['updated_at']),
      commentCount: map['comments'][0]['count'],
      username: map['profiles']['username'],
      profile_images: map['profiles']?['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'created_at': created_at,
      'updated_at': updated_at,
      'user_id': user_id,
      'image_url': image_url,
    };
  }
}
