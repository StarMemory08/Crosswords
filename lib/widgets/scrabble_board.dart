import 'package:flutter/material.dart';

/// Widget สำหรับแสดงกระดาน Scrabble ขนาด 15x15
class ScrabbleBoard extends StatefulWidget {
  //List แบบ 2 มิติที่เก็บตัวอักษรบนกระดาน (แต่ละตำแหน่งเก็บเป็น String)
  final List<List<String>> boardLetters;  
  //callback function เมื่อผู้ใช้วางตัวอักษรลงบนกระดาน โดยรับพารามิเตอร์เป็นแถว, คอลัมน์ และตัวอักษรที่วาง
  final Function(int row, int col, String letter) onPlaceLetter;
  //รายการตำแหน่งตัวอักษรที่เพิ่งวางไปใหม่ (เก็บเป็น Map ที่มีข้อมูลตำแหน่งและรายละเอียด)
  final List<Map<String, dynamic>>? recentlyPlacedTiles;

  const ScrabbleBoard({
    super.key,
    required this.boardLetters,
    required this.onPlaceLetter,
    this.recentlyPlacedTiles,
  });

  static const int boardSize = 15;  //กำหนดความคงที่ (constant) boardSize เป็น 15 ซึ่งเป็นขนาดของกระดาน
  
  //กำหนดตัวแปร static boardLayout เป็น List 2 มิติ ขนาด 15x15 โดยค่าเริ่มต้นแต่ละช่องคือ ""
  static final List<List<String>> boardLayout = List.generate(
    boardSize,
    (_) => List.generate(boardSize, (_) => ""),
  );
  static bool _initialized = false;


  //ตรวจช่องพิเศษ
  static void initializeBoardLayout() {
    if (!_initialized) {
      _setupBoardLayout();
      _initialized = true;
    }
  }

   static void _setupBoardLayout() {
    // --- Triple Word (TW)
    _setCell(0, 0, "TW");
    _setCell(0, 7, "TW");
    _setCell(0, 14, "TW");
    _setCell(7, 0, "TW");
    _setCell(7, 14, "TW");
    _setCell(14, 0, "TW");
    _setCell(14, 7, "TW");
    _setCell(14, 14, "TW");

    // --- Double Word (DW)
    _setCell(1, 1, "DW");
    _setCell(2, 2, "DW");
    _setCell(3, 3, "DW");
    _setCell(4, 4, "DW");
    _setCell(1, 13, "DW");
    _setCell(2, 12, "DW");
    _setCell(3, 11, "DW");
    _setCell(4, 10, "DW");
    _setCell(13, 1, "DW");
    _setCell(12, 2, "DW");
    _setCell(11, 3, "DW");
    _setCell(10, 4, "DW");
    _setCell(13, 13, "DW");
    _setCell(12, 12, "DW");
    _setCell(11, 11, "DW");
    _setCell(10, 10, "DW");

    // --- Triple Letter (TL)
    _setCell(1, 5, "TL");
    _setCell(1, 9, "TL");
    _setCell(5, 1, "TL");
    _setCell(5, 5, "TL");
    _setCell(5, 9, "TL");
    _setCell(5, 13, "TL");
    _setCell(9, 1, "TL");
    _setCell(9, 5, "TL");
    _setCell(9, 9, "TL");
    _setCell(9, 13, "TL");
    _setCell(13, 5, "TL");
    _setCell(13, 9, "TL");

    // --- Double Letter (DL)
    _setCell(0, 3, "DL");
    _setCell(0, 11, "DL");
    _setCell(2, 6, "DL");
    _setCell(2, 8, "DL");
    _setCell(3, 0, "DL");
    _setCell(3, 7, "DL");
    _setCell(3, 14, "DL");
    _setCell(6, 2, "DL");
    _setCell(6, 6, "DL");
    _setCell(6, 8, "DL");
    _setCell(6, 12, "DL");
    _setCell(7, 3, "DL");
    _setCell(7, 11, "DL");
    _setCell(8, 2, "DL");
    _setCell(8, 6, "DL");
    _setCell(8, 8, "DL");
    _setCell(8, 12, "DL");
    _setCell(11, 0, "DL");
    _setCell(11, 7, "DL");
    _setCell(11, 14, "DL");
    _setCell(12, 6, "DL");
    _setCell(12, 8, "DL");
    _setCell(14, 3, "DL");
    _setCell(14, 11, "DL");

    // --- ช่องกลาง (STAR)
    _setCell(7, 7, "STAR");
  }

