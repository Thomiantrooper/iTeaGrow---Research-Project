import paho.mqtt.client as mqtt
import json
import os
import imaplib
import email
from email.header import decode_header
from datetime import datetime, timedelta
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()

# ================= CONFIG =================
class Config:
    MQTT_BROKER = "860992f6cc13445db31fa3209c7ff25d.s1.eu.hivemq.cloud"
    MQTT_PORT = 8883
    MQTT_USERNAME = "Ashwin"
    MQTT_PASSWORD = "Ashwin@2002"
    
    TOPIC_MESSAGES = "auralink/device01/messages"
    TOPIC_SENSORS = "auralink/device01/sensors"

    EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS", "your-email@gmail.com")
    EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "your-app-password")
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "your-geminiai-api-key")

# ================= EMAIL SERVICE =================
class EmailService:
    def __init__(self, email_address, password):
        self.email_address = email_address
        self.password = password
        self.last_email_id = None  # Track last processed email

    def fetch_recent_emails(self, hours=12):
        """Fetch only NEW emails since last check"""
        try:
            mail = imaplib.IMAP4_SSL("imap.gmail.com")
            mail.login(self.email_address, self.password)
            mail.select("inbox")

            date_since = (datetime.now() - timedelta(hours=hours)).strftime("%d-%b-%Y")
            status, messages = mail.search(None, "SINCE", date_since)

            if status != "OK":
                print("❌ Failed to search emails")
                return None

            email_ids = messages[0].split()
            if not email_ids:
                print("📭 No new emails")
                return None

            # Get the latest email ID
            latest_email_id = email_ids[-1]
            
            # Check if this is a new email (not processed before)
            if self.last_email_id == latest_email_id:
                print("📭 No NEW emails (already processed)")
                return None
            
            # This is a new email - process it
            self.last_email_id = latest_email_id
            
            status, msg_data = mail.fetch(latest_email_id, "(RFC822)")

            if status != "OK":
                print("❌ Failed to fetch email")
                return None

            msg = email.message_from_bytes(msg_data[0][1])
            subject = self._decode_header(msg["subject"])
            sender = self._decode_header(msg["from"])
            date = msg["date"]

            # Extract body
            body = self._extract_body(msg)

            mail.close()
            mail.logout()

            return {
                "from": sender,
                "subject": subject,
                "date": date,
                "body": body,
                "email_id": latest_email_id.decode()
            }

        except Exception as e:
            print(f"❌ Email fetch error: {e}")
            return None

    def _decode_header(self, value):
        if not value:
            return ""
        try:
            decoded_parts = decode_header(value)
            decoded_value = ""
            for part, encoding in decoded_parts:
                if isinstance(part, bytes):
                    decoded_value += part.decode(encoding or "utf-8", errors="ignore")
                else:
                    decoded_value += part
            return decoded_value
        except:
            return str(value)

    def _extract_body(self, msg):
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition"))
                if content_type == "text/plain" and "attachment" not in content_disposition:
                    return part.get_payload(decode=True).decode("utf-8", errors="ignore")
        else:
            return msg.get_payload(decode=True).decode("utf-8", errors="ignore")
        return "No content"

# ================= GEMINI SUMMARIZER =================
class GeminiSummarizer:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY", "")
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel("gemini-2.5-flash")

    def summarize_email(self, email_data):
        """Generate concise summary using Gemini"""
        try:
            prompt = f"""
Summarize this email in one short paragraph (max 2-3 lines):
Subject: {email_data['subject']}
From: {email_data['from']}
Body: {email_data['body'][:800]}
"""

            response = self.model.generate_content(prompt)
            summary = response.text.strip()
            return summary if summary else "No summary generated."
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
            return "Unable to summarize email."

    def determine_priority(self, email_data, summary):
        """Determine priority based on email content"""
        try:
            content = f"Subject: {email_data['subject']}\nBody: {email_data['body'][:500]}\nSummary: {summary}"
            content_lower = content.lower()
            
            # Priority 3: Urgent emails
            urgent_keywords = ["urgent", "asap", "emergency", "important", "deadline", "critical", "immediately"]
            if any(keyword in content_lower for keyword in urgent_keywords):
                return 3
            
            # Priority 2: Work/meeting related
            work_keywords = ["meeting", "appointment", "schedule", "project", "work", "task", "assignment"]
            if any(keyword in content_lower for keyword in work_keywords):
                return 2
            
            # Priority 1: Normal emails
            return 1
            
        except Exception as e:
            print(f"❌ Priority determination error: {e}")
            return 1

    def summarize_sensor_data(self, sensor_data_list):
        """Generate AI summary of sensor data trends"""
        try:
            if not sensor_data_list:
                return "No sensor data available for analysis."
            
            # Prepare sensor data for AI analysis
            sensor_text = "Sensor data analysis:\n"
            for i, data in enumerate(sensor_data_list[-10:]):  # Last 10 readings
                sensor_text += f"Reading {i+1}: Temp={data['temperature']}°C, Hum={data['humidity']}%, "
                sensor_text += f"Motion={data['motion']}, Air={data['air_quality']}, Time={data['timestamp']}\n"
            
            prompt = f"""
Analyze this sensor data and provide a brief environmental summary (2-3 lines max). 
Focus on trends in temperature, humidity, air quality, and motion patterns.
Keep it very concise and human-readable.

{sensor_text}
"""
            
            response = self.model.generate_content(prompt)
            summary = response.text.strip()
            return summary if summary else "Environmental conditions appear normal."
            
        except Exception as e:
            print(f"❌ Sensor data summarization error: {e}")
            return "Environmental monitoring active."

