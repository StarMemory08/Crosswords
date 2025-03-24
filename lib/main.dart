import 'package:crossword_pj/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crossword_pj/pages/login.dart';
import 'package:crossword_pj/pages/register.dart';
import 'package:crossword_pj/pages/forgot_password.dart';
import 'pages/home_page.dart';
import 'pages/rules_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await AudioService().playBackgroundMusic();
  try {
    
    await Firebase.initializeApp(); // ✅ ตรวจสอบ Firebase
    
    // ✅ ตรวจสอบการโหลด SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    print("✅ SharedPreferences loaded: user_id = $userId");

    runApp(CrosswordApp(isLoggedIn: userId != null));
  } catch (e) {
    print("❌ Error in main(): $e"); // ✅ แสดง Error ถ้ามีปัญหา
  }
}

class CrosswordApp extends StatelessWidget {
  final bool isLoggedIn;
  const CrosswordApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crossword Adventure',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'UncialAntiqua',
      ),
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/rules': (context) => const RulesPage(),
      },
    );
  }
}

// 📌 ฟังก์ชันสำหรับเรียก API ดึงคำศัพท์
Future<void> fetchMessage() async {
  try {
    final response = await http.get(Uri.parse('http://192.168.1.38:8000/words'));
    if (response.statusCode == 200) {
      print('✅ Response: ${response.body}');
    } else {
      print('❌ Failed to fetch data');
    }
  } catch (e) {
    print('❌ API Error: $e');
  }
}