  //ฟังก์ชัน private สำหรับตั้งค่าค่าใน boardLayout ที่ตำแหน่ง (r, c) ให้เป็น value ที่ส่งเข้ามา
  static void _setCell(int r, int c, String value) {
    boardLayout[r][c] = value;
  }

  //ฟังก์ชัน createState() สร้าง state ของ widget โดยคืนค่า instance ของ _ScrabbleBoardState
  @override
  _ScrabbleBoardState createState() => _ScrabbleBoardState();
}

class _ScrabbleBoardState extends State<ScrabbleBoard> {
  Map<String, int>? _zoomedCell;

  @override
  Widget build(BuildContext context) {
    ScrabbleBoard.initializeBoardLayout();
    return GridView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      itemCount: ScrabbleBoard.boardSize * ScrabbleBoard.boardSize,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScrabbleBoard.boardSize,
      ),
      //คำนวณตำแหน่งของเซลล์ (row, col) จาก index
      itemBuilder: (context, index) {
        final row = index ~/ ScrabbleBoard.boardSize;
        final col = index % ScrabbleBoard.boardSize;
        final cellType = ScrabbleBoard.boardLayout[row][col];
        final letterInCell = widget.boardLetters[row][col] == "_" ? "" : widget.boardLetters[row][col];
        bool isNewlyPlaced = widget.recentlyPlacedTiles?.any(
              (tile) => tile['row'] == row && tile['col'] == col,
            ) ??
            false;
        bool shouldZoom = false;
        if (_zoomedCell != null &&
            _zoomedCell!['row'] == row &&
            _zoomedCell!['col'] == col) {
          shouldZoom = true;
        }
        return DragTarget<String>(
          builder: (context, candidateData, rejectedData) {
            return AnimatedScale(
              scale: shouldZoom ? 1.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildCellBackground(cellType),
                    if (letterInCell.isNotEmpty)
                      _buildTileDisplay(letterInCell, isNewlyPlaced),
                  ],
                ),
              ),
            );
          },
          onWillAcceptWithDetails: (draggedLetter) => letterInCell.isEmpty,
          onAcceptWithDetails: (draggedLetter) {
            widget.onPlaceLetter(row, col, draggedLetter.data);
            _triggerZoom(row, col);
          },
        );
      },
    );
  }

  //ฟังก์ชันสร้าง widget สำหรับพื้นหลังของเซลล์
  Widget _buildCellBackground(String cellType) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _getCellColor(cellType),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: _buildCellContent(cellType)),
    );
  }


  //ฟังก์ชันสีพื้นหลังตาม CellType 
  Color _getCellColor(String cellType) {
    switch (cellType) {
      case "TW":
        return Colors.redAccent.shade100;
      case "DW":
        return Colors.pink.shade100;
      case "TL":
        return Colors.blueAccent.shade100;
      case "DL":
        return Colors.lightBlue.shade100;
      case "STAR":
        return Colors.yellow.shade200;
      default:
        return Colors.brown.shade100;
    }
  }

  //ฟังก์ชันสร้าง widget สำหรับเนื้อหาของเซลล์
  Widget _buildCellContent(String cellType) {
    if (cellType.isEmpty) return const SizedBox.shrink();
    if (cellType == "STAR") {
      return const Icon(Icons.star, color: Colors.orange, size: 24);
    }
    return Text(cellType,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center);
  }


  //ฟังก์ชันสร้าง widget สำหรับแสดงตัวอักษรในเซลล์
  Widget _buildTileDisplay(String letter, bool isNewlyPlaced) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber[200],
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
        border: isNewlyPlaced ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Center(
        child: FittedBox(
          child: Text(letter,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black26),
                ],
              )),
        ),
      ),
    );
  }

  //ฟังก์ชันใช้สำหรับสร้างเอฟเฟคซูมให้กับเซลล์ที่วางตัวอักษร
  void _triggerZoom(int row, int col) {
    setState(() {
      _zoomedCell = {'row': row, 'col': col};
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _zoomedCell = null;
        });
      }
    });
  }
}
