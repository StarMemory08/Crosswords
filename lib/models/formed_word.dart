// lib/models/formed_word.dart

/// คลาสสำหรับเก็บข้อมูลคำที่ถูกสร้างขึ้นในเกม Scrabble
class FormedWord {
  final String word;
  //เก็บข้อมูลตำแหน่งและตัวอักษรแต่ละตัวที่ประกอบคำ
  final List<LetterPos> letters;
  FormedWord({
    required this.word,
    required this.letters,
  });
}


/// คลาสสำหรับเก็บข้อมูลตำแหน่งและตัวอักษรที่ประกอบคำ
class LetterPos {
  final int row;
  final int col;
  final String letter;
  LetterPos({
    required this.row,
    required this.col,
    required this.letter,
  });
}
