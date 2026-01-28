import 'package:flutter/material.dart';

class EditBlog extends StatefulWidget {
  final int? blogId;
  const EditBlog({super.key, required this.blogId});

  @override
  State<EditBlog> createState() => _EditBlogState();
}

class _EditBlogState extends State<EditBlog> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
