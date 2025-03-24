import 'package:flutter/material.dart';
import 'package:crossword_pj/widgets/scrabble_board.dart';

/// Widget สำหรับแสดงกระดานเกมโดยใช้ ScrabbleBoard
class BoardWidget extends StatelessWidget {
  final List<List<String>> boardLetters;
  final Function(int row, int col, String letter) onPlaceLetter;

  const BoardWidget({
    super.key,
    required this.boardLetters,
    required this.onPlaceLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ScrabbleBoard(
        boardLetters: boardLetters,
        onPlaceLetter: onPlaceLetter,
      ),
    );
  }
}
