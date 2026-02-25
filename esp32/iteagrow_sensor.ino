/*
 * iTeaGrow ESP32 — Unified Sensor Node
 * Sensors : DHT22 (temp + humidity), Soil Moisture, MQ-135 (air), LDR, PIR
 * Output  : OLED display + MQTT → HiveMQ Cloud
 *
 * Wiring:
 *   DHT22 DATA  → GPIO 4
 *   Soil sensor → GPIO 34 (ADC)
 *   MQ-135      → GPIO 35 (ADC)
 *   LDR         → GPIO 32 (ADC)
 *   PIR         → GPIO 27
 *   Status LED  → GPIO 25
 *   OLED SDA    → GPIO 21  (I2C)
 *   OLED SCL    → GPIO 22  (I2C)
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

// ── OLED ──────────────────────────────────────────────────────────────────
Adafruit_SH1106G display(128, 64, &Wire, -1);

// ── Pins ──────────────────────────────────────────────────────────────────
#define DHT_PIN         4
#define DHT_TYPE        DHT22
#define SOIL_PIN        34
#define AIR_QUALITY_PIN 35
#define LIGHT_PIN       32
#define PIN_PIR         27
#define PIN_STATUS_LED  25

// ── WiFi ──────────────────────────────────────────────────────────────────
const char* WIFI_SSID = "Thomiantrooper";
const char* WIFI_PASS = "Thomiantrooper@6";

// ── HiveMQ Cloud ──────────────────────────────────────────────────────────
const char* MQTT_BROKER = "c0674ce6e5414364a46009de82230e02.s1.eu.hivemq.cloud";
const int   MQTT_PORT   = 8883;
const char* MQTT_USER   = "Kajanthan";
const char* MQTT_PASS   = "Kajanthan@2002";

// ── Device ────────────────────────────────────────────────────────────────
const char* DEVICE_ID  = "esp32-001";
const char* MQTT_TOPIC = "iteagrow/sensors/esp32-001";

// ── Intervals ─────────────────────────────────────────────────────────────
const unsigned long SENSOR_INTERVAL_MS  = 2000;
const unsigned long PUBLISH_INTERVAL_MS = 5000;

// ── Objects ───────────────────────────────────────────────────────────────
DHT              dht(DHT_PIN, DHT_TYPE);
WiFiClientSecure wifiClient;
PubSubClient     mqtt(wifiClient);

// ── Timing ────────────────────────────────────────────────────────────────
unsigned long lastSensor  = 0;
unsigned long lastPublish = 0;
bool          mqttOk      = false;

// ═══════════════════════════════════════════════════════════════════════════
//  WiFi / MQTT
// ═══════════════════════════════════════════════════════════════════════════

void connectWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 40) {
    delay(500); Serial.print("."); tries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi OK  IP: " + WiFi.localIP().toString());
    digitalWrite(PIN_STATUS_LED, HIGH);
  } else {
    Serial.println("\nWiFi FAILED. Restarting...");
    delay(3000); ESP.restart();
  }
}

void connectMQTT() {
  int tries = 0;
  while (!mqtt.connected() && tries < 5) {
    Serial.print("MQTT attempt "); Serial.print(tries + 1); Serial.print("...");
    String cid = String(DEVICE_ID) + "-" + String(millis());
    if (mqtt.connect(cid.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println(" OK"); mqttOk = true;
    } else {
      int rc = mqtt.state();
      Serial.print(" fail rc="); Serial.println(rc);
      tries++; delay(4000);
    }
  }
  if (!mqtt.connected()) {
    mqttOk = false;
    Serial.println("MQTT failed. Restarting...");
    delay(3000); ESP.restart();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sensors
// ═══════════════════════════════════════════════════════════════════════════

float readTemperature()  { float v = dht.readTemperature(); return isnan(v) ? 0.0f : v; }
float readHumidity()     { float v = dht.readHumidity();    return isnan(v) ? 0.0f : v; }
float readSoilMoisture() {
  return constrain((float)map(analogRead(SOIL_PIN), 4095, 0, 0, 100), 0.0f, 100.0f);
}
float readAirQuality()   { return (float)analogRead(AIR_QUALITY_PIN); }
float readLightLevel()   { return (float)analogRead(LIGHT_PIN); }

// ═══════════════════════════════════════════════════════════════════════════
//  MQTT publish
// ═══════════════════════════════════════════════════════════════════════════

void publishSensorData() {
  StaticJsonDocument<256> doc;
  doc["device_id"]     = DEVICE_ID;
  doc["temperature"]   = readTemperature();
  doc["humidity"]      = readHumidity();
  doc["soil_moisture"] = readSoilMoisture();
  doc["air_quality"]   = readAirQuality();
  doc["light_level"]   = readLightLevel();

  char payload[256];
  serializeJson(doc, payload);

  mqttOk = mqtt.publish(MQTT_TOPIC, payload, false);
  Serial.print("MQTT → "); Serial.print(payload);
  Serial.println(mqttOk ? " [OK]" : " [FAIL]");
}

// ═══════════════════════════════════════════════════════════════════════════
//  OLED
// ═══════════════════════════════════════════════════════════════════════════

const char* airLabel(int v) {
  if (v < 200) return "Excellent";
  if (v < 400) return "Good";
  if (v < 600) return "Moderate";
  if (v < 800) return "Poor";
  return "Critical";
}

void updateDisplay(float temp, float hum, float soil, int air) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SH110X_WHITE);

  // Header
  display.setCursor(0, 0);  display.print("iTeaGrow");
  display.setCursor(86, 0); display.print(mqttOk ? "MQTT:OK" : "MQTT:--");

  display.drawLine(0, 10, 128, 10, SH110X_WHITE);

  // Sensor values
  display.setCursor(0, 14); display.print("Temp :");
  display.setCursor(50, 14); display.print(temp, 1); display.print(" C");

  display.setCursor(0, 24); display.print("Humid:");
  display.setCursor(50, 24); display.print(hum, 0);  display.print(" %");

  display.setCursor(0, 34); display.print("Soil :");
  display.setCursor(50, 34); display.print(soil, 0); display.print(" %");

  display.setCursor(0, 44); display.print("Air  :");
  display.setCursor(50, 44); display.print(airLabel(air));

  // WiFi signal
  display.setCursor(0, 54);
  display.print("WiFi RSSI: ");
  display.print(WiFi.RSSI());
  display.print(" dBm");

  display.display();
}

void startupScreen() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SH110X_WHITE);
  display.setCursor(18, 18);
  display.println("iTeaGrow");
  display.setTextSize(1);
  display.setCursor(28, 42);
  display.println("Starting...");
  display.display();
  delay(1500);
}

// ═══════════════════════════════════════════════════════════════════════════
//  setup / loop
// ═══════════════════════════════════════════════════════════════════════════

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(PIN_PIR,        INPUT);
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);

  Wire.begin(21, 22);
  if (!display.begin(0x3C, true)) {
    Serial.println("OLED init failed");
  }
  startupScreen();

  dht.begin();
  delay(1500);

  connectWiFi();

  wifiClient.setInsecure();
  mqtt.setServer(MQTT_BROKER, MQTT_PORT);
  mqtt.setBufferSize(512);
  connectMQTT();

  Serial.println("System ready!");
}

void loop() {
  // Keep connections alive
  if (WiFi.status() != WL_CONNECTED) { digitalWrite(PIN_STATUS_LED, LOW); connectWiFi(); }
  if (!mqtt.connected()) connectMQTT();
  mqtt.loop();

  unsigned long now = millis();

  // Sensor read + display every 2 s
  if (now - lastSensor > SENSOR_INTERVAL_MS) {
    float temp = readTemperature();
    float hum  = readHumidity();
    float soil = readSoilMoisture();
    int   air  = (int)readAirQuality();

    updateDisplay(temp, hum, soil, air);
    lastSensor = now;
  }

  // MQTT publish every 5 s
  if (now - lastPublish >= PUBLISH_INTERVAL_MS) {
    publishSensorData();
    lastPublish = now;
  }

  delay(10);
}
