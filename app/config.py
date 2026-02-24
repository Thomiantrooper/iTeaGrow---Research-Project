from pydantic_settings import BaseSettings
from dotenv import load_dotenv
import os

load_dotenv()

class Settings(BaseSettings):
    # MongoDB
    MONGO_URL: str = os.getenv("MONGO_URL", "mongodb://localhost:27017")
    DATABASE_NAME: str = os.getenv("DATABASE_NAME", "tea_iot")
    
    # MQTT
    MQTT_BROKER: str = os.getenv("MQTT_BROKER", "")
    MQTT_PORT: int = int(os.getenv("MQTT_PORT", "8883"))
    MQTT_USERNAME: str = os.getenv("MQTT_USERNAME", "")
    MQTT_PASSWORD: str = os.getenv("MQTT_PASSWORD", "")
    MQTT_TOPIC: str = os.getenv("MQTT_TOPIC", "test/iot")
    
    # Model
    MODEL_PATH: str = os.getenv("MODEL_PATH", "models/xgboost_model_20260214_134249.pkl")
    
    class Config:
        case_sensitive = True

settings = Settings()