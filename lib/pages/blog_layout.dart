import 'package:blogsite/pages/blogs/addblog.dart';
import 'package:blogsite/pages/blogs/blogpage.dart';
import 'package:blogsite/pages/blogs/profile.dart';
import 'package:blogsite/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogLayout extends StatefulWidget {
  final Widget child;

  const BlogLayout({super.key, required this.child});

  @override
  State<BlogLayout> createState() => _BlogLayoutState();
}

class _BlogLayoutState extends State<BlogLayout> {
  String username = "";
  String? profileImage = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchUser();
  }

  void _checkAuth() {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      });
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  Future<void> _fetchUser() async {
    setState(() {
      loading = true;
    });
    try {
      final user = await Supabase.instance.client
          .from("profiles")
          .select()
          .eq("id", Supabase.instance.client.auth.currentUser!.id)
          .single();

      setState(() {
        username = user["username"];
        profileImage = user["profileImage"];
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Simple Blog",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 20.0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10),
          child: IconButton(
            onPressed: () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Profile()),
                );
              }
            },
            icon: CircleAvatar(
              backgroundImage: profileImage != null && profileImage!.isNotEmpty
                  ? NetworkImage(profileImage!)
                  : null,
              backgroundColor: Colors.black,
              child: profileImage == null || profileImage!.isEmpty
                  ? Text(
                      username[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        leadingWidth: 60,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: _handleLogout,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.black),
                shape: WidgetStatePropertyAll(CircleBorder()),
                maximumSize: WidgetStatePropertyAll(Size(35, 35)),
                minimumSize: WidgetStatePropertyAll(Size(35, 35)),
              ),
              icon: Icon(Icons.logout, color: Colors.white),
              iconSize: 15,
            ),
          ),
        ],
      ),
      body: widget.child,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'create',
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogLayout(child: AddBlog()),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'home',
            child: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogLayout(child: BlogPage()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
