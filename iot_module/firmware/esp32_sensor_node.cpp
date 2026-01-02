/**
 * ESP32 Sensor Node for Tea Plantation Monitoring
 * ================================================
 * Collects environmental data and transmits via BLE and MQTT.
 *
 * Hardware:
 * - ESP32 DevKit
 * - DHT22 Temperature/Humidity Sensor
 * - Capacitive Soil Moisture Sensor
 * - BH1750 Light Sensor
 *
 * Connections:
 * - DHT22: GPIO 4
 * - Soil Moisture: GPIO 34 (ADC)
 * - BH1750: SDA (GPIO 21), SCL (GPIO 22)
 */

#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <DHT.h>
#include <Wire.h>
#include <BH1750.h>
#include <ArduinoJson.h>
#include <Preferences.h>

// Pin Definitions
#define DHT_PIN 4
#define SOIL_MOISTURE_PIN 34
#define DHT_TYPE DHT22

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define SENSOR_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CONFIG_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// Configuration
#define SAMPLING_INTERVAL_MS 300000  // 5 minutes
#define BLE_ADVERTISING_INTERVAL 1000
#define WIFI_TIMEOUT_MS 10000
#define MQTT_RETRY_INTERVAL 5000

// WiFi and MQTT Configuration (stored in NVS)
Preferences preferences;
String wifiSSID = "";
String wifiPassword = "";
String mqttServer = "";
int mqttPort = 1883;
String deviceId = "";

// Sensor instances
DHT dht(DHT_PIN, DHT_TYPE);
BH1750 lightMeter;

// Network clients
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

// BLE
BLEServer* pServer = NULL;
BLECharacteristic* pSensorCharacteristic = NULL;
BLECharacteristic* pConfigCharacteristic = NULL;
bool bleConnected = false;
bool oldBleConnected = false;

// Sensor data structure
struct SensorData {
    float temperature;
    float humidity;
    float soilMoisture;
    float lightIntensity;
    unsigned long timestamp;
    bool isValid;
} currentData;

// Calibration offsets
float tempOffset = 0.0;
float humidityOffset = 0.0;
float soilMoistureOffset = 0.0;

// Error tracking
int consecutiveErrors = 0;
#define MAX_CONSECUTIVE_ERRORS 5

// Forward declarations
void setupBLE();
void setupWiFi();
void setupMQTT();
void readSensors();
void publishData();
void broadcastBLE();
bool validateReading(float value, float min, float max);

// BLE Server Callbacks
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        bleConnected = true;
        Serial.println("BLE Client Connected");
    }

    void onDisconnect(BLEServer* pServer) {
        bleConnected = false;
        Serial.println("BLE Client Disconnected");
    }
};

