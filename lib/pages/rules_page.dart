import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crossword_pj/pages/settings_page.dart'; 

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // ดึงขนาดหน้าจอเพื่อใช้คำนวณความกว้างและความสูงของกล่องเนื้อหา
    return Scaffold(
      body: Stack(
        children: [
          // แสดงภาพพื้นหลังเต็มหน้าจอ
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_background.jpg', // เส้นทางไฟล์ภาพพื้นหลัง
              fit: BoxFit.cover, // ปรับขนาดภาพให้ครอบคลุมพื้นที่ทั้งหมด
            ),
          ),
          // เนื้อหาหลักของหน้า Rules
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // จัดวางให้อยู่ตรงกลางแนวตั้ง
              children: [
                // ชื่อหัวข้อ "กฎการเล่น" โดยใช้ฟอนต์ Cinzel
                Text(
                  "กฎการเล่น",
                  style: GoogleFonts.cinzel(
                    textStyle: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        // เงาเพื่อให้ตัวอักษรเด่นขึ้น
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
                const SizedBox(height: 25), // เว้นระยะห่างด้านบนของกล่องเนื้อหา
                // กล่องที่แสดงเนื้อหากฎการเล่น
                Container(
                  width: size.width * 0.9, // ความกว้าง 90% ของหน้าจอ
                  height: size.height * 0.5, // ความสูง 50% ของหน้าจอ
                  margin: const EdgeInsets.symmetric(horizontal: 16), // ระยะห่างด้านข้าง
                  padding: const EdgeInsets.all(16), // ระยะห่างภายในกล่อง
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // พื้นหลังโปร่งใส
                    borderRadius: BorderRadius.circular(16), // มุมโค้งมน
                  ),
                  // ใช้ SingleChildScrollView เพื่อให้สามารถเลื่อนดูเนื้อหากฎได้
                  child: SingleChildScrollView(
                    child: Text(
                      """
กฎการเล่น
1. วัตถุประสงค์ของเกม 
   - สร้างคะแนนโดยการจัดเรียงตัวอักษรให้เป็นคำบนกระดาน
2. การตั้งค่าเกม
   - จำนวนผู้เล่น: 2
   - ผู้เล่นแต่ละคนจั่วตัวอักษร 7 ตัวจากถุง  
   - มีตัวอักษร * ที่สามารถใช้แทนตัวอักษรใด ๆ ได้ (แต่มีค่า 0 คะแนน)
3. การเริ่มเล่น
   - ผู้เล่นที่มีตัวอักษรที่มีค่าสูงสุดจะเริ่มก่อน  
   - คำแรกที่วางต้องผ่านช่องกลางกระดาน
4. การวางตัวอักษร
   - สามารถวางตัวอักษรในแนวแกนนอนหรือแนวตั้งเท่านั้น  
   - คำที่สร้างขึ้นต้องเชื่อมต่อกับตัวอักษรที่มีอยู่บนกระดาน (ยกเว้นคำแรก)  
   - คำที่วางต้องเป็นคำที่ได้รับการยอมรับตามพจนานุกรมที่ใช้
5. การนับคะแนน  
   - แต่ละตัวอักษรมีค่าเฉพาะ (ตัวอย่างเช่น Q และ Z มีค่าสูง)  
   - คะแนนคำนวณจากผลรวมของค่าตัวอักษรที่วางในเทิร์นนั้น  
   - ช่องพิเศษบนกระดาน: มีช่องคูณตัวอักษรและช่องคูณคำที่จะเพิ่มคะแนนตามตำแหน่ง
6. การท้าทายคำ  
   - ผู้เล่นสามารถท้าทายคำที่วางได้หากสงสัยว่าไม่ถูกต้อง  
   - หากคำที่ท้าทายถูกต้อง (ไม่พบในพจนานุกรม) ผู้ท้าทายจะเสียเทิร์น  
   - หากคำที่วางไม่ถูกต้อง ผู้เล่นที่วางคำต้องนำคำออกและเสียคะแนนตามที่กำหนด
7. การเปลี่ยนตัวอักษร  
   - ผู้เล่นสามารถเลือกเปลี่ยนตัวอักษรในมือได้ โดยใช้เทิร์นของตนเอง  
   - ตัวอักษรที่เปลี่ยนจะถูกนำกลับเข้าสู่ถุงและจั่วใหม่ให้เท่ากับจำนวนที่เปลี่ยน
8. จบเกมและการนับคะแนนสุดท้าย  
   - เกมจะจบเมื่อถุงตัวอักษรหมดและไม่มีผู้เล่นที่สามารถวางคำได้ในเทิร์น  
   - คะแนนสุดท้ายจะถูกปรับโดยการหักคะแนนจากตัวอักษรที่เหลือในมือของผู้เล่นทุกคน  
   - หากผู้เล่นใดวางตัวอักษรครบทุกตัวในมือ จะได้รับคะแนนโบนัสตามที่กำหนด
9. การชนะเกม
   - ผู้เล่นที่มีคะแนนสูงสุดหลังจากนับคะแนนสุดท้ายจะเป็นผู้ชนะ

**หมายเหตุ:**  
กฎเหล่านี้เป็นการสรุปเนื้อหาหลักของเกม Scrabble ตามกฎทางการ โดยอาจมีรายละเอียดหรือเงื่อนไขเพิ่มเติมในคู่มือการเล่นเกมเวอร์ชันล่าสุด
                      """,
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(height: 25), // เว้นระยะห่างด้านล่างของกล่องเนื้อหา
                // ปุ่ม "กลับ" เพื่อกลับไปยังหน้าก่อนหน้า
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // กลับไปหน้าก่อนหน้า
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'กลับ',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ปุ่ม FloatingActionButton สำหรับไปยัง SettingsPage
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
}
