import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showHistoryDialog(BuildContext context, List<Map<String, dynamic>> playedWords) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("ประวัติคำที่ลง", style: GoogleFonts.sarabun()),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: playedWords.isEmpty
              ? Center(child: Text("ยังไม่มีคำที่ลง", style: GoogleFonts.sarabun()))
              : ListView.builder(
                  itemCount: playedWords.length,
                  itemBuilder: (context, index) {
                    final entry = playedWords[index];
                    return ListTile(
                      title: Text("${entry['player']}: ${entry['words']}", style: GoogleFonts.sarabun()),
                      subtitle: Text("แปล: ${entry['translation']}", style: GoogleFonts.sarabun()),
                      trailing: Text("+${entry['score']}", style: GoogleFonts.sarabun()),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ปิด", style: GoogleFonts.sarabun()),
          ),
        ],
      );
    },
  );
}