// Config Characteristic Callbacks
class ConfigCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String value = pCharacteristic->getValue().c_str();

        // Parse JSON configuration
        DynamicJsonDocument doc(512);
        DeserializationError error = deserializeJson(doc, value);

        if (!error) {
            if (doc.containsKey("wifi_ssid")) {
                wifiSSID = doc["wifi_ssid"].as<String>();
                preferences.putString("wifi_ssid", wifiSSID);
            }
            if (doc.containsKey("wifi_pass")) {
                wifiPassword = doc["wifi_pass"].as<String>();
                preferences.putString("wifi_pass", wifiPassword);
            }
            if (doc.containsKey("mqtt_server")) {
                mqttServer = doc["mqtt_server"].as<String>();
                preferences.putString("mqtt_server", mqttServer);
            }
            if (doc.containsKey("mqtt_port")) {
                mqttPort = doc["mqtt_port"];
                preferences.putInt("mqtt_port", mqttPort);
            }
            if (doc.containsKey("temp_offset")) {
                tempOffset = doc["temp_offset"];
                preferences.putFloat("temp_offset", tempOffset);
            }
            if (doc.containsKey("humidity_offset")) {
                humidityOffset = doc["humidity_offset"];
                preferences.putFloat("hum_offset", humidityOffset);
            }

            Serial.println("Configuration updated");

            // Reconnect with new settings
            if (doc.containsKey("wifi_ssid") || doc.containsKey("mqtt_server")) {
                setupWiFi();
                setupMQTT();
            }
        }
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println("Tea Plantation Sensor Node Starting...");

    // Initialize preferences
    preferences.begin("tea-sensor", false);
    loadConfiguration();

    // Generate device ID if not set
    if (deviceId.length() == 0) {
        uint8_t mac[6];
        WiFi.macAddress(mac);
        deviceId = String(mac[4], HEX) + String(mac[5], HEX);
        preferences.putString("device_id", deviceId);
    }

    // Initialize sensors
    dht.begin();
    Wire.begin();

    if (!lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
        Serial.println("Warning: BH1750 not found");
    }

    // Initialize analog for soil moisture
    analogReadResolution(12);  // 12-bit resolution (0-4095)

    // Initialize BLE
    setupBLE();

    // Initialize WiFi and MQTT if configured
    if (wifiSSID.length() > 0) {
        setupWiFi();
        if (WiFi.status() == WL_CONNECTED && mqttServer.length() > 0) {
            setupMQTT();
        }
    }

    Serial.println("Initialization complete");
}

void loadConfiguration() {
    wifiSSID = preferences.getString("wifi_ssid", "");
    wifiPassword = preferences.getString("wifi_pass", "");
    mqttServer = preferences.getString("mqtt_server", "");
    mqttPort = preferences.getInt("mqtt_port", 1883);
    deviceId = preferences.getString("device_id", "");
    tempOffset = preferences.getFloat("temp_offset", 0.0);
    humidityOffset = preferences.getFloat("hum_offset", 0.0);
    soilMoistureOffset = preferences.getFloat("soil_offset", 0.0);
}

void setupBLE() {
    BLEDevice::init("TeaSensor-" + deviceId);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Sensor data characteristic (notify)
    pSensorCharacteristic = pService->createCharacteristic(
        SENSOR_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pSensorCharacteristic->addDescriptor(new BLE2902());

    // Configuration characteristic (write)
    pConfigCharacteristic = pService->createCharacteristic(
        CONFIG_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
    );
    pConfigCharacteristic->setCallbacks(new ConfigCallbacks());

    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    BLEDevice::startAdvertising();

    Serial.println("BLE Advertising started");
}

void setupWiFi() {
    if (wifiSSID.length() == 0) return;

    Serial.print("Connecting to WiFi: ");
    Serial.println(wifiSSID);

    WiFi.mode(WIFI_STA);
    WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

    unsigned long startTime = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - startTime < WIFI_TIMEOUT_MS) {
        delay(500);
        Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi Connected");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\nWiFi Connection Failed");
    }
}

void setupMQTT() {
    if (mqttServer.length() == 0) return;

    mqttClient.setServer(mqttServer.c_str(), mqttPort);
    reconnectMQTT();
}

void reconnectMQTT() {
    if (!mqttClient.connected() && WiFi.status() == WL_CONNECTED) {
        Serial.print("Connecting to MQTT...");

        String clientId = "TeaSensor-" + deviceId;

        if (mqttClient.connect(clientId.c_str())) {
            Serial.println("connected");

            // Subscribe to configuration topic
            String configTopic = "tea/sensors/" + deviceId + "/config";
            mqttClient.subscribe(configTopic.c_str());
        } else {
            Serial.print("failed, rc=");
            Serial.println(mqttClient.state());
        }
    }
}

