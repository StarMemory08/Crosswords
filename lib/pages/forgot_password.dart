import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final String apiBaseUrl = "http://172.23.226.226:8000"; // เปลี่ยนเป็น API ของคุณ
  bool _isLoading = false; // ✅ ใช้สำหรับแสดงโหลด

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    print("📌 [DEBUG] Sending email: $email");

    if (email.isEmpty || !email.contains('@')) {
      _showSnackbar("กรุณากรอกอีเมลที่ถูกต้อง");
      return;
    }

    setState(() {
      _isLoading = true; // ✅ แสดงสถานะโหลด
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/request_password_reset'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      print("📌 [DEBUG] API Response: ${response.statusCode} - ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["success"] == true) {
        _showSnackbar("ลิงก์รีเซ็ตรหัสผ่านถูกส่งไปยังอีเมลของคุณ");
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // ✅ ปิดหน้าเมื่อสำเร็จ
        });
      } else {
        _showSnackbar(responseData["detail"] ?? "เกิดข้อผิดพลาด");
      }
    } catch (e) {
      _showSnackbar("เกิดข้อผิดพลาด: $e");
    } finally {
      setState(() {
        _isLoading = false; // ✅ ซ่อนโหลด
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "CROSSWORD ADVENTURE",
                      style: GoogleFonts.cinzel(
                        textStyle: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black),
                            Shadow(offset: Offset(-2, -2), blurRadius: 4, color: Color.fromARGB(96, 255, 255, 255)),
                          ],
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40.0),
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4B5).withOpacity(0.9),
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
                          const Text(
                            'ลืมรหัสผ่าน',
                            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 24.0),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'อีเมล',
                              hintText: 'กรุณากรอกอีเมลของคุณ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFFE4B5),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD2691E),
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                                ),
                                child: const Text(
                                  'ย้อนกลับ',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword, // ✅ ปิดปุ่มขณะโหลด
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLoading ? Colors.grey : const Color(0xFFD2691E),
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white) // ✅ แสดงโหลด
                                    : const Text(
                                        'ยืนยัน',
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
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
}
