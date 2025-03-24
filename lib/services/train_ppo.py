from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import BaseCallback
from scrabble_env import ScrabbleEnv
import os

class TensorboardCallback(BaseCallback):
    def __init__(self, stop_timesteps, verbose=0):
        super(TensorboardCallback, self).__init__(verbose)
        self.stop_timesteps = stop_timesteps

    def _on_step(self) -> bool:
        self.logger.record("train/step", self.num_timesteps)
        
        # ตรวจสอบว่า timesteps ถึงขีดจำกัดหรือไม่
        if self.num_timesteps >= self.stop_timesteps:
            print("✅ ถึงขีดจำกัด timesteps หยุดการเทรนแล้ว!")
            return False  # บังคับให้หยุดเทรน
        
        return True  # ให้ callback ทำงานต่อไป

# ✅ สร้าง `ScrabbleEnv`
env = ScrabbleEnv()

# ✅ ใช้ `PPO` เทรน พร้อมตั้งค่าที่เหมาะสมเพื่อป้องกันการรันเกิน
model = PPO(
    "MlpPolicy", env, verbose=1, tensorboard_log="./ppo_scrabble_logs/",
    n_steps=500, batch_size=50  # ป้องกัน PPO รันเกิน 100 timesteps
)

# ✅ ใช้ callback ที่มีเงื่อนไขหยุด
callback = TensorboardCallback(stop_timesteps=10)

# ✅ เริ่มเทรน + บันทึก TensorBoard
print("🚀 เริ่มต้นเทรน PPO...")
model.learn(total_timesteps=10, reset_num_timesteps=False, progress_bar=True, callback=callback)
print(f"✅ เทรนเสร็จสิ้น! timesteps ที่ใช้จริง: {model.num_timesteps}")

# ✅ บันทึกโมเดล
model.save("bot005")
print("📂 บันทึกโมเดลใหม่สำเร็จ")
