import json
import redis
import psycopg2
import numpy as np
import os
import atexit
from fastapi.responses import JSONResponse
from fastapi import FastAPI, HTTPException, Request, Depends
from pydantic import BaseModel
import bcrypt
from stable_baselines3 import PPO
from lib.services.scrabble_env import ScrabbleEnv
from psycopg2 import pool
import random
from collections import Counter
from typing import List, Optional
import time
import uuid
import base64
import smtplib
from email.mime.text import MIMEText
from gym import spaces
from datetime import datetime 
from lib.services.game_state import load_game_state, save_game_state

env = ScrabbleEnv()
app = FastAPI()

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_SENDER = "teramate3030@gmail.com"
EMAIL_PASSWORD = "oabp qtmx mnke mfcd" 

# ✅ เชื่อมต่อ Redis
try:
    redis_client = redis.StrictRedis(
        host="localhost",
        port=6379,
        db=0,
        decode_responses=True,
        socket_timeout=5,  # ตั้ง Timeout 5 วินาที
        retry_on_timeout=True  # ให้ลองใหม่ถ้า Timeout
    )
    print("✅ Connected to Redis")
except Exception as e:
    print(f"❌ Redis Connection Error: {e}")
    redis_client = None

# ✅ ตั้งค่าการเชื่อมต่อ PostgreSQL (ใช้ Connection Pool)
DB_CONFIG = {
    "user": "starmemory",
    "password": "12345678",
    "host": "127.0.0.1",
    "port": "5432",
    "database": "crossword_db"
}

try:
    db_pool = psycopg2.pool.ThreadedConnectionPool(
        minconn=5,  # จำนวน Connection ต่ำสุด
        maxconn=20,  # จำนวน Connection สูงสุด
        **DB_CONFIG
    )
    print("✅ Connected to PostgreSQL")
except Exception as e:
    print(f"❌ PostgreSQL Connection Error: {e}")
    db_pool = None

def get_db_connection():
    conn = db_pool.getconn()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    return conn

# ✅ ฟังก์ชันคืน Connection กลับไปที่ Pool
def release_db_connection(conn):
    if conn:
        db_pool.putconn(conn)

# ✅ ใช้ FastAPI Dependency Injection เพื่อจัดการ Connection อัตโนมัติ
def get_db():
    conn = get_db_connection()
    try:
        yield conn
    finally:
        release_db_connection(conn)  # คืน Connection เสมอ

# ✅ โหลดโมเดล AI
model_path = os.path.join(os.path.dirname(__file__), "bot005.zip")
model = PPO.load(model_path) if os.path.exists(model_path) else None

class GameStateRequest(BaseModel):
    game_id: str
    board: List[List[str]]
    rack_player: List[str] 
    rack_player2: List[str]  
    tile_bag: List[str]
    playedWords: List[dict] = []  
    last_move_by: str
    
# 📌 โครงสร้างข้อมูลที่รับจาก Flutter
class BotMoveRequest(BaseModel):
    game_id: str
    board: list
    rack_player2: Optional[List[str]] = None  # ✅ ทำให้ rack เป็น Optional
    difficulty: str
    
class RegisterUser(BaseModel):
    username: str
    email: str
    password: str
    
class LoginRequest(BaseModel):
    username: str
    password: str

class ProfileUpdate(BaseModel):
    user_id: str
    profile_image: str  # Base64 encoded image

class GameSaveRequest(BaseModel):
    user_id: str
    level_id: int | None = None  # อาจเป็น NULL ถ้าโหมดสร้างห้อง
    room_id: int | None = None  # อาจเป็น NULL ถ้าโหมดผจญภัย
    game_mode: str  # 'a' = ผจญภัย, 'c' = สร้างห้อง
    start_at: str  # เวลาที่เริ่ม

class EmailRequest(BaseModel):
    to: str
    link: str
    
def generate_user_id():
    return str(uuid.uuid4())

used_words = set()  # ✅ เก็บคำที่บอทเคยใช้ไป

