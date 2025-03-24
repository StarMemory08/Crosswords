import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart';
import '../dialogs/exchange_dialog.dart';
import '../dialogs/history_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/formed_word.dart';
import '../utils/tile_utils.dart';
import '../widgets/board_widget.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/scoreboard_widget.dart';
import '../widgets/tile_rack_widget.dart';
import 'package:crossword_pj/pages/settings_page.dart';

final translator = GoogleTranslator();

Future<String> translateWord(String word,
    {String from = 'en', String to = 'th'}) async {
  try {
    var translation = await translator.translate(word, from: from, to: to);
    return translation.text;
  } catch (e) {
    return word;
  }
}

class GamePage extends StatefulWidget {
  final int levelNumber;
  final VoidCallback onWin; // เรียกเมื่อผู้เล่นชนะด่านนี้

  const GamePage({
    Key? key,
    required this.levelNumber,
    required this.onWin,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  String get playerName => "Player";
  String get botName => "BOT AI ${widget.levelNumber}";

  static const int boardSize = 15;
  Map<String, dynamic> gameState = {};
  late List<List<String>> boardLetters;
  List<String> tileBag = [];
  List<String> tileRackPlayer1 = [];
  List<String> tileRackPlayer2 = [];
  List<Map<String, dynamic>> tempPlacedTiles = [];
  int player1Score = 0;
  int player2Score = 0;
  List<Map<String, dynamic>> playedWords = [];
  bool isPlayer1Turn = true;
  bool isFirstMove = true;
  int skipCountPlayer1 = 0;
  int skipCountPlayer2 = 0;
  Timer? _turnTimer;
  int _remainingSecondsPlayer1 = 900;
  int _remainingSecondsPlayer2 = 900;
  String _notificationMessage = "";
  List<String>? cachedDictionary;
  int get currentRemainingSeconds =>
      isPlayer1Turn ? _remainingSecondsPlayer1 : _remainingSecondsPlayer2;

  Future<List<String>> fetchWordsFromDatabase() async {
    try {
      final String apiUrl = 'http://192.168.1.38:8000/words';
      debugPrint("📡 Fetching words from: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data["data"] is List) {
          List<String> words = List<String>.from(data["data"]);  // ✅ รองรับโครงสร้างใหม่
          debugPrint("✅ Fetched ${words.length} words successfully!");
          return words;
        } else {
          throw Exception("❌ Invalid data format from API");
        }
      } else {
        throw Exception('❌ Failed to load words, status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("🚨 Error fetching words: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getBotMove() async {
    print("📌 [DEBUG] โหลด game_state ก่อนให้บอทเล่น...");

    try {
        final gameStateResponse = await http.get(
            Uri.parse("http://192.168.1.38:8000/game_state")
        );

        if (gameStateResponse.statusCode != 200) {
            throw Exception("❌ ไม่สามารถโหลด game_state ได้: ${gameStateResponse.body}");
        }

        final gameState = json.decode(gameStateResponse.body);
        print("✅ [DEBUG] game_state ที่ได้: ${jsonEncode(gameState)}");

        final response = await http.post(
            Uri.parse("http://192.168.1.38:8000/bot_move"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
                "game_id": "scrabble_game03",
                "board": gameState["board"],
                "rack_player2": gameState["rack_player2"],  // ✅ ต้องเป็น rack ของบอท
                "tile_bag": gameState["tile_bag"],
                "difficulty": "medium"
            }),
        );

        if (response.statusCode == 200) {
            print("✅ [DEBUG] บอทตอบกลับ: ${response.body}");
            return json.decode(response.body);
        } else {
            print("⚠️ [ERROR] API bot_move ผิดพลาด: ${response.body}");
            throw Exception("Failed to fetch bot move");
        }
    } catch (e) {
        print("❌ [ERROR] getBotMove() มีปัญหา: $e");
        return {};
    }
}




  @override
  void initState() {
    super.initState();

    // ส่วนที่เหลือของการตั้งค่า
    boardLetters =
        List.generate(boardSize, (_) => List.generate(boardSize, (_) => ""));
    tileBag = generateTileBag();
    tileRackPlayer1 = drawTiles(tileBag, 7);
    tileRackPlayer2 = drawTiles(tileBag, 7);
    _startTurnTimer();
    fetchWordsFromDatabase().then((words) {
      setState(() {
        cachedDictionary = words;
      });
      debugPrint("Loaded ${words.length} words from asset");
    }).catchError((error) {
      debugPrint("Error loading words from asset: $error");
    });
  }

  Future<void> fetchLatestGameState() async {
  debugPrint("📡 [Flutter] กำลังโหลด game_state...");

  try {
    final response = await http.get(
      Uri.parse("http://192.168.1.38:8000/game_state?timestamp=${DateTime.now().millisecondsSinceEpoch}")
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      debugPrint("📩 [Flutter] game_state ที่ได้รับ: ${json.encode(data)}"); // ✅ Debug JSON เต็ม

      if (data.containsKey("board") && data["board"] is List) {
        List<List<String>> newBoard = List<List<String>>.from(data["board"].map(
          (row) => List<String>.from(row.map((cell) => cell == "_" ? "" : cell))
        ));

        List<String> newTileBag = List<String>.from(data["tile_bag"] ?? []);

        // ✅ Debug ตรวจสอบก่อนอัปเดต UI
        debugPrint("🔍 [DEBUG] ค่า board ใหม่:");
        for (var row in newBoard) {
          debugPrint(row.toString());
        }

        debugPrint("🔍 [DEBUG] tileBag ใหม่: ${newTileBag.toString()}");

        setState(() {
          gameState = data;
          boardLetters = newBoard;
          tileBag = newTileBag;
        });

        debugPrint("✅ [Flutter] โหลด game_state ล่าสุดสำเร็จ และอัปเดต UI แล้ว");
      } else {
        debugPrint("⚠️ [ERROR] game_state ไม่ถูกต้อง: ${json.encode(data)}");
      }
    } else {
      debugPrint("❌ [Flutter] ไม่สามารถโหลด game_state ได้, status: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ [Flutter] เกิดข้อผิดพลาดในการโหลด game_state: $e");
  }
}

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (isPlayer1Turn) {
          if (_remainingSecondsPlayer1 <= 0) {
            timer.cancel();
            _handleTimeExpired();
          } else {
            _remainingSecondsPlayer1--;
          }
        } else {
          if (_remainingSecondsPlayer2 <= 0) {
            timer.cancel();
            _handleTimeExpired();
          } else {
            _remainingSecondsPlayer2--;
          }
        }
      });
    });
  }

  void _handleTimeExpired() {
    // หักคะแนน 100 จากผู้เล่นที่หมดเวลา
    setState(() {
      if (isPlayer1Turn) {
        player1Score -= 100;
      } else {
        player2Score -= 100;
      }
    });

    // แสดงข้อความแจ้งเตือน
    _showMessage("หมดเวลา! ถูกหักคะแนน 100 แล้วจบเกม");

    // เช็คผู้ชนะ
    String winner;
    if (player1Score > player2Score) {
      winner = playerName;
    } else if (player2Score > player1Score) {
      winner = botName;
    } else {
      winner = "เสมอกัน";
    }

    // สรุปเกม
    _endGame(winner);
  }

  Future<void> placeLetterOnBoard(int row, int col, String letter) async {
    if (letter != '*') {
      _doPlaceLetter(row, col, letter, false);
      return;
    }
    final chosenLetter = await _pickLetterForBlank();
    if (chosenLetter == null || chosenLetter.isEmpty) return;
    _doPlaceLetter(row, col, chosenLetter, true);
  }

  void _doPlaceLetter(int row, int col, String letter, bool isBlank) {
    setState(() {
      if (isBlank) {
        getCurrentRack().remove('*');
      } else {
        getCurrentRack().remove(letter);
      }
      boardLetters[row][col] = letter;
      tempPlacedTiles
          .add({'row': row, 'col': col, 'letter': letter, 'isBlank': isBlank});
    });
  }

  int _getLetterScore(String letter) {
    const scores = {
      'A': 1,
      'B': 3,
      'C': 3,
      'D': 2,
      'E': 1,
      'F': 4,
      'G': 2,
      'H': 4,
      'I': 1,
      'J': 8,
      'K': 5,
      'L': 1,
      'M': 3,
      'N': 1,
      'O': 1,
      'P': 3,
      'Q': 10,
      'R': 1,
      'S': 1,
      'T': 1,
      'U': 1,
      'V': 4,
      'W': 4,
      'X': 8,
      'Y': 4,
      'Z': 10,
    };
    return scores[letter.toUpperCase()] ?? 0;
  }

  Widget _buildTileContent(String letter) {
    final int score = _getLetterScore(letter);
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

  Future<String?> _pickLetterForBlank() async {
    final letters =
        List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i));
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('เลือกตัวอักษรแทน Blank', style: GoogleFonts.sarabun()),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: letters.map((letter) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, letter),
                  child: Container(
                    width: 40,
                    height: 40,
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
                    child: _buildTileContent(letter),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ยกเลิก", style: GoogleFonts.sarabun()),
            ),
          ],
        );
      },
    );
  }

  void pullBackAllTiles() {
    setState(() {
      for (var tile in tempPlacedTiles) {
        final row = tile['row'];
        final col = tile['col'];
        final letter = tile['letter'];
        final isBlank = tile['isBlank'] == true;
        boardLetters[row][col] = "";
        if (isBlank) {
          getCurrentRack().add('*');
        } else {
          getCurrentRack().add(letter);
        }
      }
      tempPlacedTiles.clear();
    });
  }

  List<String> getCurrentRack() {
    return isPlayer1Turn ? tileRackPlayer1 : tileRackPlayer2;
  }

  Future<void> exchangeTiles() async {
    pullBackAllTiles();
    final currentRack = getCurrentRack();
    if (currentRack.isEmpty) {
      _showMessage("ไม่มีตัวอักษรในถุงที่จะเปลี่ยน");
      return;
    }
    final List<String>? selectedLetters =
        await showExchangeDialog(context, currentRack);
    if (selectedLetters == null || selectedLetters.isEmpty) return;

    for (String letter in selectedLetters) {
      currentRack.remove(letter);
    }
    tileBag.addAll(selectedLetters);
    tileBag.shuffle();

    final List<String> newTiles = drawTiles(tileBag, selectedLetters.length);
    currentRack.addAll(newTiles);

    _showMessage("เปลี่ยนตัวอักษรแล้ว จำนวน ${selectedLetters.length} ตัว");

    setState(() {
      // เช็ค skip
      if (isPlayer1Turn) {
        skipCountPlayer1++;
        if (skipCountPlayer1 >= 3) {
          _showMessage("$playerName ข้ามเทิร์น 3 ครั้ง, คะแนนลด 100 คะแนน!");
          player1Score -= 100;
          skipCountPlayer1 = 0;
        }
      } else {
        skipCountPlayer2++;
        if (skipCountPlayer2 >= 3) {
          _showMessage("$botName ข้ามเทิร์น 3 ครั้ง, คะแนนลด 100 คะแนน!");
          player2Score -= 100;
          skipCountPlayer2 = 0;
        }
      }
      if (boardLetters[7][7] != "") {
        isFirstMove = false;
      }

      isPlayer1Turn = !isPlayer1Turn;
    });
    _startTurnTimer();
  }

  void skipTurn() {
    setState(() {
      pullBackAllTiles();
      if (isPlayer1Turn) {
        skipCountPlayer1++;
        if (skipCountPlayer1 >= 3) {
          _showMessage("$playerName ข้ามเทิร์น 3 ครั้ง -> แพ้เกม!");
          _endGame(botName);
          return;
        }
      } else {
        skipCountPlayer2++;
        if (skipCountPlayer2 >= 3) {
          _showMessage("$botName ข้ามเทิร์น 3 ครั้ง -> แพ้เกม!");
          _endGame(playerName);
          return;
        }
      }
      isPlayer1Turn = !isPlayer1Turn;
    });
    _startTurnTimer();
  }

  void _endGame(String winner) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "GameResult",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        final isWinner = winner == playerName;
        return Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.blue.shade700, Colors.lightBlueAccent.shade100],
                center: Alignment.topCenter,
                radius: 1.0,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10)),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWinner ? 'WIN' : 'LOSE',
                    style: GoogleFonts.cinzel(
                      textStyle: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              blurRadius: 8,
                              offset: Offset(2, 2),
                              color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Player 1
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playerName,
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$player1Score',
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Bot
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            botName,
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$player2Score',
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (winner == playerName) ...[
                    // ---- ปุ่ม "ตกลง" (onWin + กลับหน้าเลือกด่าน)
                    ElevatedButton(
                      onPressed: () {
                        widget.onWin(); // อัปเดตผ่านด่าน
                        Navigator.pop(ctx); // ปิด Dialog
                        Navigator.pop(ctx); // กลับหน้าเลือกด่าน
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'ตกลง',
                        style: GoogleFonts.sarabun(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---- ปุ่ม "ไปด่านต่อไป" (onWin + เปิดด่านใหม่)
                    ElevatedButton(
                      onPressed: () {
                        widget.onWin(); // อัปเดตผ่านด่าน
                        Navigator.pop(ctx); // ปิด Dialog

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GamePage(
                              levelNumber: widget.levelNumber + 1, // ด่านถัดไป
                              onWin: () {
                                // ถ้าต้องการให้ด่านถัดไปปลดล็อกถัดไปอีก
                                // ก็ทำโค้ดต่อได้ที่นี่ หรือเว้นว่างไว้
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'ไปด่านต่อไป',
                        style: GoogleFonts.sarabun(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // ---- ถ้าผู้เล่นแพ้ แสดงปุ่ม "ตกลง" เฉย ๆ (ไม่ onWin)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // ปิด Dialog
                        Navigator.pop(ctx); // กลับหน้าเลือกด่าน
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'ตกลง',
                        style: GoogleFonts.sarabun(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        );
      },
    );
  }

  Future<void> saveGameState() async {
    print("📌 [DEBUG] saveGameState() ถูกเรียก");

    final requestBody = {
      "game_id": "scrabble_game03",
      "board": boardLetters.map((row) => row.map((cell) => cell.isEmpty ? "_" : cell).toList()).toList(),
      "rack_player1": tileRackPlayer1,
      "rack_player2": tileRackPlayer2,
      "tile_bag": tileBag,
    };

    print("📩 [DEBUG] Request body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.38:8000/save_game_state"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 [DEBUG] Response Status: ${response.statusCode}");
      print("📥 [DEBUG] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [DEBUG] saveGameState() บันทึกสำเร็จ");
      } else {
        print("❌ [ERROR] saveGameState() บันทึกล้มเหลว: ${response.body}");
      }
    } catch (e) {
      print("❌ [ERROR] saveGameState() มีปัญหา: $e");
    }
  }

  Future<void> saveGameResult({
    required String userId,
    required String gameId,
    int? levelId,
    int? roomId,
    required String gameMode,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final String apiUrl = 'http://192.168.1.38:8000/save_game';

    final Map<String, dynamic> gameData = {
      "user_id": userId,
      "level_id": levelId,
      "room_id": roomId,
      "game_mode": gameMode,
      "start_at": startAt.toIso8601String(),
      "end_at": endAt.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(gameData),
      );

      if (response.statusCode == 200) {
        print("✅ บันทึกข้อมูลเกมสำเร็จ");
      } else {
        print("❌ ไม่สามารถบันทึกข้อมูลเกมได้: ${response.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> submitWord() async {
    print("📌 [DEBUG] submitWord() ถูกเรียก");

    if (tempPlacedTiles.isEmpty) {
      _showMessage("ไม่มีตัวอักษรที่วางไว้!");
      return;
    }
    if (!_checkSingleLine(tempPlacedTiles)) {
      _showMessage("ตัวอักษรต้องอยู่ในแถวเดียวหรือคอลัมน์เดียวเท่านั้น");
      return;
    }
    if (isFirstMove && boardLetters[7][7] == "") {
      _showMessage("ตาแรกต้องคร่อมช่องกลาง (7,7)");
      return;
    }
    if (!_checkNoGap(tempPlacedTiles)) {
      _showMessage("ตัวอักษรต้องติดกัน (ไม่มีช่องว่าง)");
      return;
    }
    if (!isFirstMove && !_checkConnected(tempPlacedTiles)) {
      _showMessage("ตัวอักษรใหม่ต้องเชื่อมต่อกับคำที่มีอยู่แล้ว");
      return;
    }

    final formedWords = _getAllFormedWords(tempPlacedTiles);
    if (formedWords.isEmpty) {
      _showMessage("ไม่พบคำที่ถูกต้อง");
      return;
    }

    try {
      if (cachedDictionary == null) {
        _showMessage("กำลังโหลดคำศัพท์จาก asset กรุณาลองใหม่อีกครั้ง");
        return;
      }
      for (var fw in formedWords) {
        if (!cachedDictionary!.contains(fw.word.toString().toUpperCase())) {
          _showMessage("คำไม่ถูกต้อง: ${fw.word}");
          return;
        }
      }

      int score = formedWords.fold(0, (sum, fw) => sum + fw.word.length);
      setState(() {
        if (isPlayer1Turn) {
          player1Score += score;
        } else {
          player2Score += score;
        }
      });

      String submittedWords = formedWords.map((fw) => fw.word).join(", ");
      final List<Future<String>> translationFutures =
          formedWords.map((fw) => translateWord(fw.word)).toList();
      final List<String> translations = await Future.wait(translationFutures);
      final String translationText = translations.join(", ");

      playedWords.add({
        "player": isPlayer1Turn ? playerName : botName,
        "words": submittedWords,
        "translation": translationText,
        "score": score,
      });

      print("📌 [DEBUG] กำลังส่ง save_game_state");

      final response = await http.post(
        Uri.parse("http://192.168.1.38:8000/save_game_state"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "game_id": "scrabble_game03",  // ✅ ใช้ game_id จริง
          "board": boardLetters.map((row) => row.map((cell) => cell.isEmpty ? "_" : cell).toList()).toList(),
          "rack_player": tileRackPlayer1,
          "rack_player2": tileRackPlayer2,
          "tile_bag": tileBag,
          "playedWords": playedWords,  // ✅ บันทึกคำที่ถูกลงไปแล้ว
          "last_move_by": "ผู้เล่น 1"
        }),
      );

      print("📥 [DEBUG] save_game_state response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [DEBUG] บันทึก game_state สำเร็จ!");
      } else {
        print("❌ [ERROR] ไม่สามารถบันทึก game_state ได้: ${response.body}");
        return;
      }

      tempPlacedTiles.clear();
      if (boardLetters[7][7] != "") {
        isFirstMove = false;
      }

      final needed = 7 - getCurrentRack().length;
      if (needed > 0) {
        getCurrentRack().addAll(drawTiles(tileBag, needed));
      }
      setState(() {
        isPlayer1Turn = !isPlayer1Turn;
      });
      _startTurnTimer();
      _showMessage("$submittedWords  \n ได้คะแนน +$score   (แปล : $translationText)");

      print("📌 [DEBUG] รอ 500ms ให้เซิร์ฟเวอร์บันทึก");
      await Future.delayed(Duration(milliseconds: 500));

      print("📌 [DEBUG] โหลด game_state ใหม่ก่อนให้บอทเล่น");
      await fetchLatestGameState();

      print("📌 [DEBUG] รอ 500ms ก่อนให้บอทเล่น");
      await Future.delayed(Duration(milliseconds: 500));

      print("📌 [DEBUG] เรียก getBotMove() เพื่อให้บอทคิด");
      final botMove = await getBotMove(); // ✅ ส่ง game_id

      if (botMove.containsKey("word")) {
        String word = botMove["word"].toString();
        int row = int.parse(botMove["position"][0].toString());
        int col = int.parse(botMove["position"][1].toString());
        String direction = botMove["direction"].toString();
        int score = int.parse(botMove["score"].toString());
        List<String> newRack = List<String>.from(botMove["new_rack"].map((e) => e.toString()));

        for (int i = 0; i < word.length; i++) {
          int newRow = direction == "1" ? row + i : row;
          int newCol = direction == "0" ? col + i : col;
          placeLetterOnBoard(newRow, newCol, word[i]);
        }

      playedWords.add({
        "player": "BOT AI",
        "words": word,
        "translation": await translateWord(word),  // ใช้ฟังก์ชันแปลศัพท์
        "score": score,
      });

        print("✅ บอทวางคำว่า: $word ที่ [$row, $col] ทิศทาง $direction ได้คะแนน $score");

        setState(() {
          player2Score += score;
          tileRackPlayer2 = newRack;
          isPlayer1Turn = true;
        });

        final botResponse = await http.post(
          Uri.parse("http://192.168.1.38:8000/save_game_state"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "game_id": "scrabble_game03",
            "board": boardLetters.map((row) => row.map((cell) => cell.isEmpty ? "_" : cell).toList()).toList(),
            "rack_player": tileRackPlayer1,
            "rack_player2": tileRackPlayer2,
            "tile_bag": tileBag,
            "playedWords": playedWords,  // ✅ บันทึกคำที่บอทลง
            "last_move_by": "BOT AI"
          }),
        );

        print("📥 [DEBUG] save_game_state response (บอท): ${botResponse.statusCode} - ${botResponse.body}");

        if (botResponse.statusCode == 200) {
          print("✅ [DEBUG] บันทึก game_state สำเร็จ! (บอท)");
        } else {
          print("❌ [ERROR] ไม่สามารถบันทึก game_state ได้: ${botResponse.body}");
        }

        final needed = 7 - tileRackPlayer2.length;
        if (needed > 0) {
          tileRackPlayer2.addAll(drawTiles(tileBag, needed));  // เติมตัวอักษรจาก tileBag
        }


        print("📌 [DEBUG] โหลด game_state หลังจากบอทเล่นเสร็จ");
        await fetchLatestGameState();
    } else {
        print("🤖 บอทไม่มีคำที่สามารถลงได้ ข้ามตา");
        setState(() {
          isPlayer1Turn = true;
        });
    }

    } catch (e) {
        print("❌ [ERROR] submitWord() มีปัญหา: $e");
        _showMessage("เกิดข้อผิดพลาดในการตรวจสอบคำ: $e");
    }
}

  bool _checkNoGap(List<Map<String, dynamic>> placedTiles) {
    final rows = placedTiles.map((t) => t['row'] as int).toSet();
    final cols = placedTiles.map((t) => t['col'] as int).toSet();
    if (rows.length == 1) {
      final r = rows.first;
      final sortedCols = cols.toList()..sort();
      final startC = sortedCols.first;
      final endC = sortedCols.last;
      for (int c = startC; c <= endC; c++) {
        if (boardLetters[r][c] == "" &&
            !placedTiles.any((pt) => pt['row'] == r && pt['col'] == c)) {
          return false;
        }
      }
      return true;
    } else if (cols.length == 1) {
      final c = cols.first;
      final sortedRows = rows.toList()..sort();
      final startR = sortedRows.first;
      final endR = sortedRows.last;
      for (int r = startR; r <= endR; r++) {
        if (boardLetters[r][c] == "" &&
            !placedTiles.any((pt) => pt['row'] == r && pt['col'] == c)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  bool _checkSingleLine(List<Map<String, dynamic>> tiles) {
    final rows = tiles.map((t) => t['row'] as int).toSet();
    final cols = tiles.map((t) => t['col'] as int).toSet();
    return (rows.length == 1 || cols.length == 1);
  }

  bool _checkConnected(List<Map<String, dynamic>> tiles) {
    final newPositions = tiles.map((t) => '${t['row']},${t['col']}').toSet();
    for (var t in tiles) {
      final int r = t['row'];
      final int c = t['col'];
      if (r > 0 &&
          boardLetters[r - 1][c] != "" &&
          !newPositions.contains('${r - 1},$c')) {
        return true;
      }
      if (r < boardSize - 1 &&
          boardLetters[r + 1][c] != "" &&
          !newPositions.contains('${r + 1},$c')) {
        return true;
      }
      if (c > 0 &&
          boardLetters[r][c - 1] != "" &&
          !newPositions.contains('$r,${c - 1}')) {
        return true;
      }
      if (c < boardSize - 1 &&
          boardLetters[r][c + 1] != "" &&
          !newPositions.contains('$r,${c + 1}')) {
        return true;
      }
    }
    return false;
  }

  List<FormedWord> _getAllFormedWords(List<Map<String, dynamic>> placedTiles) {
    final foundWords = <String>{};
    final result = <FormedWord>[];
    for (var t in placedTiles) {
      final r = t['row'];
      final c = t['col'];
      final wH = _buildWordHorizontal(r, c);
      if (wH.word.length > 1 && !foundWords.contains(wH.word)) {
        result.add(wH);
        foundWords.add(wH.word);
      }
      final wV = _buildWordVertical(r, c);
      if (wV.word.length > 1 && !foundWords.contains(wV.word)) {
        result.add(wV);
        foundWords.add(wV.word);
      }
    }
    return result;
  }

  FormedWord _buildWordHorizontal(int r, int c) {
    int startCol = c;
    while (startCol > 0 && boardLetters[r][startCol - 1] != "") {
      startCol--;
    }
    int endCol = c;
    while (endCol < boardSize - 1 && boardLetters[r][endCol + 1] != "") {
      endCol++;
    }
    final sb = StringBuffer();
    final letterPositions = <LetterPos>[];
    for (int cc = startCol; cc <= endCol; cc++) {
      final letter = boardLetters[r][cc];
      sb.write(letter);
      letterPositions.add(LetterPos(row: r, col: cc, letter: letter));
    }
    return FormedWord(word: sb.toString(), letters: letterPositions);
  }

  FormedWord _buildWordVertical(int r, int c) {
    int startRow = r;
    while (startRow > 0 && boardLetters[startRow - 1][c] != "") {
      startRow--;
    }
    int endRow = r;
    while (endRow < boardSize - 1 && boardLetters[endRow + 1][c] != "") {
      endRow++;
    }
    final sb = StringBuffer();
    final letterPositions = <LetterPos>[];
    for (int rr = startRow; rr <= endRow; rr++) {
      final letter = boardLetters[rr][c];
      sb.write(letter);
      letterPositions.add(LetterPos(row: rr, col: c, letter: letter));
    }
    return FormedWord(word: sb.toString(), letters: letterPositions);
  }

  void _showMessage(String msg) {
    setState(() {
      _notificationMessage = msg;
    });
  }

  void _showBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings, color: Colors.deepOrange),
                title: Text("ตั้งค่า", style: GoogleFonts.sarabun()),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_bag, color: Colors.blueAccent),
                title: Text("ตัวอักษรที่เหลือ", style: GoogleFonts.sarabun()),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRemainingTiles();
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.green),
                title: Text("ประวัติ", style: GoogleFonts.sarabun()),
                onTap: () {
                  Navigator.pop(ctx);
                  showHistoryDialog(context, playedWords);
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: Text("ยอมแพ้", style: GoogleFonts.sarabun()),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGiveUpDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGiveUpDialog() async {
    bool? confirmed = await showConfirmDialog(
        context, "ยืนยันการยอมแพ้", "คุณแน่ใจหรือว่าต้องการยอมแพ้?");
    if (confirmed == true) {
      _handleGiveUp();
    }
  }

  void _handleGiveUp() {
    String winner = isPlayer1Turn ? botName : playerName;
    _showMessage("$winner ชนะโดยที่ฝ่ายตรงข้ามยอมแพ้!");
    _endGame(winner);
  }

  void _showRemainingTiles() {
    Map<String, int> letterCount = {};
    for (String letter in tileBag) {
      letterCount[letter] = (letterCount[letter] ?? 0) + 1;
    }
    List<String> normalLetters = [];
    List<String> specialLetters = [];
    letterCount.forEach((letter, count) {
      if (letter == '*') {
        specialLetters.add(letter);
      } else {
        normalLetters.add(letter);
      }
    });
    normalLetters.sort((a, b) => a.compareTo(b));
    List<String> allLetters = [];
    allLetters.addAll(normalLetters);
    allLetters.addAll(specialLetters);
    int totalRemaining =
        letterCount.values.fold(0, (prev, element) => prev + element);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text("ตัวอักษรที่เหลือ : $totalRemaining ตัว",
                style: GoogleFonts.prompt()),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allLetters.map((letter) {
                    int count = letterCount[letter] ?? 0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
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
                              Center(
                                child: Text(letter,
                                    style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("$count",
                            style: GoogleFonts.sarabun(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red))
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("ปิด", style: GoogleFonts.sarabun()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomScoreBoard() {
    return ScoreBoardWidget(
      remainingSeconds: currentRemainingSeconds,
      player1Score: player1Score,
      player2Score: player2Score,
      notificationMessage: _notificationMessage,
      isPlayer1Turn: isPlayer1Turn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRack = isPlayer1Turn ? tileRackPlayer1 : tileRackPlayer2;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
          child: Column(
            children: [
              _buildCustomScoreBoard(),
              const SizedBox(height: 10),
              Expanded(
                child: BoardWidget(
                  boardLetters: boardLetters,
                  onPlaceLetter: placeLetterOnBoard,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              TileRackWidget(letters: currentRack),
              ControlPanelWidget(
                onShowMenu: _showBottomSheetMenu,
                onExchange: exchangeTiles,
                onSubmit: submitWord,
                onUndo: pullBackAllTiles,
                onSkip: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("ยืนยันการข้ามเทิร์น",
                            style: TextStyle(fontFamily: 'UncialAntiqua')),
                        content: const Text("คุณแน่ใจหรือว่าต้องการข้ามเทิร์น?",
                            style: TextStyle(fontFamily: 'UncialAntiqua')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _turnTimer?.cancel();
                              skipTurn();
                            },
                            child: const Text("ข้ามเทิร์น"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
