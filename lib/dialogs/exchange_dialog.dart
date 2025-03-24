import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ฟังก์ชันช่วยสำหรับคำนวณคะแนนของตัวอักษร
int _getLetterScore(String letter) {
  const scores = {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4,
    'G': 2, 'H': 4, 'I': 1, 'J': 8, 'K': 5, 'L': 1,
    'M': 3, 'N': 1, 'O': 1, 'P': 3, 'Q': 10, 'R': 1,
    'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 4, 'X': 8,
    'Y': 4, 'Z': 10,
  };
  return scores[letter.toUpperCase()] ?? 0;
}

// ฟังก์ชันสำหรับสร้าง Widget ที่แสดงตัวอักษรพร้อมคะแนน
Widget _buildTileContent(String letter) {
  final int score = _getLetterScore(letter);
  return Stack(
    children: [
      Center(
        child: Text(
          letter,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      Positioned(
        right: 3,
        bottom: 2,
        child: Text(
          score.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

Future<List<String>?> showExchangeDialog(BuildContext context, List<String> currentRack) async {
  List<bool> selected = List.filled(currentRack.length, false);
  return showDialog<List<String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Center(child: Text("เลือกตัวอักษรที่จะเปลี่ยน", style: GoogleFonts.sarabun())),
            content: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(currentRack.length, (index) {
                  String letter = currentRack[index];
                  bool isSelected = selected[index];
                  return GestureDetector(
                    onTap: () {
                      setStateDialog(() {
                        selected[index] = !selected[index];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber[200],
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(1, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: _buildTileContent(letter),
                      ),
                    ),
                  );
                }),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text("ยกเลิก", style: GoogleFonts.sarabun()),
              ),
              ElevatedButton(
                onPressed: () {
                  List<String> toExchange = [];
                  for (int i = 0; i < currentRack.length; i++) {
                    if (selected[i]) {
                      toExchange.add(currentRack[i]);
                    }
                  }
                  Navigator.pop(context, toExchange);
                },
                child: Text("ตกลง", style: GoogleFonts.sarabun()),
              ),
            ],
          );
        },
      );
    },
  );
}
