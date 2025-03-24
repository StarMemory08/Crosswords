import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // import Google Fonts
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ไม่ใช้ backgroundColor เพราะเราจะใช้ภาพพื้นหลัง
      body: Stack(
        children: [
          // 1. ภาพพื้นหลัง (ใช้ภาพเดียวกับหน้า HomePage)
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 2. เนื้อหาหน้า login
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
                child: Column(
                  children: [
                    // หัวเรื่องของแอป (ใช้ Google Fonts และสีเหมือนหน้า HomePage)
                    Text(
                      "CROSSWORD ADVENTURE",
                      style: GoogleFonts.cinzel(
                        textStyle: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            Shadow(
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                              color: Color.fromARGB(96, 255, 255, 255),
                            ),
                          ],
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40.0),
                    // กล่องสำหรับแบบฟอร์มลงชื่อเข้าใช้
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4B5).withOpacity(0.9), // ปรับให้โปร่งเล็กน้อย
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      width: 350,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16.0),
                          const Text(
                            'ลงชื่อเข้าใช้',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // TextFormField สำหรับอีเมล
                                TextFormField(
                                  focusNode: _emailFocus,
                                  decoration: InputDecoration(
                                    labelText: 'อีเมล',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                                  onChanged: (value) {
                                    _email = value;
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !value.contains('@')) {
                                      return 'กรุณากรอกอีเมลที่ถูกต้อง';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                // TextFormField สำหรับรหัสผ่าน
                                TextFormField(
                                  focusNode: _passwordFocus,
                                  decoration: InputDecoration(
                                    labelText: 'รหัสผ่าน',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  obscureText: true,
                                  onChanged: (value) {
                                    _password = value;
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty || value.length < 8) {
                                      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                // ปุ่มสำหรับ "สร้างบัญชีใหม่" และ "ลืมรหัสผ่าน"
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/register');
                                      },
                                      child: const Text(
                                        'สร้างบัญชีใหม่',
                                        style: TextStyle(color: Colors.brown),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/forgot_password');
                                      },
                                      child: const Text(
                                        'ลืมรหัสผ่าน',
                                        style: TextStyle(color: Colors.brown),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                // ปุ่ม "เข้าสู่ระบบ" (ใช้สไตล์คล้ายกับหน้า HomePage)
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 255, 230, 162),
                                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: const Text(
                                    'เข้าสู่ระบบ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                // ปุ่ม "ผู้เยี่ยมชม"
                                OutlinedButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.clear(); // ✅ เคลียร์ข้อมูลผู้ใช้ทั้งหมด
                                    print("✅ ล้าง SharedPreferences สำเร็จ");
                                    await prefs.setBool("is_guest", true); // ✅ ตั้งค่าเป็น Guest Mode
                                    Navigator.pushNamed(context, '/home');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                                    side: const BorderSide(color: Colors.brown),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: const Text(
                                    'ผู้เยี่ยมชม',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    try {
      final url = Uri.parse('http://192.168.1.38:8000/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _email!.trim(),
          "password": _password!.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ Login Success: ${responseData["user_id"]}");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", responseData["user_id"]);
        await prefs.setBool("is_guest", false); // ✅ ออกจากโหมด Guest
        print("✅ เปลี่ยน is_guest เป็น false");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
        );

        Navigator.pushNamed(context, '/home');
      } else {
        print("❌ Login Failed: ${responseData["detail"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${responseData["detail"]}')),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
      );
    }
  }
}




}
