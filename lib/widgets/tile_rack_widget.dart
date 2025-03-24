import 'package:flutter/material.dart';
import 'package:crossword_pj/widgets/tile_rack.dart';

/// Widget สำหรับแสดง Tile Rack ของผู้เล่น
class TileRackWidget extends StatelessWidget {
  final List<String> letters;

  const TileRackWidget({super.key, required this.letters});

  @override
  Widget build(BuildContext context) {
    return TileRack(letters: letters);
  }
}
