import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget สำหรับแสดง ScoreBoard ที่รวมเวลาที่เหลือ คะแนน และข้อความแจ้งเตือน
class ScoreBoardWidget extends StatelessWidget {
  //ประกาศตัวแปร final ทั้ง 5 ตัวที่ใช้แสดงข้อมูล
  final int remainingSeconds;
  final int player1Score;
  final int player2Score;
  final String notificationMessage;
  final bool isPlayer1Turn;

  const ScoreBoardWidget({
    super.key,
    required this.remainingSeconds,
    required this.player1Score,
    required this.player2Score,
    required this.notificationMessage,
    required this.isPlayer1Turn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // แถบเวลาที่เหลือ (Progress Bar)
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: remainingSeconds / 900.0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // แถบคะแนนและข้อมูลผู้เล่น
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ผู้เล่น 1
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isPlayer1Turn
                          ? Border.all(color: Colors.green, width: 3)
                          : null,
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blueGrey,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ผู้เล่น 1",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$player1Score",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                  )
                ],
              ),
              // ตัวจับเวลา
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TIME",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              // BOT AI
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: !isPlayer1Turn
                          ? Border.all(color: Colors.green, width: 3)
                          : null,
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blueGrey,
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "BOT AI",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$player2Score",
                    style: GoogleFonts.sarabun(
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // พื้นที่แสดงข้อความแจ้งเตือน
          SizedBox(
            height: 65,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.indigo,
                    Colors.deepPurple,
                    Colors.indigoAccent
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigoAccent, width: 2),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                notificationMessage.isEmpty ? " " : notificationMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  textStyle: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