@app.post("/register")
def register_user(user: RegisterUser):
    conn = get_db_connection()
    cursor = conn.cursor()

    user_id = generate_user_id()

    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # 🔹 Debug: แสดงค่าที่กำลังจะ Insert
    print(f"Registering user: user_id={user_id}, username={user.username}, email={user.email}")

    try:
        cursor.execute("INSERT INTO users (user_id, username, email, password) VALUES (%s, %s, %s, %s)",
                       (user_id, user.username.strip(), user.email.strip(), hashed_password))
        conn.commit()

        # 🔹 Debug: แจ้งว่า Insert สำเร็จ
        print(f"User {user_id} inserted into database!")

        return {"message": "สมัครสมาชิกสำเร็จ", "user_id": user_id}
    except Exception as e:
        conn.rollback()

        print(f" Failed to register user: {str(e)}")

        raise HTTPException(status_code=400, detail=f"Error: {str(e)}")
    finally:
        cursor.close()
        release_db_connection(conn)

@app.post("/request_password_reset")
async def request_password_reset(request: Request):
    data = await request.json()
    email = data.get("email")

    print(f"รับค่า email: {email}")

    if not email:
        raise HTTPException(status_code=400, detail="ไม่พบอีเมลในคำขอ")

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT password FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            print("ERROR ไม่พบอีเมลในระบบ")
            raise HTTPException(status_code=400, detail="ไม่พบอีเมลนี้ในระบบ")

        user_password = user[0]  

        send_email(email, user_password)

        return {"success": True, "message": "รหัสผ่านถูกส่งไปยังอีเมลของคุณ"}

    except Exception as e:
        print(f"ERROR {e}")
        raise HTTPException(status_code=500, detail="เกิดข้อผิดพลาดในเซิร์ฟเวอร์")

    finally:
        cursor.close()
        conn.close()

def send_email(to_email, user_password):
    print(f"กำลังส่งอีเมลไปที่ {to_email}...")

    msg = MIMEText(f"""
    <html>
        <body>
            <p>คุณได้ร้องขอรีเซ็ตรหัสผ่านของคุณ</p>
            <p><strong>รหัสผ่านของคุณคือ:</strong> {user_password}</p>
            <p>กรุณาเปลี่ยนรหัสผ่านทันทีหากคุณไม่ได้ร้องขอ</p>
        </body>
    </html>
    """, "html")

    msg["Subject"] = "รีเซ็ตรหัสผ่านของคุณ"
    msg["From"] = EMAIL_SENDER
    msg["To"] = to_email

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_SENDER, EMAIL_PASSWORD)
        server.sendmail(EMAIL_SENDER, to_email, msg.as_string())
        server.quit()
        print("อีเมลถูกส่งสำเร็จ!")
    except Exception as e:
        print(f"ไม่สามารถส่งอีเมลได้: {e}")


