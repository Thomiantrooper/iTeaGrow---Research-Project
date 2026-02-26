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
    """MQTT client for handling sensor data from ESP32"""
    
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
            logger.info(f"📨 Received raw message: {payload}")
            
            data = json.loads(payload)
            
            # Validate data using model_validate with alias support
            soil_data = SoilData.model_validate(data)
            logger.info(f"✅ Data validated successfully: {soil_data}")
            
            # Process the data
            self.process_sensor_data(soil_data)
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON format: {e}")
        except Exception as e:
            logger.error(f"❌ Error processing message: {e}")
            logger.error(f"Raw data that caused error: {payload}")
    
    def process_sensor_data(self, soil_data: SoilData):
        """Process sensor data: predict, recommend, and store"""
        try:
            # Convert to dict for processing
            data_dict = soil_data.model_dump()
            logger.debug(f"Processed data dict: {data_dict}")
            
            # Predict soil health using all 7 features
            soil_health = predict_soil_health(data_dict)
            
            # Get fertilizer recommendations
            fertilizer = fertilizer_recommendation(
                data_dict["N"], data_dict["P"], data_dict["K"], data_dict["pH"], soil_health
            )
            
            # Create result document with all features
            result = {
                "device_id": data_dict["device_id"],
                "hectare_id": data_dict["hectare_id"],
                "block_id": data_dict.get("block_id"),  # Store block_id if present
                "N": data_dict["N"],
                "P": data_dict["P"],
                "K": data_dict["K"],
                "pH": data_dict["pH"],
                "EC": data_dict["EC"],
                "temperature": data_dict["temperature"],
                "humidity": data_dict["humidity"],
                "soil_health": soil_health,
                "fertilizer": fertilizer,
                "timestamp": datetime.now(timezone.utc)
            }
            
            # Add reading_count if present
            if "reading_count" in data_dict and data_dict["reading_count"] is not None:
                result["reading_count"] = data_dict["reading_count"]
            
            # Save to MongoDB
            mongodb.predictions.insert_one(result)
            
            logger.info(f"✅ Saved prediction for hectare {data_dict['hectare_id']}: {soil_health}")
            logger.debug(f"📊 Result saved: {result}")
            
        except Exception as e:
            logger.error(f"❌ Error processing sensor data: {e}")
            logger.error(f"Data that caused error: {soil_data}")
    
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