import 'dart:io';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/audio_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  double _volume = 1.0;
  File? _imageFile;
  bool _isUploading = false;
  String? userId;
  Uint8List? _imageBytes;
  Map<String, dynamic>? userData; // ✅ ตัวแปรเก็บข้อมูลผู้ใช้
  Map<String, dynamic>? userHistory; // ✅ เก็บข้อมูลสถิติ
  final String apiBaseUrl = "http://192.168.1.38:8000";

  @override
  void initState() {
    super.initState();
    print("✅ เปิดหน้า SettingsPage");
    Future.delayed(Duration(milliseconds: 100), () async {
      await _loadUserId();
    });
    _loadUserId();
    _requestPermissions();
    _volume = AudioService().getVolume();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  // ✅ โหลด user_id จาก SharedPreferences และดึงข้อมูลจาก API
  Future<void> _loadUserId() async {
    print("✅ _loadUserId() ถูกเรียก");
    final prefs = await SharedPreferences.getInstance();
    bool isGuest = prefs.getBool("is_guest") ?? false;
    print("🔍 SharedPreferences contains 'is_guest': $isGuest");

    if (isGuest) {
      userId = null;
      setState(() {
        userData = {
          "username": "ผู้ใช้ชั่วคราว",
          "email": "-",
          "password": "********",
        };
        userHistory = {
          "total_games": 0,
          "total_wins": 0,
          "total_loses": 0,
          "win_rate": "0%"
        };
      });
      print("✅ ตั้งค่าเป็นโหมด Guest");
    } else {
      userId = prefs.getString("user_id");
      print("✅ Loaded user_id in SettingsPage: $userId"); // ✅ ตรวจสอบ user_id ใน SettingsPage

      if (userId != null) {
        print("✅ กำลังเรียก _fetchUserData()...");
        _fetchUserData();
        _fetchProfileImage();
        _fetchUserHistory();
      } else {
        print("❌ user_id เป็น null, อาจมีปัญหากับการโหลดจาก SharedPreferences");
      }
    }
  }

  // ✅ ดึงข้อมูลผู้ใช้จาก API
  Future<void> _fetchUserData() async {
    print("✅ _fetchUserData() ถูกเรียก");

    if (userId == null) {
      print("❌ userId เป็น null, ไม่สามารถโหลดข้อมูลผู้ใช้ได้");
      return;
    }

    final url = Uri.parse('http://192.168.1.38:8000/get_user/$userId');
    print("🔹 กำลังเรียก API: $url");

    final response = await http.get(url);
    print("🔹 API Response: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
      });

      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {});
      });

      print("✅ User Data Loaded: ${userData.toString()}");
    } else {
      print("❌ Error fetching user data: ${response.statusCode}");
    }
  }



  Future<void> _fetchUserHistory() async {
    if (userId == null) return;

    final url = Uri.parse('$apiBaseUrl/get_user_history/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        userHistory = jsonDecode(response.body);
      });
    } else {
      print("❌ Error fetching user history: ${response.statusCode}");
    }
  }

  Future<void> _fetchProfileImage() async {
  if (userId == null) return;

  final url = Uri.parse('$apiBaseUrl/get_user/$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['profile_image'] != null) {
      print("🔹 Profile Image String (Base64): ${data['profile_image']}");

      try {
        String base64String = data['profile_image'];

        // ✅ ถ้ามี "base64," ให้ตัดออกก่อนแปลง
        if (base64String.contains("base64,")) {
          base64String = base64String.split("base64,")[1];
        }

        Uint8List imageBytes = base64Decode(base64String);
        setState(() {
          _imageBytes = imageBytes;
        });
        print("✅ Profile image loaded successfully");
      } catch (e) {
        print("❌ Error decoding Base64: $e");
      }
    } else {
      print("❌ No profile image found");
    }
  } else {
    print("❌ Error fetching profile image: ${response.statusCode}");
  }
}




  void _updateVolume(double value) {
    setState(() {
      _volume = value;
    });
    AudioService().setVolume(value);
  }


  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        print("❌ No image selected.");
        return;
      }

      setState(() {
        _imageFile = File(pickedFile.path);
      });

      print("✅ Image selected: ${pickedFile.path}");
      _uploadImage();
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }


  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(bytes);
      String imageData = "data:image/png;base64,$base64Image"; // ✅ เพิ่ม MIME type

      final response = await http.post(
        Uri.parse('$apiBaseUrl/upload_profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "profile_image": imageData, // ✅ ส่ง Base64 พร้อม MIME type
        }),
      );

      if (response.statusCode == 200) {
        print("✅ อัปโหลดรูปโปรไฟล์สำเร็จ");
        _fetchProfileImage(); // ✅ โหลดรูปใหม่หลังอัปโหลดเสร็จ
      } else {
        print("❌ อัปโหลดรูปโปรไฟล์ล้มเหลว: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'การตั้งค่า',
                        style: GoogleFonts.cinzel(
                          textStyle: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // รูปโปรไฟล์
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!)
                                  : const AssetImage('assets/images/default_profile.jpg') as ImageProvider,
                              backgroundColor: Colors.white,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isUploading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 20),

                      // ข้อมูลผู้ใช้
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // ✅ เช็คว่าเป็น Guest หรือไม่
                            if (userId == null) 
                              Column(
                                children: [
                                  Text(
                                    'ผู้ใช้ชั่วคราว',  // ✅ แสดง Guest Mode
                                    style: GoogleFonts.sarabun(
                                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const ListTile(
                                    title: Text('อีเมล'),
                                    subtitle: Text('-'),  // ✅ Guest ไม่มีอีเมล
                                  ),
                                  const ListTile(
                                    title: Text('รหัสผ่าน'),
                                    subtitle: Text('********'),  // ✅ Guest ไม่มีรหัสผ่าน
                                  ),
                                ],
                              )
                            else if (userData == null) 
                              const Center(child: CircularProgressIndicator())  // ✅ โหลดข้อมูลจาก API
                            else 
                              Column(
                                children: [
                                  Text(
                                    userData!['username'] ?? 'ผู้ใช้ชั่วคราว',  // ✅ ถ้าไม่มี username ใช้ค่าเริ่มต้น
                                    style: GoogleFonts.sarabun(
                                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: const Text('อีเมล'),
                                    subtitle: Text(userData!['email'] ?? '-'),  // ✅ ถ้าไม่มีข้อมูลให้แสดง "-"
                                  ),
                                  ListTile(
                                    title: const Text('รหัสผ่าน'),
                                    subtitle: Text('********'),  // ✅ ไม่แสดงรหัสผ่านจริงเพื่อความปลอดภัย
                                  ),
                                  const Divider(height: 30, thickness: 1),
                                  Text(
                                    'สถิติของคุณ',
                                    style: GoogleFonts.sarabun(
                                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  if (userHistory == null) 
                                    const Center(child: CircularProgressIndicator()) // ✅ โหลดข้อมูลสถิติ
                                  else 
                                    Column(
                                      children: [
                                        ListTile(
                                          title: const Text('จำนวนตาที่เล่น'),
                                          trailing: Text(userHistory!['total_games']?.toString() ?? '0'), // ✅ ถ้าไม่มีข้อมูลให้แสดง 0
                                        ),
                                        ListTile(
                                          title: const Text('จำนวนครั้งที่ชนะ'),
                                          trailing: Text(userHistory!['total_wins']?.toString() ?? '0'), // ✅ ถ้าไม่มีข้อมูลให้แสดง 0
                                        ),
                                        ListTile(
                                          title: const Text('จำนวนครั้งที่แพ้'),
                                          trailing: Text(userHistory!['total_loses']?.toString() ?? '0'), // ✅ ถ้าไม่มีข้อมูลให้แสดง 0
                                        ),
                                        ListTile(
                                          title: const Text('อัตราชนะ (%)'),
                                          trailing: Text("${userHistory!['win_rate']?.toString() ?? '0'}%"), // ✅ ถ้าไม่มีข้อมูลให้แสดง 0
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            const SizedBox(height: 20), // ✅ ใส่ไว้ให้อยู่ภายนอก Column หลัก
                          ],
                        ),
                      ),
                      // Slider ควบคุมระดับเสียง
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ระดับเสียงเพลง',
                                  style: GoogleFonts.sarabun(textStyle: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Slider(
                                    value: _volume,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 10,
                                    label: (_volume * 100).round().toString(),
                                    onChanged: _updateVolume,
                                    activeColor: Colors.brown,
                                    inactiveColor: Colors.brown.shade200,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ปุ่มออกจากระบบ
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        ),
                        child: Text(
                          'ออกจากระบบ',
                          style: GoogleFonts.sarabun(
                            textStyle: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
