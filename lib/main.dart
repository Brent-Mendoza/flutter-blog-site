import 'package:blogsite/pages/blog_layout.dart';
import 'package:blogsite/pages/blogs/blogpage.dart';
import 'package:blogsite/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final String url = dotenv.env['SUPABASE_URL'] ?? '';
  final String key = dotenv.env['SUPABASE_KEY'] ?? '';

  await Supabase.initialize(url: url, anonKey: key);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _session == null ? Login() : BlogLayout(child: BlogPage()),
    );
  }
}
