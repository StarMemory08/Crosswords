import gym
import numpy as np
import random
from collections import Counter
import psycopg2  # ใช้สำหรับเชื่อมต่อฐานข้อมูล PostgreSQL
from gym import spaces  # ใช้สำหรับกำหนด Action Space ใน Reinforcement Learning


class ScrabbleEnv(gym.Env):
    
    def load_word_database(self):
        """โหลดฐานข้อมูลคำศัพท์จาก PostgreSQL"""
        word_set = set()  # ✅ ใช้ตัวแปรภายในก่อน
        
        try:
            connection = psycopg2.connect(
                user="starmemory",
                password="12345678",
                host="127.0.0.1",
                port="5432",
                database="crossword_db"
            )
            with connection.cursor() as cursor:
                cursor.execute('SELECT "word_name" FROM words;')  
                word_set = {row[0].lower() for row in cursor.fetchall()}  

            print(f"📖 โหลดคำศัพท์จากฐานข้อมูลสำเร็จ: {len(word_set)} คำ")

        except Exception as e:
            print(f"❌ ไม่สามารถโหลดคำศัพท์จากฐานข้อมูลได้: {e}")
        
        finally:
            if connection:
                connection.close()
        
        return word_set  # ✅ คืนค่า set() ของคำศัพท์

    def __init__(self, game_id=None, board=None, rack=None, tile_bag=None):
        """กำหนดค่าพื้นฐานของ Scrabble Environment"""
        super(ScrabbleEnv, self).__init__()

        # ✅ โหลดฐานข้อมูลคำศัพท์
        self.word_database = self.load_word_database()
        self.game_id = game_id

        # ✅ กำหนดค่าจาก game_state
        self.board = np.array(board) if board is not None else np.full((15, 15), "", dtype=object)
        self.tile_bag = tile_bag if tile_bag is not None else self.generate_tile_bag()
        
        # ✅ ใช้ rack จาก game_state ถ้ามี ไม่ใช้ draw_tiles()
        self.rack = rack if rack is not None else []
        
        self.is_first_move = True  # ใช้เพื่อตรวจสอบว่าคำแรกลงหรือยัง
        self.score = 0  # คะแนนของผู้เล่น

        self.setup_board_layout()
        # ✅ รองรับการฝึกบอทในอนาคต
        self.action_space = spaces.MultiDiscrete([15, 15, 2])  # (row, col, direction)
        self.observation_space = spaces.Box(low=0, high=1, shape=(15, 15), dtype=np.int32)

        print(f"✅ Scrabble Environment Initialized!")
        print(f"🔹 Rack ของผู้เล่น: {self.rack}")
        print(f"🔹 จำนวน Tiles ที่เหลือ: {len(self.tile_bag)}")


    def reset(self):
        """รีเซ็ตเกมใหม่"""
        
        # ✅ สร้างกระเป๋าอักษรใหม่
        self.tile_bag = self.generate_tile_bag()
        
        # ✅ ล้างกระดาน และกำหนดช่องพิเศษใหม่
        self.board = np.full((15, 15), "", dtype=object)  # ใช้ "" แทน 0
        self.setup_board_layout()

        # ✅ สุ่ม Rack ของผู้เล่นใหม่
        self.rack = self.draw_tiles(7)

        # ✅ รีเซ็ตสถานะเกม
        self.is_first_move = True  
        self.score = 0  

        print("🔄 เกมถูกรีเซ็ต!")
        print(f"🔹 Rack ใหม่: {self.rack}")
        print(f"🔹 Tile Bag เหลือ: {len(self.tile_bag)}")

        # ✅ คืนค่า state ใหม่ของเกม (ถ้าใช้ RL)
        return self.get_state()

    def generate_tile_bag(self):
        """ สร้างกระเป๋าตัวอักษรสำหรับ Scrabble โดยมีจำนวนตัวอักษรตามที่กำหนด """
        tile_distribution = {
            'A': 9, 'B': 2, 'C': 2, 'D': 4, 'E': 12, 'F': 2, 'G': 3, 'H': 2,
            'I': 9, 'J': 1, 'K': 1, 'L': 4, 'M': 2, 'N': 6, 'O': 8, 'P': 2,
            'Q': 1, 'R': 6, 'S': 4, 'T': 6, 'U': 4, 'V': 2, 'W': 2, 'X': 1,
            'Y': 2, 'Z': 1
        }

        tile_bag = []
        for letter, count in tile_distribution.items():
            tile_bag.extend([letter] * count)  # ✅ ใส่ตัวอักษรตามจำนวนที่กำหนด

        random.shuffle(tile_bag)  # ✅ สุ่มกระเป๋าอักษรให้เป็นแบบสุ่ม
        print(f"🎲 สร้างกระเป๋าอักษรสำเร็จ! มีตัวอักษรทั้งหมด: {len(tile_bag)}")
        return tile_bag

    def draw_tiles(self, count=7):
        """เติม rack ด้วยตัวอักษรจาก tile_bag จนเต็ม 7 ตัว"""

        if self.rack is None:
            self.rack = []
        
        print(f"🔍 จำนวน Tile ที่เหลือใน bag: {len(self.tile_bag)}")  

        while len(self.rack) < count and self.tile_bag:
            new_tile = self.tile_bag.pop(0)
            self.rack.append(new_tile)
            print(f"🟢 เติมตัวอักษร '{new_tile}' เข้า rack (กระเป๋าเหลือ {len(self.tile_bag)} ตัว)")

        print(f"✅ Rack ปัจจุบัน (หลังเติม): {self.rack}")  
        return self.rack

    def setup_board_layout(self):
        """ กำหนดช่องพิเศษในกระดาน Scrabble ตามกติกา """
        self.board_layout = np.array(self.board) if self.board is not None else np.full((15, 15), "", dtype=object)

        # ✅ Triple Word (TW) - x3 คำศัพท์
        for r, c in [(0, 0), (0, 7), (0, 14), (7, 0), (7, 14), (14, 0), (14, 7), (14, 14)]:
            self.board_layout[r, c] = "TW"

        # ✅ Double Word (DW) - x2 คำศัพท์
        for r, c in [(1, 1), (2, 2), (3, 3), (4, 4), (1, 13), (2, 12), (3, 11), (4, 10),
                    (13, 1), (12, 2), (11, 3), (10, 4), (13, 13), (12, 12), (11, 11), (10, 10)]:
            self.board_layout[r, c] = "DW"

        # ✅ Triple Letter (TL) - x3 ตัวอักษร
        for r, c in [(1, 5), (1, 9), (5, 1), (5, 5), (5, 9), (5, 13), (9, 1), (9, 5),
                    (9, 9), (9, 13), (13, 5), (13, 9)]:
            self.board_layout[r, c] = "TL"

        # ✅ Double Letter (DL) - x2 ตัวอักษร
        for r, c in [(0, 3), (0, 11), (2, 6), (2, 8), (3, 0), (3, 7), (3, 14), (6, 2),
                    (6, 6), (6, 8), (6, 12), (7, 3), (7, 11), (8, 2), (8, 6), (8, 8),
                    (8, 12), (11, 0), (11, 7), (11, 14), (12, 6), (12, 8), (14, 3), (14, 11)]:
            self.board_layout[r, c] = "DL"

        # ✅ ช่องเริ่มต้น (STAR) ที่ 7,7
        self.board_layout[7, 7] = "STAR"

        print("✅ กระดาน Scrabble พร้อมใช้งาน! ช่องพิเศษถูกตั้งค่าแล้ว")

    def get_board_string(self):
        """
        แปลงกระดานจากตัวเลข ASCII กลับเป็นตัวอักษร เพื่อให้อ่านง่ายขึ้น
        - ใช้ '.' แทนช่องว่าง
        """
        return "\n".join(
            " ".join(str(cell) if cell != "" else '.' for cell in row)
            for row in self.board
        )

    def is_board_empty(self):
        """
        ✅ ตรวจสอบว่ากระดาน Scrabble ว่างเปล่าหรือไม่
        """
        return np.all(self.board == "")  # ✅ เปลี่ยนจาก == 0 เป็น == ""

    
    def get_valid_positions(self):
        """
        ✅ หาตำแหน่งที่สามารถวางคำได้จริง
        """
        if self.is_board_empty():
            print("✅ กระดานว่าง → บังคับให้เริ่มที่ (7,7)")
            return {(7, 7)}

        valid_positions = set()
        used_letters_positions = set()  # ✅ เก็บตำแหน่งที่มีตัวอักษรอยู่แล้ว

        for row in range(15):
            for col in range(15):
                if self.board[row][col] != "" and self.board[row][col].strip() != "":  
                    used_letters_positions.add((row, col))  # ✅ ตำแหน่งที่มีตัวอักษร
                elif self.has_adjacent_letter(row, col):  
                    valid_positions.add((row, col))  # ✅ ตำแหน่งที่วางคำใหม่ได้

        print(f"📌 Debug: used_letters_positions -> {used_letters_positions}")
        print(f"📌 Debug: valid_positions ก่อนเช็ค -> {valid_positions}")

        return valid_positions  # ✅ คืนค่าตำแหน่งที่สามารถใช้ได้

    def get_surrounding_positions(self, last_positions):
        """
        ✅ หาตำแหน่งรอบๆ คำที่ลงไปล่าสุดที่สามารถใช้วางคำใหม่ได้
        ✅ ตรวจสอบว่าต้องเชื่อมกับตัวอักษรที่มีอยู่บนกระดานจริงๆ
        """
        print(f"📌 Debug: last_positions -> {last_positions}")  # ✅ ตรวจสอบค่าที่ส่งเข้ามา

        surrounding_positions = set()

        for row, col in last_positions:
            neighbors = [
                (row-1, col), (row+1, col),
                (row, col-1), (row, col+1)
            ]

            for r, c in neighbors:
                if 0 <= r < 15 and 0 <= c < 15 and self.board[r][c] == "":  # ✅ แก้จาก 0 เป็น ""
                    surrounding_positions.add((r, c))

        if not surrounding_positions:
            print("⚠️ get_surrounding_positions() คืนค่า set() ว่าง! แก้ให้ใช้ get_valid_positions() แทน")
            surrounding_positions = self.get_valid_positions()  # ✅ ใช้ fallback method
            print(f"📌 Debug: get_valid_positions() fallback -> {surrounding_positions}")

        print(f"📌 Debug: get_surrounding_positions() -> {surrounding_positions}")
        return surrounding_positions





    def has_adjacent_letter(self, row, col):
        """
        ✅ ตรวจสอบว่าตำแหน่ง (row, col) มีตัวอักษรอยู่ข้าง ๆ หรือไม่
        """
        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # ⬆⬇⬅➡
        
        for dr, dc in directions:
            nr, nc = row + dr, col + dc
            if 0 <= nr < 15 and 0 <= nc < 15 and self.board[nr][nc] not in ["", " "]:  
                return True  # ✅ ถ้ามีตัวอักษรอยู่ติดกัน → คืนค่า True

        return False  # ❌ ถ้าไม่มีตัวอักษรอยู่ติดกันเลย → คืนค่า False







    def letter_score(self, letter):
        """คืนค่าคะแนนของตัวอักษรใน Scrabble"""
        letter_values = {
            "A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4, "I": 1,
            "J": 8, "K": 5, "L": 1, "M": 3, "N": 1, "O": 1, "P": 3, "Q": 10, "R": 1,
            "S": 1, "T": 1, "U": 1, "V": 4, "W": 4, "X": 8, "Y": 4, "Z": 10
        }
        return letter_values.get(letter.upper(), 0)  # คืนค่า ถ้าไม่มีให้เป็น 0
    
    def get_valid_words_from_db(self):
        if self.word_database is None:
            self.load_word_database()

        if not self.word_database:
            print("❌ `word_database` ไม่มีคำให้ใช้")
            return []

        possible_words = set(self.word_database)  
        rack_counter = Counter(letter.upper() for letter in self.rack_bot)

        valid_words = []
        for word in possible_words:
            word_upper = word.upper()
            word_counter = Counter(word_upper)

            # ✅ ตรวจสอบว่ามีตัวอักษรเพียงพอ และให้เลือกคำที่มีความยาวมากกว่า 2 ตัวอักษร
            if len(word_upper) > 2 and all(word_counter[char] <= rack_counter.get(char, 0) for char in word_upper):
                valid_words.append(word_upper)

        # ✅ จัดเรียงคำที่เป็นไปได้จากคำยาวไปสั้น เพื่อให้บอทเลือกคำที่ดีที่สุด
        valid_words.sort(key=len, reverse=True)

        print(f"📖 คำที่สามารถใช้จาก rack {self.rack_bot}: {valid_words[:10]}")  
        return valid_words


    def filter_valid_word(self, possible_words):
        """
        ✅ ปรับให้รองรับการเล่นคำแรกเมื่อกระดานยังว่าง
        """
        valid_words = []
        existing_letters = {
            (r, c): str(self.board[r][c]).upper() for r in range(15) for c in range(15) if self.board[r][c] != ""
        }

        print(f"📌 Debug: ตัวอักษรที่มีอยู่บนกระดาน: {existing_letters}")

        valid_positions = self.get_valid_positions()  # ✅ ดึงตำแหน่งที่สามารถวางคำได้
        print(f"📌 Debug: valid_positions -> {valid_positions}")

        for word in possible_words:
            word_upper = word.upper()
            rack_counter = Counter(letter.upper() for letter in self.rack_bot)
            word_counter = Counter(word_upper)

            can_form = True
            used_board_letters = set()

            if self.is_board_empty():
                # ✅ ถ้ากระดานยังว่าง คำต้องเริ่มที่ (7,7) และขยายออกไปทางขวาหรือแนวตั้ง
                if len(word) <= 7:
                    valid_words.append(word_upper)
                    continue  # ✅ ข้ามเงื่อนไขอื่น เพราะคำแรกลงได้แน่
                else:
                    print(f"❌ ตัดคำ '{word_upper}' ออก เพราะยาวเกินไปสำหรับคำแรก")
                    continue

            # ✅ ตรวจสอบว่ามีตัวอักษรพอจาก rack + กระดาน
            for char in word_upper:
                if word_counter[char] > rack_counter.get(char, 0) + list(existing_letters.values()).count(char):
                    can_form = False
                    break

            # ✅ ตรวจสอบว่ามีตำแหน่งที่สามารถวางคำได้จริง
            can_place = False
            for pos in valid_positions:
                if self.is_valid_placement(pos[0], pos[1], word_upper, direction=0) or \
                self.is_valid_placement(pos[0], pos[1], word_upper, direction=1):
                    can_place = True
                    break

            if can_form and (self.is_board_empty() or can_place):
                valid_words.append(word_upper)

        print(f"📖 คำที่เหลือหลังจากกรอง: {valid_words}")  
        return valid_words












    def is_valid_placement(self, row, col, word, direction):
        """
        ✅ ตรวจสอบว่าสามารถวางคำที่จุด (row, col) ได้หรือไม่
        """
        if self.is_board_empty():
            if direction == 0 and not any(c == 7 for c in range(col, col + len(word))):
                print(f"❌ คำ '{word}' ไม่ผ่านตำแหน่ง (7,7)")
                return False
            elif direction == 1 and not any(r == 7 for r in range(row, row + len(word))):
                print(f"❌ คำ '{word}' ไม่ผ่านตำแหน่ง (7,7)")
                return False
            return True  

        if direction == 0 and (col + len(word) > 15):
            return False
        if direction == 1 and (row + len(word) > 15):
            return False

        has_adjacent = False
        used_existing_letters = False  

        for i, letter in enumerate(word):
            r, c = (row, col + i) if direction == 0 else (row + i, col)

            if self.board[r][c] != "" and self.board[r][c] != letter:
                print(f"❌ ตำแหน่ง ({r}, {c}) มี '{self.board[r][c]}' อยู่แล้ว")
                return False  

            if self.has_adjacent_letter(r, c):
                has_adjacent = True

            if self.board[r][c] != "":  
                used_existing_letters = True

        if not has_adjacent and not self.is_board_empty():
            print(f"❌ คำ '{word}' ไม่มีตัวอักษรติดกัน")
            return False

        if not used_existing_letters and not self.is_board_empty():
            print(f"❌ คำ '{word}' ไม่ได้ใช้ตัวอักษรจากกระดาน")
            return False

        print(f"✅ คำ '{word}' สามารถวางที่ ({row}, {col}) ได้")
        return True

    def place_word(self, word, row, col, direction):
        """
        ✅ แก้ไขให้เช็คว่าคำใหม่ที่เกิดขึ้นต้องมีอยู่ในฐานข้อมูลก่อนวาง
        """
        if not self.is_valid_placement(row, col, word, direction):
            print(f"❌ ERROR: คำ '{word}' ไม่สามารถวางที่ ({row}, {col}) ได้")
            return False

        placed_positions = []

        # ✅ วางตัวอักษรลงกระดานชั่วคราวเพื่อเช็คคำใหม่ที่เกิดขึ้น
        for i, letter in enumerate(word):
            r, c = (row, col + i) if direction == 0 else (row + i, col)

            if self.board[r][c] == "":  # ✅ ใช้ "" แทน 0
                self.board[r][c] = letter
                placed_positions.append((r, c))

        # ✅ ดึงคำใหม่ที่เกิดขึ้นจากการวาง
        new_words = self.get_new_words(placed_positions)

        # ❌ **เช็คว่าคำทั้งหมดต้องมีในฐานข้อมูล**
        invalid_words = [new_word for new_word in new_words if new_word.lower() not in self.word_database]

        if invalid_words:
            print(f"❌ ERROR: คำ {invalid_words} ไม่มีในฐานข้อมูล! ยกเลิกการวาง")
            
            # ❌ ยกเลิกการวางและคืนค่ากระดานเดิม
            for r, c in placed_positions:
                self.board[r][c] = ""  # ✅ ลบคำที่เพิ่งวางไป
            return False

        # ✅ ลบตัวอักษรที่ใช้ไปจาก rack
        self.remove_used_letters(word, row, col, direction)

        # ✅ อัปเดตสถานะเกม
        if self.is_first_move:
            self.is_first_move = False

        self.print_board()
        return True


    
    def remove_used_letters(self, word, row, col, direction):
        """
        ✅ ลบตัวอักษรที่ใช้จาก rack โดยพิจารณาว่าตัวอักษรนั้นมีอยู่บนกระดานแล้วหรือไม่
        """
        print(f"📌 Debug: remove_used_letters -> ก่อนลบ rack: {self.rack}")
        
        new_rack = list(self.rack_bot)  # ✅ สำเนา rack ปัจจุบัน เพื่อป้องกันการเปลี่ยนแปลงที่ผิดพลาด

        for i, letter in enumerate(word):
            r, c = (row, col + i) if direction == 0 else (row + i, col)

            # ✅ ถ้าตัวอักษรนี้ไม่ได้อยู่บนกระดานมาก่อน ให้ลบออกจาก rack
            if (self.board[r][c] == letter) and (letter in new_rack):
                new_rack.remove(letter)  # ❌ เดิมใช้ผิดเงื่อนไข อัปเดตให้ลบเฉพาะอักษรที่ลงใหม่เท่านั้น
                print(f"✅ ลบ '{letter}' ออกจาก rack (ตำแหน่ง {r}, {c})")

        self.rack_bot = new_rack  # ✅ อัปเดต rack ใหม่
        print(f"✅ Debug: remove_used_letters -> หลังลบ rack: {self.rack}")





    def calculate_score(self, word, row, col, direction):
        """
        ✅ แก้ไขให้ตรวจสอบคำที่เกิดขึ้นว่าต้องมีในฐานข้อมูลก่อนให้คะแนน
        """
        base_score = 0
        word_multiplier = 1
        placed_positions = []

        for i, letter in enumerate(word):
            r, c = (row, col + i) if direction == 0 else (row + i, col)
            letter_value = self.letter_score(letter)

            if self.board[r][c] != "" and self.board[r][c] != letter:
                base_score += letter_value
                continue

            placed_positions.append((r, c))

            cell_type = self.board_layout[r][c]
            if cell_type == "DL":
                base_score += letter_value * 2
            elif cell_type == "TL":
                base_score += letter_value * 3
            elif cell_type in ["DW", "STAR"]:
                word_multiplier *= 2
                base_score += letter_value
            elif cell_type == "TW":
                word_multiplier *= 3
                base_score += letter_value
            else:
                base_score += letter_value

        # ✅ ตรวจสอบคำใหม่ที่เกิดขึ้นจากการวาง
        new_words = self.get_new_words(placed_positions)
        additional_score = 0

        for new_word in new_words:
            if new_word.lower() not in self.word_database:
                print(f"❌ ERROR: คำ '{new_word}' ไม่มีในฐานข้อมูล! คะแนนคำนี้เป็น 0")
                return 0  # ❌ **ถ้ามีคำผิด คะแนนเป็น 0 ทันที**

            word_score = sum(self.letter_score(letter) for letter in new_word)
            additional_score += word_score

        total_score = (base_score * word_multiplier) + additional_score
        print(f"✅ คำนวณคะแนนของ '{word}' ได้ {total_score} คะแนน")
        return total_score




    def get_word_vertical(self, row, col):
        """
        ✅ ดึงคำแนวตั้งจากจุดที่กำหนด (แก้ปัญหาการรวมคำผิดพลาด)
        ✅ เช็คว่ามีช่องว่าง ("") หรือไม่ก่อนรวม
        """
        start_row = row
        while start_row > 0 and self.board[start_row - 1][col] != "":
            start_row -= 1

        end_row = row
        while end_row < 14 and self.board[end_row + 1][col] != "":
            end_row += 1

        # ตรวจสอบว่ามีช่องว่างแยกคำหรือไม่
        word = ""
        for r in range(start_row, end_row + 1):
            if self.board[r][col] == "":
                break  # เจอช่องว่างให้หยุด
            word += self.board[r][col]

        print(f"🔍 get_word_vertical({row}, {col}) -> '{word}'")
        return word.strip()


    def get_word_horizontal(self, row, col):
        """
        ✅ ดึงคำแนวนอนจากจุดที่กำหนด (แก้ปัญหาการรวมคำผิดพลาด)
        ✅ เช็คว่ามีช่องว่าง ("") หรือไม่ก่อนรวม
        """
        start_col = col
        while start_col > 0 and self.board[row][start_col - 1] != "":
            start_col -= 1

        end_col = col
        while end_col < 14 and self.board[row][end_col + 1] != "":
            end_col += 1

        # ตรวจสอบว่ามีช่องว่างแยกคำหรือไม่
        word = ""
        for c in range(start_col, end_col + 1):
            if self.board[row][c] == "":
                break  # เจอช่องว่างให้หยุด
            word += self.board[row][c]

        print(f"🔍 get_word_horizontal({row}, {col}) -> '{word}'")
        return word.strip()



    def get_new_words(self, word_positions):
        new_words = set()

        for r, c in word_positions:
            vertical_word = self.get_word_vertical(r, c)
            horizontal_word = self.get_word_horizontal(r, c)

            print(f"🔍 คำแนวตั้ง: '{vertical_word}', คำแนวนอน: '{horizontal_word}'")

            if len(vertical_word) > 1:
                new_words.add(vertical_word)

            if len(horizontal_word) > 1:
                new_words.add(horizontal_word)

        print(f"✅ คำใหม่ที่พบ: {new_words}")
        return list(new_words)


    def should_exchange_tiles(self):
        possible_words = self.get_valid_words_from_db()
        valid_words = self.filter_valid_word(possible_words)  # ✅ คำนวณใหม่แทนการใช้ self.valid_words

        return len(valid_words) == 0 and len(self.rack) > 0 and len(self.tile_bag) > len(self.rack)




    def exchange_tiles(self):
        if self.should_exchange_tiles():
            num_to_exchange = min(7, len(self.rack))  # ✅ แลกเปลี่ยนได้สูงสุด 7 ตัว
            tiles_to_exchange = random.sample(self.rack, num_to_exchange)

            # 🔄 นำตัวอักษรเดิมกลับไปในกระเป๋า
            self.tile_bag.extend(tiles_to_exchange)

            # ลบตัวอักษรที่แลกออกจาก rack
            self.rack = [tile for tile in self.rack if tile not in tiles_to_exchange]

            # ✅ ดึงตัวอักษรใหม่จากกระเป๋า
            random.shuffle(self.tile_bag)  # สุ่มกระเป๋าตัวอักษรก่อนดึง
            for _ in range(num_to_exchange):
                if self.tile_bag:
                    self.rack.append(self.tile_bag.pop())

            print(f"🔄 บอทแลกตัวอักษร {tiles_to_exchange} → ได้ตัวใหม่ {self.rack}")
            return tiles_to_exchange



    def select_word_from_rack(self):
        """
        ✅ บอทต้องเลือกคำที่มีอยู่ใน rack และสามารถวางได้จริง
        """
        print(f"🛠️ บอทกำลังเลือกคำจาก rack -> board type: {type(self.board)}")
        possible_words = self.get_valid_words_from_db()
        valid_words = self.filter_valid_word(possible_words)

        if not valid_words:
            print("❌ ไม่มีคำที่สามารถวางได้ → บอท pass รอบนี้")
            return {"move": "pass"}  # ✅ ไม่สุ่มคำจากฐานข้อมูลแล้ว

        valid_positions = self.get_valid_positions()
        print(f"📌 Debug: get_valid_positions() -> {valid_positions}")

        best_placement = self.find_best_placement(valid_words, valid_positions)
        if best_placement is None:
            print("❌ ไม่มีคำที่สามารถวางได้ → บอท pass รอบนี้")
            return {"move": "pass"}  

        best_word, best_position = best_placement
        print(f"✅ เลือกคำ '{best_word}' ที่ตำแหน่ง {best_position}")
        return {"move": "play", "word": best_word, "position": best_position}




    def find_best_placement(self, valid_words, last_positions):
        if not valid_words:
            print("⚠️ ไม่มีคำที่สามารถเล่นได้")
            return None

        best_position = None
        best_score = -1
        best_word = None

        valid_positions = self.get_valid_positions()
        print(f"🔍 ตำแหน่งที่สามารถวางได้: {valid_positions}")

        for word in valid_words:
            for row, col in valid_positions:
                for direction in [0, 1]:  # แนวนอน, แนวตั้ง
                    if self.is_valid_placement(row, col, word, direction):
                        score = self.calculate_score(word, row, col, direction)
                        print(f"📌 ทดสอบวาง '{word}' ที่ ({row}, {col}) -> คะแนน: {score}")

                        if score > best_score:
                            best_score = score
                            best_position = (row, col, direction)
                            best_word = word

        if best_position:
            print(f"✅ เลือกคำ '{best_word}' ที่ตำแหน่ง {best_position} (คะแนน: {best_score})")
            return best_word, best_position

        print("❌ ไม่มีตำแหน่งให้วางคำได้เลย")
        return None






    def get_placed_positions(self, word, row, col, direction):
        """
        ✅ ดึงตำแหน่งของตัวอักษรที่ถูกวางจริง
        """
        return [(row + i, col) if direction == 1 else (row, col + i) for i in range(len(word))]

    def get_state(self):
        """
        ✅ แปลงสถานะกระดานเป็นตัวเลข (แทนตัวอักษรด้วยคะแนน Scrabble)
        """
        def letter_to_score(letter):
            """แปลงตัวอักษรเป็นคะแนน Scrabble"""
            if letter == "":
                return 0
            return self.letter_score(letter)  # ✅ เรียกจาก self

        board_numeric = np.vectorize(letter_to_score)(self.board)  # ใช้ vectorized function
        return board_numeric.astype(np.float32)  # ✅ return อยู่ในฟังก์ชัน

    
    def get_game_state(self):
        return {
            "board": self.board.tolist(),  
            "rack_player1": self.rack,  # ✅ เปลี่ยนให้ชัดเจนว่าเป็นของผู้เล่น
            "rack_player2": self.rack_bot,  # ✅ เพิ่ม rack ของบอทให้แน่ใจว่าไม่หาย
            "tile_bag": self.tile_bag
        }


    def step(self, action):
        """
        ✅ PPO จะเรียก step() โดยส่ง action มา
        - action = [row, col, direction]
        - ใช้ action นี้วางคำลงกระดาน
        - คำนวณคะแนนที่ได้เป็น reward
        - คืนค่า (state ใหม่, reward, done, info)
        """
        row, col, direction = action

        # ✅ หา "คำที่ดีที่สุด" จาก rack หรือแลกตัวอักษรถ้าจำเป็น
        move = self.select_word_from_rack()

        if move["move"] == "exchange":
            exchanged_tiles = move["tiles"]
            print(f"🔄 บอทแลกเปลี่ยนตัวอักษร: {exchanged_tiles}")

            # ✅ ลด penalty เพื่อให้บอทยอมแลกตัวอักษรเฉพาะกรณีจำเป็น
            return self.get_state(), -1, False, {}

        if move["move"] == "pass":
            print("🚫 บอทข้ามตา")
            
            # ✅ ปรับให้ pass ได้แต่ไม่จบเกมทันที
            return self.get_state(), -5, False, {}

        # ✅ วางคำที่เลือก
        word, placement = move["word"], move["position"]
        row, col, direction = placement
        success = self.place_word(word, row, col, direction)

        if success:
            score = self.calculate_score(word, row, col, direction)

            # ✅ ให้โบนัสเพิ่มถ้าวางคำติดกับคำอื่น
            has_adjacent = any(self.has_adjacent_letter(row + (i if direction == 1 else 0),
                                                        col + (i if direction == 0 else 0))
                                for i in range(len(word)))
            
            bonus = 5 if has_adjacent else 0  # ✅ เพิ่มโบนัสเพื่อให้ PPO ชอบวางคำติดกัน
            reward = score + bonus  

            print(f"✅ วาง '{word}' สำเร็จ ได้คะแนน: {score} (+{bonus} bonus)")

            self.remove_used_letters(word, row, col, direction)
            self.draw_tiles()
        else:
            print(f"❌ ไม่สามารถวาง '{word}' ได้")
            reward = -3  # ❌ ลดค่ามากขึ้นหากวางคำไม่ได้ เพื่อป้องกัน PPO วางพลาดบ่อย ๆ

        # ✅ ตรวจสอบว่าหมดตัวอักษรหรือไม่
        done = len(self.rack) == 0 or not self.tile_bag

        return self.get_state(), reward, done, {}




    def print_board(self):
        """
        ✅ แสดงกระดาน Scrabble โดยใช้ '.' แทนช่องว่าง
        """
        print("\n📌 กระดาน Scrabble:\n")
        board_str = "\n".join(
            " ".join(str(cell) if cell != "" else '.' for cell in row) for row in self.board
        )
        print(board_str)




    
    

    
 


    
    

