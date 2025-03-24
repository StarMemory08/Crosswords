import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crossword_pj/pages/settings_page.dart';
import 'package:crossword_pj/pages/game_page.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({Key? key}) : super(key: key);

  @override
  _LevelSelectionPageState createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  // ตัวอย่างด่านทั้งหมด 12 ด่าน
  // มีสถานะ: locked, unlocked, completed
  final List<Map<String, dynamic>> kLevels = List.generate(12, (index) {
    final levelNumber = index + 1;
    return {
      'number': levelNumber,
      'status': (levelNumber == 1) ? 'unlocked' : 'locked',
    };
  });

  // ฟังก์ชันสำหรับปลดล็อกด่านถัดไป
  void unlockNextLevel(int currentLevel) {
    // currentLevel จะเท่ากับ 1-12
    // ถ้า currentLevel < 12, ให้ปลดล็อก (currentLevel+1)
    if (currentLevel < 12) {
      setState(() {
        kLevels[currentLevel]['status'] = 'unlocked';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // รูปพื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // ปุ่มย้อนกลับ
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          // เนื้อหาหลัก
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ชื่อเกม
                  Text(
                    "CROSSWORD ADVENTURE",
                    style: GoogleFonts.cinzel(
                      textStyle: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(offset: Offset(2, 2), blurRadius: 4, color: Color.fromARGB(255, 0, 0, 0)),
                          Shadow(offset: Offset(-2, -2), blurRadius: 4, color: Color.fromARGB(96, 255, 255, 255)),
                        ],
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  // กล่องแสดง Grid ของด่าน
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4B5).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: kLevels.length,
                      itemBuilder: (context, index) {
                        final levelInfo = kLevels[index];
                        final int levelNumber = levelInfo['number'];
                        final String status = levelInfo['status'];

                        final bool isLocked = (status == 'locked');
                        final bool isCompleted = (status == 'completed');

                        // กำหนดสีตามสถานะ
                        Color levelColor;
                        if (isLocked) {
                          levelColor = Colors.grey;
                        } else if (isCompleted) {
                          levelColor = Colors.green;
                        } else {
                          levelColor = Colors.orange;
                        }

                        return GestureDetector(
                          onTap: isLocked
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GamePage(
                                        levelNumber: levelNumber,
                                        onWin: () {
                                          // เมื่อชนะด่านนี้ ให้เปลี่ยนสถานะเป็น completed
                                          setState(() {
                                            kLevels[levelNumber - 1]['status'] = 'completed';
                                          });

                                          // แล้วปลดล็อกด่านถัดไป
                                          unlockNextLevel(levelNumber);
                                        },
                                      ),
                                    ),
                                  );
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: levelColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2,2),
                                )
                              ],
                            ),
                            child: Center(
                              child: isLocked
                                  ? const Icon(Icons.lock, color: Colors.white)
                                  : Text(
                                      "$levelNumber",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
          // ปุ่ม FloatingActionButton สำหรับไปยัง Settings
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
