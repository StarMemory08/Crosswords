import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget สำหรับแถบปุ่มควบคุม (เมนู, แลกเปลี่ยน, Submit, Undo, Skip Turn)
class ControlPanelWidget extends StatelessWidget {
  final VoidCallback onShowMenu;
  final VoidCallback onExchange;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;
  final VoidCallback onSkip;

  const ControlPanelWidget({
    super.key,
    required this.onShowMenu,
    required this.onExchange,
    required this.onSubmit,
    required this.onUndo,
    required this.onSkip,
  });



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: onShowMenu,
            icon: const Icon(Icons.list),
            tooltip: 'เมนู',
            color: Colors.blueAccent,
            iconSize: 28,
          ),
          IconButton(
            onPressed: onExchange,
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'แลกเปลี่ยนตัวอักษร',
            color: Colors.green,
            iconSize: 28,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                "SUBMIT",
                style: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onUndo,
            icon: const Icon(Icons.undo),
            tooltip: 'ยกเลิก',
            color: Colors.purple,
            iconSize: 28,
          ),
          IconButton(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next),
            tooltip: 'ข้ามเทิร์น',
            color: Colors.redAccent,
            iconSize: 28,
          ),
        ],
      ),
    );
  }
}
