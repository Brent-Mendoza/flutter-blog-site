import 'dart:io';
import 'dart:typed_data';
import 'package:blogsite/pages/blog_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String username = "";
  String? profileImage;
  bool loading = false;
  bool updating = false;

  File? _selectedImageFile; // For mobile
  Uint8List? _selectedImageBytes; // For web

  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
          username = user["username"] ?? "";
          profileImage = user["profileImage"];
          _usernameController.text = username;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
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
        _selectedImageFile = null; // Clear the other one
      });
    } else {
      setState(() {
        _selectedImageFile = File(image.path);
        _selectedImageBytes = null; // Clear the other one
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

  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    setState(() {
      updating = true;
    });

    try {
      String? newImageUrl = profileImage;

      // Upload new image if selected
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        newImageUrl = await _uploadImage();
      }

      // Update profile in database
      await Supabase.instance.client
          .from("profiles")
          .update({
            "username": _usernameController.text.trim(),
            if (newImageUrl != null) "profileImage": newImageUrl,
          })
          .eq("id", Supabase.instance.client.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated!')));

        // Clear selected images
        setState(() {
          _selectedImageFile = null;
          _selectedImageBytes = null;
        });

        // Refresh
        await _fetchUser();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update error: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return BlogLayout(child: Center(child: CircularProgressIndicator()));
    }

    // Image preview
    Widget imagePreview;
    if (_selectedImageBytes != null) {
      // Web - show selected image
      imagePreview = CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(_selectedImageBytes!),
      );
    } else if (_selectedImageFile != null) {
      // Mobile - show selected image
      imagePreview = CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImageFile!),
      );
    } else if (profileImage != null && profileImage!.isNotEmpty) {
      // Show existing profile image
      imagePreview = CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(profileImage!),
      );
    } else {
      // No image - show placeholder
      imagePreview = CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      );
    }

    return BlogLayout(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(onTap: _pickImage, child: imagePreview),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _pickImage,
                  child: Text('Change Profile Picture'),
                ),
                SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: updating ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B62FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: updating
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Updating...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            'Update Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