# ✅ API Login เช็คชื่อผู้ใช้ & รหัสผ่าน
@app.post("/login")
def login(request: LoginRequest):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # 🔹 ค้นหาข้อมูลผู้ใช้จากฐานข้อมูล
        cursor.execute("SELECT user_id, password FROM users WHERE email = %s", (request.username,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=400, detail="ชื่อผู้ใช้ไม่ถูกต้อง")

        user_id, hashed_password = user

        # 🔹 ตรวจสอบรหัสผ่านที่รับมากับรหัสที่เข้ารหัสใน DB
        if bcrypt.checkpw(request.password.encode("utf-8"), hashed_password.encode("utf-8")):
            return {"message": "เข้าสู่ระบบสำเร็จ", "user_id": user_id}
        else:
            raise HTTPException(status_code=400, detail="รหัสผ่านไม่ถูกต้อง")

    except Exception as e:
        return {"error": str(e)}
    finally:
        cursor.close()
        conn.close()

@app.post("/upload_profile")
def upload_profile(data: ProfileUpdate):
    user_id = data.user_id
    try:
        # ✅ แปลงข้อมูล Base64 เป็นไบต์
        image_data = base64.b64decode(data.profile_image.split(",")[-1])  # ตัดส่วน `data:image/png;base64,` ออก
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"❌ Base64 ไม่ถูกต้อง: {str(e)}")

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("UPDATE users SET profile_image = %s WHERE user_id = %s", (image_data, user_id))
        conn.commit()
        return {"success": True, "message": "✅ อัปโหลดรูปโปรไฟล์สำเร็จ"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"❌ Database Error: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@app.get("/get_user/{user_id}")
def get_user(user_id: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT username, email, stage_level, profile_image FROM users WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    
    cursor.close()
    conn.close()

    if row:
        user = {
            "username": row[0],
            "email": row[1],
            "stage_level": row[2],
            "profile_image": f"data:image/png;base64,{base64.b64encode(row[3]).decode('utf-8')}" if row[3] else None
        }
        return user
    
    raise HTTPException(status_code=404, detail="User not found")


    
# 📌 API `/bot_move` ให้บอทเล่น Scrabble
@app.post("/bot_move")
async def get_bot_move(request: BotMoveRequest):
    print(f"🔹 Received request for game {request.game_id}")

    # ✅ โหลดสถานะเกมจาก Redis
    env = load_game_state(request.game_id)

    if env is None:
        env = ScrabbleEnv(
            game_id=request.game_id,
            board=request.board,
            rack_bot=request.rack_player2,  # ✅ ใช้ rack ของบอทตอนสร้างใหม่
            tile_bag=request.tile_bag
        )
    else:
        env.rack_bot = request.rack_player2

    move = env.select_word_from_rack()
    print(f"📖 คำที่เลือกโดยบอท: {move}")

    if move and move["move"] == "play":
        word, (row, col, direction) = move["word"], move["position"]
        success = env.place_word(word, row, col, direction)

        if success:
            env.remove_used_letters(word, row, col, direction)
            save_game_state(request.game_id, env)  # ✅ บันทึกสถานะเกมใหม่

            return {
                "game_state": env.get_game_state(),
                "word": word,
                "position": [row, col],
                "direction": direction,
                "score": env.calculate_score(word, row, col, direction),
                "new_rack": env.rack  # ✅ ส่ง rack ที่อัปเดตกลับไป
            }

    return {"message": "No valid move found"}

@app.get("/game_state")
async def get_game_state():
    env = load_game_state("scrabble_game03")
    if env is None:
        return JSONResponse(status_code=404, content={"message": "Game state not found"})

    game_state = env.get_game_state()

    print(f"📡 [DEBUG] game_state ที่ส่งไป Flutter:\n{json.dumps(game_state, indent=2, ensure_ascii=False)}")

    return JSONResponse(
        status_code=200,
        content={
            "board": game_state["board"],
            "rack_player1": game_state.get("rack_player1", []),
            "rack_player2": game_state.get("rack_player2", []), 
            "tile_bag": game_state["tile_bag"],
            "playedWords": game_state.get("playedWords", []), 
            "last_move_by": game_state.get("last_move_by", "")
        }
    )

@app.get("/get_user_history/{user_id}")
def get_user_history(user_id: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM user_historys WHERE user_id = %s", (user_id,))
    total_games = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM user_historys WHERE user_id = %s AND result = TRUE", (user_id,))
    total_wins = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM user_historys WHERE user_id = %s AND result = FALSE", (user_id,))
    total_loses = cursor.fetchone()[0]

    cursor.close()
    conn.close()

    win_rate = (total_wins / total_games * 100) if total_games > 0 else 0

    return {
        "total_games": total_games,
        "total_wins": total_wins,
        "total_loses": total_loses,
        "win_rate": round(win_rate, 2)
    }

@app.post("/save_game")
async def save_game(data: GameSaveRequest):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        query = """
        INSERT INTO games (user_id, level_id, room_id, game_mode, start_at)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING game_id;  -- ดึงค่า game_id ที่เพิ่มใหม่กลับมา
        """
        values = (
            data.user_id,
            data.level_id if data.level_id is not None else None,
            data.room_id if data.room_id is not None else None,
            data.game_mode,
            data.start_at
        )

        cursor.execute(query, values)
        game_id = cursor.fetchone()[0]  # รับค่า game_id ที่ถูกสร้างอัตโนมัติ
        conn.commit()

        return {"message": "✅ เกมถูกบันทึกแล้ว", "game_id": game_id}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"❌ Error saving game: {str(e)}")
    finally:
        cursor.close()
        conn.close()

        
@app.post("/save_game_state")
async def save_state(request: GameStateRequest):
    try:
        print(f"💾 [SAVE] ก่อนบันทึก: board = {request.board}")  # ✅ Debug ก่อนเซฟ
        
        board_to_save = request.board.tolist() if isinstance(request.board, np.ndarray) else request.board

        env_data = {
            "board": board_to_save,
            "rack_player1": request.rack_player,  # ✅ ใช้ rack ของ Player 1
            "rack_player2": request.rack_player2,
            "tile_bag": request.tile_bag,
            "playedWords": request.playedWords,  
            "last_move_by": request.last_move_by
        }

        redis_client.delete(request.game_id)  # ✅ ลบค่าเก่าก่อนเซฟ
        redis_client.set(request.game_id, json.dumps(env_data))  # ✅ เซฟใหม่
        
        # ✅ ตรวจสอบว่าบันทึกค่าถูกต้องหรือไม่
        saved_data = redis_client.get(request.game_id)
        print(f"✅ [SAVE] หลังบันทึก Redis: {saved_data}")  # ✅ Debug หลังเซฟ

        return {"message": f"✅ Game state {request.game_id} saved successfully"}

    except Exception as e:
        return HTTPException(status_code=500, detail=f"Server error: {str(e)}")

@app.get("/get_user/{user_id}")
def get_user(user_id: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT username, email, stage_level, profile_image FROM users WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    
    cursor.close()
    conn.close()

    if row:
        user = {
            "username": row[0],
            "email": row[1],
            "stage_level": row[2],
            "profile_image": base64.b64encode(row[3]).decode('utf-8') if row[3] else None
        }
        print(f"✅ พบข้อมูลผู้ใช้: {user}")
        return user
    
    print("❌ ไม่พบ user_id นี้ในฐานข้อมูล")
    raise HTTPException(status_code=404, detail="User not found")




# ✅ API `/clear_state/{game_id}` ลบข้อมูลใน Redis
@app.delete("/clear_state/{game_id}")
def clear_game_state(game_id: str):
    redis_client.delete(game_id)
    return {"status": "success", "message": f"Game state {game_id} cleared"}

def load_words_to_redis():
    """
    ✅ โหลดคำศัพท์จากฐานข้อมูลแล้วเก็บลง Redis
    """
    connection = get_db_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT word_name FROM words;")
        words = [row[0].upper() for row in cursor.fetchall()]
        
        # ✅ เก็บลง Redis
        redis_client.set("cached_words", json.dumps(words))
        redis_client.expire("cached_words", 3600)  # ตั้งให้หมดอายุใน 1 ชั่วโมง
        print(f"✅ Cached {len(words)} words in Redis")
    
    finally:
        cursor.close()
        release_db_connection(connection)

@app.get("/words")
def get_words():
    try:
        # ✅ ลองดึงคำศัพท์จาก Redis ก่อน
        cached_words = redis_client.get("cached_words")
        if cached_words:
            print("✅ Loaded words from Redis cache")
            return {"data": json.loads(cached_words)}

        # ❌ ถ้าไม่มีใน Redis -> โหลดใหม่จากฐานข้อมูล
        load_words_to_redis()

        # ✅ ดึงจาก Redis อีกครั้งหลังโหลดใหม่
        cached_words = redis_client.get("cached_words")
        if cached_words:
            return {"data": json.loads(cached_words)}

        return {"status": "Failed", "error": "Failed to load words from database and cache"}

    except Exception as e:
        print(f"❌ Error fetching words: {e}")
        return {"status": "Failed", "error": str(e)}



def close_db_pool():
    if db_pool:
        db_pool.closeall()
        print("🛑 Connection Pool Closed")

atexit.register(close_db_pool)

# ✅ รันเซิร์ฟเวอร์ FastAPI
if __name__ == "__main__":
    load_words_to_redis()
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
