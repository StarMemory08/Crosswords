from pydantic import BaseModel
from typing import List
import redis
import json
import numpy as np
from lib.services.scrabble_env import ScrabbleEnv

#ตั้งค่า Redis Client
try:
    redis_client = redis.StrictRedis(host="localhost", port=6379, db=0, decode_responses=True)
    print("Connected to Redis")
except Exception as e:
    print(f"Redis Connection Error: {e}")
    redis_client = None


# ฟังก์ชันพิมพ์บอร์ดให้ดูง่าย
def print_board(board):
    """พิมพ์กระดาน Scrabble ในรูปแบบ 15x15"""
    print("กระดาน Scrabble:")
    for row in board:
        print(" ".join(row if row else "." for row in row))

def save_game_state(game_id, env):
    print(f"💾 [SAVE] Board ก่อนบันทึก: {env.board}")
    print(f"💾 [SAVE] rack_player1: {env.rack}")  # ✅ Debug ค่า rack ของ Player 1
    print(f"💾 [SAVE] rack_player2: {env.rack_bot}")  # ✅ Debug ค่า rack ของ Bot ก่อนเซฟ

    game_state = {
        "board": [[cell if cell != "" else "_" for cell in row] for row in env.board.tolist()],
        "rack_player1": env.rack,  
        "rack_player2": env.rack_bot,  
        "tile_bag": env.tile_bag.copy(),
        "playedWords": env.played_words, 
        "last_move_by": env.last_move_by,
    }

    print(f"✅ กำลังบันทึกลง Redis -> {json.dumps(game_state, indent=2, ensure_ascii=False)}")
    redis_client.set(game_id, json.dumps(game_state))

def load_game_state(game_id):
    env_data = redis_client.get(game_id)
    if env_data:
        game_state = json.loads(env_data)
        print(f"🔍 โหลด Game State จาก Redis -> {json.dumps(game_state, indent=2, ensure_ascii=False)}")

        env = ScrabbleEnv(game_id)
        env.board = np.array([[cell if cell != "_" else "" for cell in row] for row in game_state["board"]], dtype=object)

        # ✅ ใช้ rack_player1 ให้ถูกต้อง
        env.rack = [str(tile) for tile in game_state.get("rack_player1", [])]  

        # ✅ ใช้ rack_player2 ให้กับบอท
        env.rack_bot = [str(tile) for tile in game_state.get("rack_player2", [])]  

        env.tile_bag = [str(tile) for tile in game_state.get("tile_bag", env.tile_bag)]
        
        env.played_words = game_state.get("playedWords", [])

        env.last_move_by = game_state.get("last_move_by", "")

        # ✅ Debug เช็คค่าของ rack_bot
        print(f"📌 Debug: Rack ของบอทหลังโหลด -> {env.rack_bot}")

        return env
    else:
        print(f"⚠️ ไม่พบสถานะเกม {game_id}, กำลังสร้างใหม่...")
        env = ScrabbleEnv(game_id)
        save_game_state(game_id, env)
        return env


