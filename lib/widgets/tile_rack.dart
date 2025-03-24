import 'package:flutter/material.dart';

/// Widget แสดง tile rack สำหรับแสดงตัวอักษรที่ผู้เล่นมีอยู่
class TileRack extends StatelessWidget {
  final List<String> letters;
  const TileRack({super.key, required this.letters});

  // ฟังก์ชันแสดงคะแนนตัวอักษร 
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

  //ฟังก์ชันที่สร้าง widget สำหรับแสดงตัวอักษรพร้อมคะแนน
  Widget _buildTileContent(String letter) {
    final score = _getLetterScore(letter);
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


  //ฟังก์ชันสร้าง widget สำหรับแสดง tile (กล่องที่มีตัวอักษร) 
  Widget _buildTile(String letter, {bool isDragging = false}) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDragging ? Colors.grey : Colors.amber[200],
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(1, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          _buildTileContent(letter),
        ],
      ),
    );
  }

  //ฟังก์ชันสร้าง widget สำหรับแสดง tile ขณะลาก
  Widget _buildDraggingTile(String letter) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Container(
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
            ),
            _buildTileContent(letter),
          ],
        ),
      ),
    );
  }


  //ขอบพื้นหลังตัวอักษรของเรา
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blueGrey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((letter) {
          return Draggable<String>(
            data: letter,
            feedback: _buildDraggingTile(letter),
            childWhenDragging: _buildTile(letter, isDragging: true),
            child: _buildTile(letter),
          );
        }).toList(),
      ),
    );
  }
}