# ================= SENSOR DATA MANAGER =================
class SensorDataManager:
    def __init__(self):
        self.sensor_data = []  # Store recent sensor data
        self.max_readings = 50  # Keep last 50 readings
        
    def add_sensor_data(self, sensor_data):
        """Add new sensor reading and maintain buffer size"""
        self.sensor_data.append({
            "temperature": sensor_data.get("temperature", 0),
            "humidity": sensor_data.get("humidity", 0),
            "motion": sensor_data.get("motion_detected", 0),
            "air_quality": sensor_data.get("air_quality", 0),
            "air_quality_rating": sensor_data.get("air_quality_rating", "Unknown"),
            "timestamp": datetime.now().isoformat()
        })
        
        # Keep only recent readings
        if len(self.sensor_data) > self.max_readings:
            self.sensor_data = self.sensor_data[-self.max_readings:]
            
    def get_recent_data(self):
        """Get all stored sensor data"""
        return self.sensor_data

# ================= MAIN BACKEND =================
class AuralinkBackend:
    def __init__(self):
        self.config = Config()
        self.email_service = EmailService(self.config.EMAIL_ADDRESS, self.config.EMAIL_PASSWORD)
        self.summarizer = GeminiSummarizer()
        self.sensor_manager = SensorDataManager()
        self.mqtt_client = self._setup_mqtt()
        self.last_sensor_summary_time = datetime.now()
        self.sensor_summary_interval = timedelta(minutes=30)  # Every 30 minutes

    def _setup_mqtt(self):
        client = mqtt.Client()
        client.username_pw_set(self.config.MQTT_USERNAME, self.config.MQTT_PASSWORD)
        client.tls_set()
        client.on_connect = self._on_connect
        client.on_message = self._on_message  # Listen for sensor data
        return client

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print("✅ Connected to MQTT broker!")
            # Subscribe to sensor data topic
            client.subscribe(self.config.TOPIC_SENSORS)
            print(f"📡 Subscribed to: {self.config.TOPIC_SENSORS}")
        else:
            print(f"❌ MQTT connection failed: {rc}")

    def _on_message(self, client, userdata, msg):
        """Handle incoming sensor data from ESP32"""
        try:
            if msg.topic == self.config.TOPIC_SENSORS:
                sensor_data = json.loads(msg.payload.decode())
                print(f"📊 Received sensor data: Temp={sensor_data.get('temperature')}°C")
                
                # Store sensor data for analysis
                self.sensor_manager.add_sensor_data(sensor_data)
                
        except Exception as e:
            print(f"❌ Error processing sensor data: {e}")

    def send_email_alert(self, email_data):
        """Send email alert (only for new emails)"""
        print("📧 New email detected!")
        print(f"   From: {email_data['from']}")
        print(f"   Subject: {email_data['subject']}")
        
        # Generate summary
        summary = self.summarizer.summarize_email(email_data)
        print(f"   Summary: {summary}")
        
        # Determine priority
        priority = self.summarizer.determine_priority(email_data, summary)
        print(f"   Priority: {priority}")
        
        # Create payload
        payload = {
            "email_summary": summary,
            "priority": priority,
            "timestamp": datetime.now().isoformat(),
            "raw_subject": email_data["subject"],
            "raw_from": email_data["from"],
            "type": "email_alert"
        }

        # Send to ESP32
        self.mqtt_client.publish(self.config.TOPIC_MESSAGES, json.dumps(payload))
        print("✅ New email alert sent via MQTT")

    def send_sensor_summary(self):
        """Send AI-powered sensor data summary"""
        sensor_data = self.sensor_manager.get_recent_data()
        if not sensor_data:
            print("📊 No sensor data available for summary")
            return
            
        print("📊 Generating sensor data summary...")
        
        # Generate AI summary
        summary = self.summarizer.summarize_sensor_data(sensor_data)
        print(f"   Sensor Summary: {summary}")
        
        # Create payload
        payload = {
            "sensor_summary": summary,
            "timestamp": datetime.now().isoformat(),
            "data_points": len(sensor_data),
            "type": "sensor_summary"
        }

        # Send to ESP32
        self.mqtt_client.publish(self.config.TOPIC_MESSAGES, json.dumps(payload))
        print("✅ Sensor summary sent via MQTT")
        self.last_sensor_summary_time = datetime.now()

    def should_send_sensor_summary(self):
        """Check if it's time to send sensor summary"""
        return datetime.now() - self.last_sensor_summary_time >= self.sensor_summary_interval

    def start(self):
        print("🚀 Starting Auralink Smart Backend...")
        print(f"📧 Monitoring: {self.config.EMAIL_ADDRESS}")
        print("⏰ Sensor summaries every 30 minutes")
        print("📧 Email alerts for NEW emails only")
        
        self.mqtt_client.connect(self.config.MQTT_BROKER, self.config.MQTT_PORT, 60)
        self.mqtt_client.loop_start()

        try:
            while True:
                # Check for new emails
                email_data = self.email_service.fetch_recent_emails(hours=12)
                if email_data:
                    self.send_email_alert(email_data)
                else:
                    print("⏳ No new emails...")

                # Check if it's time for sensor summary
                if self.should_send_sensor_summary():
                    self.send_sensor_summary()

                # Wait 60 seconds before next check
                import time
                time.sleep(60)

        except KeyboardInterrupt:
            print("🛑 Stopped manually")
            self.mqtt_client.disconnect()
        except Exception as e:
            print(f"❌ Runtime error: {e}")

# ================= RUN =================
if __name__ == "__main__":
    backend = AuralinkBackend()
    backend.start()