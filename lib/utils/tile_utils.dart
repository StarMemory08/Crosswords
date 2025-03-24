//สับตัวอักษรส่วนรวมเริ่มต้น
List<String> generateTileBag() {
  List<String> tileBag = [];
  for (int i = 0; i < 9; i++) {
    tileBag.add('A');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('B');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('C');
  }
  for (int i = 0; i < 4; i++) {
    tileBag.add('D');
  }
  for (int i = 0; i < 12; i++) {
    tileBag.add('E');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('F');
  }
  for (int i = 0; i < 3; i++) {
    tileBag.add('G');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('H');
  }
  for (int i = 0; i < 9; i++) {
    tileBag.add('I');
  }
  tileBag.add('J');
  tileBag.add('K');
  for (int i = 0; i < 4; i++) {
    tileBag.add('L');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('M');
  }
  for (int i = 0; i < 6; i++) {
    tileBag.add('N');
  }
  for (int i = 0; i < 8; i++) {
    tileBag.add('O');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('P');
  }
  tileBag.add('Q');
  for (int i = 0; i < 6; i++) {
    tileBag.add('R');
  }
  for (int i = 0; i < 4; i++) {
    tileBag.add('S');
  }
  for (int i = 0; i < 6; i++) {
    tileBag.add('T');
  }
  for (int i = 0; i < 4; i++) {
    tileBag.add('U');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('V');
  }
  for (int i = 0; i < 2; i++) {
    tileBag.add('W');
  }
  tileBag.add('X');
  for (int i = 0; i < 2; i++) {
    tileBag.add('Y');
  }
  tileBag.add('Z');
  tileBag.add('*');
  tileBag.add('*');
  tileBag.shuffle();
  return tileBag;
}


//จั๋วตัวอักษรแจกทั้ง2ฝั้ง
List<String> drawTiles(List<String> tileBag, int count) {
  List<String> drawn = [];
  for (int i = 0; i < count; i++) {
    if (tileBag.isEmpty) break;
    drawn.add(tileBag.removeLast());
  }
  return drawn;
}
