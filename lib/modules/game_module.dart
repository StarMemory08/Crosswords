import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/game_page.dart';

// ฟังก์ชัน startGame ปรับใหม่ รองรับ onWin
void startGame(
  BuildContext context, {
  required int levelNumber,
  required VoidCallback onWin,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GamePage(
        levelNumber: levelNumber,
        onWin: onWin,
      ),
    ),
  );
}

// ฟังก์ชันออกจากเกม
void exitGame() {
  SystemNavigator.pop();
}
