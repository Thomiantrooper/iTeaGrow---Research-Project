import paho.mqtt.client as mqtt
from paho.mqtt.enums import CallbackAPIVersion
import json
import logging
from datetime import datetime, timezone
from typing import Optional
import threading
from app.config import settings
from app.services.ml_service import predict_soil_health
from app.services.fertilizer_service import fertilizer_recommendation
from app.database import mongodb
from app.models.schemas import SoilData

logger = logging.getLogger(__name__)

class MQTTClient:
    """MQTT client for handling sensor data with 7 features"""
    
    def __init__(self):
        self.client = mqtt.Client(
            callback_api_version=CallbackAPIVersion.VERSION2
        )
        self.client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
        self.client.tls_set()
        
        # Setup callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        
        self.is_running = False
        self.thread: Optional[threading.Thread] = None
    
    def on_connect(self, client, userdata, flags, reason_code, properties=None):
        """Callback for when client connects to broker"""
        if reason_code == 0:
            logger.info(f"✅ Connected to MQTT Broker at {settings.MQTT_BROKER}")
            client.subscribe(settings.MQTT_TOPIC)
            logger.info(f"📡 Subscribed to topic: {settings.MQTT_TOPIC}")
        else:
            logger.error(f"❌ Failed to connect, return code {reason_code}")
    
    def on_disconnect(self, client, userdata, reason_code, properties=None):
        """Callback for when client disconnects from broker"""
        logger.warning(f"🔌 Disconnected from MQTT Broker (rc: {reason_code})")
        self.is_running = False
    
    def on_message(self, client, userdata, msg):
        """Callback for when message is received"""
        try:
            # Parse message
            payload = msg.payload.decode()
            logger.debug(f"📨 Received message: {payload}")
            
            data = json.loads(payload)
            
            # Validate data (will check all 7 features if present)
            soil_data = SoilData(**data)
            
            # Process the data
            self.process_sensor_data(soil_data.dict())
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON format: {e}")
        except Exception as e:
            logger.error(f"❌ Error processing message: {e}")
    
    def process_sensor_data(self, data: dict):
        """Process sensor data with 7 features: predict, recommend, and store"""
        try:
            # Predict soil health using all 7 features
            soil_health = predict_soil_health(data)
            
            # Get fertilizer recommendations (uses N, P, K, pH)
            fertilizer = fertilizer_recommendation(
                data["N"], data["P"], data["K"], data["pH"], soil_health
            )
            
            # Create result document with all 7 features
            result = {
                "device_id": data["device_id"],
                "hectare_id": data["hectare_id"],
                "N": data["N"],
                "P": data["P"],
                "K": data["K"],
                "pH": data["pH"],
                "EC": data.get("EC", 0.0),  # Electrical Conductivity
                "temperature": data.get("temperature", 0.0),
                "humidity": data.get("humidity", 0.0),
                "soil_health": soil_health,
                "fertilizer": fertilizer,
                "timestamp": datetime.now(timezone.utc)
            }
            
            # Save to MongoDB
            mongodb.predictions.insert_one(result)
            
            logger.info(f"✅ Saved prediction for hectare {data['hectare_id']}: {soil_health}")
            logger.debug(f"📊 Data: N={data['N']}, P={data['P']}, K={data['K']}, pH={data['pH']}, EC={data.get('EC')}, Temp={data.get('temperature')}, Humidity={data.get('humidity')}")
            
        except Exception as e:
            logger.error(f"❌ Error processing sensor data: {e}")
    
    def start(self):
        """Start MQTT client in background thread"""
        try:
            self.client.connect(settings.MQTT_BROKER, settings.MQTT_PORT)
            self.thread = threading.Thread(target=self._run_loop, daemon=True)
            self.thread.start()
            self.is_running = True
            logger.info("🔄 MQTT client started")
        except Exception as e:
            logger.error(f"❌ Failed to start MQTT client: {e}")
            raise
    
    def _run_loop(self):
        """Run the MQTT client loop"""
        self.client.loop_forever()
    
    def stop(self):
        """Stop MQTT client"""
        if self.is_running:
            self.client.loop_stop()
            self.client.disconnect()
            self.is_running = False
            logger.info("🛑 MQTT client stopped")

# Create singleton instance
mqtt_client = MQTTClient()

def start_mqtt():
    """Convenience function to start MQTT client"""
    mqtt_client.start()