void readSensors() {
    currentData.timestamp = millis();
    currentData.isValid = true;

    // Read temperature and humidity
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();

    if (!isnan(temp) && validateReading(temp, -10, 50)) {
        currentData.temperature = temp + tempOffset;
    } else {
        Serial.println("Temperature reading error");
        currentData.isValid = false;
    }

    if (!isnan(hum) && validateReading(hum, 0, 100)) {
        currentData.humidity = hum + humidityOffset;
    } else {
        Serial.println("Humidity reading error");
        currentData.isValid = false;
    }

    // Read soil moisture (capacitive sensor)
    int soilRaw = analogRead(SOIL_MOISTURE_PIN);
    // Convert to percentage (calibrate based on your sensor)
    // Dry: ~3500, Wet: ~1500
    currentData.soilMoisture = map(soilRaw, 3500, 1500, 0, 100);
    currentData.soilMoisture = constrain(currentData.soilMoisture + soilMoistureOffset, 0, 100);

    // Read light intensity
    float lux = lightMeter.readLightLevel();
    if (lux >= 0) {
        currentData.lightIntensity = lux;
    } else {
        Serial.println("Light sensor reading error");
        currentData.lightIntensity = -1;
    }

    // Track errors
    if (!currentData.isValid) {
        consecutiveErrors++;
        if (consecutiveErrors >= MAX_CONSECUTIVE_ERRORS) {
            Serial.println("Too many consecutive errors, restarting...");
            ESP.restart();
        }
    } else {
        consecutiveErrors = 0;
    }

    // Debug output
    Serial.printf("T: %.1f°C, H: %.1f%%, Soil: %.1f%%, Light: %.0f lux\n",
        currentData.temperature,
        currentData.humidity,
        currentData.soilMoisture,
        currentData.lightIntensity
    );
}

bool validateReading(float value, float min, float max) {
    return value >= min && value <= max;
}

void publishData() {
    // Create JSON payload
    DynamicJsonDocument doc(256);

    doc["device_id"] = deviceId;
    doc["timestamp"] = currentData.timestamp;
    doc["temperature"] = currentData.temperature;
    doc["humidity"] = currentData.humidity;
    doc["soil_moisture"] = currentData.soilMoisture;
    doc["light_intensity"] = currentData.lightIntensity;
    doc["is_valid"] = currentData.isValid;

    String payload;
    serializeJson(doc, payload);

    // Publish via MQTT if connected
    if (mqttClient.connected()) {
        String topic = "tea/sensors/" + deviceId + "/data";
        mqttClient.publish(topic.c_str(), payload.c_str());
        Serial.println("Published to MQTT");
    }
}

void broadcastBLE() {
    if (bleConnected) {
        // Create JSON payload
        DynamicJsonDocument doc(256);

        doc["t"] = round(currentData.temperature * 10) / 10.0;  // 1 decimal
        doc["h"] = round(currentData.humidity * 10) / 10.0;
        doc["s"] = round(currentData.soilMoisture);
        doc["l"] = round(currentData.lightIntensity);
        doc["ts"] = currentData.timestamp;
        doc["v"] = currentData.isValid;

        String payload;
        serializeJson(doc, payload);

        pSensorCharacteristic->setValue(payload.c_str());
        pSensorCharacteristic->notify();

        Serial.println("BLE notification sent");
    }

    // Handle reconnection
    if (!bleConnected && oldBleConnected) {
        delay(500);
        pServer->startAdvertising();
        Serial.println("Restarting BLE advertising");
    }
    oldBleConnected = bleConnected;
}

unsigned long lastSampleTime = 0;
unsigned long lastMQTTRetry = 0;

void loop() {
    // Maintain MQTT connection
    if (WiFi.status() == WL_CONNECTED && mqttServer.length() > 0) {
        if (!mqttClient.connected() && millis() - lastMQTTRetry > MQTT_RETRY_INTERVAL) {
            reconnectMQTT();
            lastMQTTRetry = millis();
        }
        mqttClient.loop();
    }

    // Sample sensors at interval
    if (millis() - lastSampleTime >= SAMPLING_INTERVAL_MS) {
        readSensors();

        if (currentData.isValid) {
            publishData();
            broadcastBLE();
        }

        lastSampleTime = millis();
    }

    delay(100);
}
