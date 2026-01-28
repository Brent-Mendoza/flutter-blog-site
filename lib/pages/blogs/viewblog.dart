import 'package:flutter/material.dart';

class ViewBlog extends StatefulWidget {
  final int? blogId;
  const ViewBlog({super.key, required this.blogId});

  @override
  State<ViewBlog> createState() => _ViewBlogState();
}

class _ViewBlogState extends State<ViewBlog> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("View Blog"));
  }
}
