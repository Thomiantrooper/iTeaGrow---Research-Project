"""
iTeaGrow MQTT Bridge
====================
Subscribes to HiveMQ Cloud MQTT broker and stores incoming sensor data
directly into MongoDB Atlas (iot_data collection).

Flow:
    ESP32 (WiFi) → MQTT Broker → mqtt_bridge.py → MongoDB → FastAPI → Flutter

Usage (standalone):
    python mqtt_bridge.py

Used by main.py:
    from mqtt_bridge import get_bridge
    bridge = get_bridge()
    bridge.start_background()   # non-blocking daemon thread

MQTT Payload format from ESP32 (JSON):
    {
        "device_id":    "esp32-001",
        "temperature":  26.5,
        "humidity":     72.3,
        "soil_moisture": 65.2,
        "air_quality":  420,
        "light_level":  8500
    }

Topic format:
    iteagrow/sensors/{device_id}
    OR the device_id can be embedded in the payload.
"""
import json
import logging
import os
import threading
import time
from datetime import datetime, timezone
from typing import Optional

import paho.mqtt.client as mqtt
from pymongo import MongoClient

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [mqtt_bridge] %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("mqtt_bridge")

# ─── Configuration (from env vars, with sensible defaults) ────────────────────
MQTT_BROKER   = os.getenv("MQTT_BROKER",   "c0674ce6e5414364a46009de82230e02.s1.eu.hivemq.cloud")
MQTT_PORT     = int(os.getenv("MQTT_PORT", "8883"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME", "Kajanthan")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD", "Kajanthan@2002")
MQTT_TOPIC    = os.getenv("MQTT_TOPIC",    "iteagrow/sensors/#")

MONGODB_URL   = os.getenv("MONGODB_URL",   "mongodb+srv://kanzur:kanzur@cluster0.joabitw.mongodb.net/?appName=Cluster0")
DB_NAME       = os.getenv("DB_NAME",       "iteagrow")

# The user_id stored alongside MQTT sensor data so the existing
# /api/iot/live/latest endpoint can query without a user filter.
IOT_USER_ID   = os.getenv("IOT_USER_ID",  "iot_system")

# ─── MongoDB connection (lazy singleton) ──────────────────────────────────────
_mongo_client: Optional[MongoClient] = None
_collection = None
_mongo_lock = threading.Lock()


def _get_collection():
    """Return the iot_data collection, creating the connection if needed."""
    global _mongo_client, _collection
    if _collection is not None:
        return _collection
    with _mongo_lock:
        if _collection is None:
            _mongo_client = MongoClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
            db = _mongo_client[DB_NAME]
            _collection = db["iot_data"]
            # Ensure indexes exist (idempotent)
            _collection.create_index([("device_id", 1), ("timestamp", -1)])
            _collection.create_index("user_id")
            log.info("MongoDB connection established (iot_data collection)")
    return _collection


# ─── MQTT callbacks ───────────────────────────────────────────────────────────
def _on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0 or (hasattr(reason_code, 'is_failure') and not reason_code.is_failure):
        log.info("Connected to MQTT broker: %s:%d", MQTT_BROKER, MQTT_PORT)
        client.subscribe(MQTT_TOPIC, qos=1)
        log.info("Subscribed to topic: %s", MQTT_TOPIC)
    else:
        log.error("MQTT connection refused (reason=%s)", reason_code)


def _on_disconnect(client, userdata, flags, reason_code=None, properties=None):
    if reason_code is not None and reason_code != 0:
        log.warning("Unexpected MQTT disconnect (reason=%s) — will auto-reconnect", reason_code)


def _on_message(client, userdata, msg):
    """
    Parse incoming MQTT message and write it to MongoDB.
    Expected JSON keys: device_id, temperature, humidity,
                        soil_moisture, air_quality, light_level
    """
    try:
        payload = json.loads(msg.payload.decode("utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        log.warning("Bad payload on topic '%s': %s", msg.topic, exc)
        return

    # device_id: prefer value in payload, fall back to MQTT topic segment
    topic_parts = msg.topic.split("/")
    device_id = (
        payload.get("device_id")
        or (topic_parts[2] if len(topic_parts) >= 3 else "unknown_device")
    )

    doc = {
        "user_id":      IOT_USER_ID,       # sentinel so /live/latest can query
        "device_id":    str(device_id),
        "temperature":  _to_float(payload.get("temperature")),
        "humidity":     _to_float(payload.get("humidity")),
        "soil_moisture": _to_float(payload.get("soil_moisture")),
        "air_quality":  _to_float(payload.get("air_quality")),
        "light_level":  _to_float(payload.get("light_level")),
        "timestamp":    datetime.now(timezone.utc),
    }

    try:
        col = _get_collection()
        result = col.insert_one(doc)
        log.info(
            "Stored [%s] T=%.1f°C H=%.1f%% → id=%s",
            device_id,
            doc["temperature"] or 0,
            doc["humidity"] or 0,
            result.inserted_id,
        )
    except Exception as exc:
        log.error("MongoDB write failed: %s", exc)


def _to_float(value) -> Optional[float]:
    """Safely cast value to float, return None on failure."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


# ─── Bridge class ─────────────────────────────────────────────────────────────
class MQTTBridge:
    """
    Manages the MQTT client lifecycle.

    Usage:
        bridge = MQTTBridge()
        bridge.start_background()   # non-blocking daemon thread
        # ... your application runs ...
        bridge.stop()
    """

    def __init__(self):
        self._stop_event = threading.Event()
        self._client = self._build_client()

    def _build_client(self) -> mqtt.Client:
        try:
            # paho-mqtt 2.x API
            client = mqtt.Client(
                callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
                client_id=f"iteagrow-bridge-{int(time.time())}",
                clean_session=True,
            )
        except AttributeError:
            # paho-mqtt 1.x fallback
            client = mqtt.Client(
                client_id=f"iteagrow-bridge-{int(time.time())}",
                clean_session=True,
            )
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        client.tls_set()          # TLS required for HiveMQ Cloud (port 8883)
        client.on_connect    = _on_connect
        client.on_disconnect = _on_disconnect
        client.on_message    = _on_message
        return client

    def start(self):
        """Blocking run — reconnects automatically on failure."""
        log.info("iTeaGrow MQTT Bridge starting…")
        log.info("  Broker  : %s:%d", MQTT_BROKER, MQTT_PORT)
        log.info("  Topic   : %s", MQTT_TOPIC)
        log.info("  MongoDB : %s / %s", DB_NAME, "iot_data")

        while not self._stop_event.is_set():
            try:
                self._client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
                self._client.loop_forever()          # blocks until disconnect
            except OSError as exc:
                log.error("Network error: %s. Retrying in 15 s…", exc)
                time.sleep(15)
            except Exception as exc:
                log.error("Unexpected error: %s. Retrying in 15 s…", exc)
                time.sleep(15)

        log.info("MQTT Bridge stopped.")

    def start_background(self) -> threading.Thread:
        """Start bridge in a daemon thread and return it (non-blocking)."""
        thread = threading.Thread(target=self.start, daemon=True, name="mqtt-bridge")
        thread.start()
        log.info("MQTT Bridge running in background thread (daemon=True)")
        return thread

    def stop(self):
        """Signal the bridge to stop and disconnect."""
        self._stop_event.set()
        try:
            self._client.disconnect()
        except Exception:
            pass


# ─── Module-level singleton ───────────────────────────────────────────────────
_bridge_singleton: Optional[MQTTBridge] = None


def get_bridge() -> MQTTBridge:
    """Return the module-level singleton MQTTBridge (creates on first call)."""
    global _bridge_singleton
    if _bridge_singleton is None:
        _bridge_singleton = MQTTBridge()
    return _bridge_singleton


# ─── Standalone entry point ───────────────────────────────────────────────────
if __name__ == "__main__":
    bridge = get_bridge()
    try:
        bridge.start()          # blocking
    except KeyboardInterrupt:
        bridge.stop()
        log.info("Stopped by user (Ctrl-C)")
