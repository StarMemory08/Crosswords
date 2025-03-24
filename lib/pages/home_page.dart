import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crossword_pj/pages/level_selection_page.dart';
import 'package:crossword_pj/pages/settings_page.dart';
import 'package:flutter/services.dart'; 

// หน้า HomePage สำหรับแสดงหน้าจอหลักของแอปพลิเคชัน
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ฟังก์ชัน build() สร้าง widget tree สำหรับหน้า HomePage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ Stack เพื่อวางภาพพื้นหลังและเนื้อหาซ้อนกัน
      body: Stack(
        children: [
          // Widget สำหรับแสดงภาพพื้นหลังให้เต็มจอ
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_background.jpg', // รูปภาพพื้นหลัง
              fit: BoxFit.cover, // ปรับขนาดให้ครอบคลุมพื้นที่ทั้งหมด
            ),
          ),
          // Center widget สำหรับจัดวางเนื้อหาตรงกลางหน้าจอ
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ข้อความชื่อเกมที่มีการปรับแต่งด้วย Google Fonts
                  Text(
                    "CROSSWORD ADVENTURE",
                    style: GoogleFonts.cinzel(
                      textStyle: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          // เงาของตัวอักษรด้านขวาล่าง
                          Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Color.fromARGB(255, 0, 0, 0)),
                          // เงาของตัวอักษรด้านซ้ายบน
                          Shadow(
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                              color: Color.fromARGB(96, 255, 255, 255)),
                        ],
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  // ปุ่ม "เริ่มผจญภัย" เรียกไปหน้าเลือกด่าน (LevelSelectionPage)
                  _buildButton(
                    context,
                    label: "เริ่มผจญภัย",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const LevelSelectionPage()),
                      );
                    },
                  ),
                  // ปุ่ม "ประวัติการเล่น" แสดง Dialog ประวัติการเล่น (ยังไม่พร้อมใช้งาน)
                  _buildButton(
                    context,
                    label: "ประวัติการเล่น",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("ประวัติการเล่น"),
                            content: const Text("Coming Soon!"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("ปิด"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // ปุ่ม "กฎการเล่น" นำไปสู่หน้ากฎของเกมผ่าน Navigator.pushNamed
                  _buildButton(
                    context,
                    label: "กฎการเล่น",
                    onTap: () {
                      Navigator.pushNamed(context, '/rules');
                    },
                  ),
                  // ปุ่ม "ออกจากเกม" ที่แสดง Dialog ยืนยันการออกจากเกม
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("ออกจากเกม"),
                              content: const Text(
                                  "คุณแน่ใจหรือไม่ว่าต้องการออกจากเกม?"),
                              actions: [
                                // ปุ่มยกเลิก Dialog
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text("ยกเลิก"),
                                ),
                                // ปุ่มออกจากเกม (ปิดแอพ)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    SystemNavigator.pop(); // ออกจากแอพ
                                  },
                                  child: const Text("ออก"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        "ออกจากเกม",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // ปุ่ม Floating Action สำหรับไปยังหน้าตั้งค่า (SettingsPage)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
        backgroundColor: Colors.grey[700],
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }
  
  // ฟังก์ชัน _buildButton() สร้างปุ่มที่มีสไตล์เหมือนกันโดยรับ label และ onTap เป็น parameter
  Widget _buildButton(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 200, // กำหนดความกว้างของปุ่ม
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color.fromARGB(255, 255, 230, 162), // สีพื้นหลังของปุ่ม
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)), // ปรับขอบโค้ง
            padding: const EdgeInsets.symmetric(vertical: 15), // ช่องว่างภายในปุ่ม
          ),
          child: Text(
            label, // ข้อความที่จะแสดงบนปุ่ม
            style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
