/* ESP32 Soil Monitoring - COMPLETE VERSION WITH WIFI/MQTT AND BATCH UPLOAD */

#include <HardwareSerial.h>
#include <SD.h>
#include <SPI.h>
#include <vector>
#include <ctype.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// Pin definitions
#define RXD2 16
#define TXD2 17
#define RE_DE 4
#define BUZZER_PIN 25
#define BUTTON_PIN 32
#define SD_CS 5
#define SIM800_RX_PIN 26
#define SIM800_TX_PIN 27
#define LED_PIN 2

HardwareSerial RS485(2);
HardwareSerial sim800(1);

// ========== WiFi & MQTT CONFIGURATION ==========
const char* ssid = "Ashwin";
const char* password = "Ashwin@2002";
const char* mqtt_server = "16ecfb92158844a691fe89ef4c42565e.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "iteagrow";
const char* mqtt_pass = "iTeagrow123";
const char* mqtt_topic = "test/iot";

// ========== FARM STRUCTURE CONFIGURATION ==========
const char* DIVISION_ID = "north_estate_01";
const int BLOCKS_PER_DIVISION = 3;
const int HECTARES_PER_BLOCK = 10;
const int TOTAL_HECTARES = 25;

// HiveMQ Cloud Root CA (Let's Encrypt)
const char* root_ca = \
"-----BEGIN CERTIFICATE-----\n" \
"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\n" \
"-----END CERTIFICATE-----\n";

// ========== WiFi and MQTT clients ==========
WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);
bool wifiConnected = false;
bool mqttConnected = false;
unsigned long lastReconnectAttempt = 0;
const unsigned long RECONNECT_INTERVAL = 30000;

// ========== Batch data structure ==========
struct BatchData {
  int block_id;
  int hectare_id;
  float avg_temp;
  float avg_hum;
  float avg_ec;
  float avg_ph;
  float avg_n;
  float avg_p;
  float avg_k;
  int reading_count;
  unsigned long timestamp;
  bool uploaded;
};

// ========== Pending uploads queue ==========
std::vector<BatchData> pendingUploads;
const int MAX_PENDING_UPLOADS = 50;

const long SENSOR_BAUD = 4800;
int currentArea = 1;
int currentBlock = 1;
int currentHectare = 1;
bool buttonPressed = false;
unsigned long lastButtonPress = 0;
const unsigned long DEBOUNCE_DELAY = 500;
float tempSum = 0, humSum = 0, ecSum = 0, phSum = 0, nSum = 0, pSum = 0, kSum = 0;
int readingCount = 0;
const int REQUIRED_READINGS = 20;
bool sdCardInitialized = false;
String FARMER_PHONE = "+94762866142";

// Timing variables
unsigned long lastSoilReadingTime = 0;
const unsigned long SOIL_READING_INTERVAL = 5000;
unsigned long lastAirWaterWarningTime = 0;
const unsigned long AIR_WATER_WARNING_INTERVAL = 5000;

// Buzzer state control
bool buzzerState = false;
unsigned long buzzerStartTime = 0;
unsigned long buzzerDuration = 0;

// LED for connection status
bool ledState = false;
unsigned long lastLedBlink = 0;

struct Sample {
  float temp, hum, ec, ph, n, p, k;
  bool isValid;
  String sensorState;
};

struct TriResult {
  String status;
  int matchPercent;
  String recommendations;
};

// Function declarations
uint16_t modbusCRC(byte *buf, int len);
Sample readSensorData();
bool initSDCard();
void saveDataToSD(const Sample &data);
void saveBatchToSD(const BatchData &batch);
Sample calculateAverage();
void enhancedLoop();
void checkButton();
void manualSoilCheck();
void sendSMS(const String &message);
void processAreaData();
void startBeep(unsigned long duration);
void updateBuzzer();
String toUpperCaseString(String str);
bool publishToMQTT(const BatchData &data);
void uploadPendingBatches();
void loadPendingUploads();
void setupWiFi();
bool connectMQTT();
void checkWiFiAndMQTT();
void mqttCallback(char* topic, byte* payload, unsigned int length);
void publishSoilData(int blockId, int hectareId, Sample &avgData);
String predictSoilHealthML(const Sample &s);
TriResult checkTRI(const Sample &s);
String composeSMS(const Sample &avg, const String &mlPrediction, const TriResult &tri, int blockId, int hectareId);
void playBeepPattern(int pattern);

// ========== WiFi/MQTT Functions ==========
void setupWiFi() {
  Serial.print("📡 Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("📶 IP Address: ");
    Serial.println(WiFi.localIP());
    digitalWrite(LED_PIN, HIGH);
  } else {
    wifiConnected = false;
    Serial.println("\n❌ WiFi Connection Failed - Will retry later");
    digitalWrite(LED_PIN, LOW);
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("📨 Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
}

bool connectMQTT() {
  if (!wifiConnected) return false;
  
  Serial.print("🔌 Connecting to HiveMQ Cloud...");
  
  espClient.setCACert(root_ca);
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  
  String clientId = "ESP32-" + String(random(0xffff), HEX);
  
  if (mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
    mqttConnected = true;
    Serial.println("✅ Connected to HiveMQ Cloud!");
    return true;
  } else {
    mqttConnected = false;
    Serial.print("❌ Connection failed, rc=");
    Serial.println(mqttClient.state());
    return false;
  }
}

void checkWiFiAndMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    mqttConnected = false;
    digitalWrite(LED_PIN, LOW);
    Serial.println("📡 WiFi disconnected, attempting reconnect...");
    WiFi.reconnect();
  } else {
    wifiConnected = true;
    
    if (!mqttConnected) {
      unsigned long now = millis();
      if (now - lastLedBlink > 1000) {
        lastLedBlink = now;
        ledState = !ledState;
        digitalWrite(LED_PIN, ledState);
      }
      
      unsigned long now2 = millis();
      if (now2 - lastReconnectAttempt > RECONNECT_INTERVAL) {
        lastReconnectAttempt = now2;
        connectMQTT();
      }
    } else {
      digitalWrite(LED_PIN, HIGH);
      mqttClient.loop();
    }
  }
}

void publishSoilData(int blockId, int hectareId, Sample &avgData) {
  if (!mqttConnected) return;
  
  StaticJsonDocument<512> doc;
  
  doc["division_id"] = DIVISION_ID;
  doc["block_id"] = blockId;
  doc["hectare_id"] = hectareId;
  doc["avg_temp"] = avgData.temp;
  doc["avg_hum"] = avgData.hum;
  doc["avg_ec"] = avgData.ec;
  doc["avg_ph"] = avgData.ph;
  doc["avg_n"] = avgData.n;
  doc["avg_p"] = avgData.p;
  doc["avg_k"] = avgData.k;
  doc["reading_count"] = readingCount;
  doc["timestamp"] = millis();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  if (mqttClient.publish(mqtt_topic, jsonString.c_str())) {
    Serial.println("✅ Soil data published to cloud");
    Serial.println(jsonString);
  } else {
    Serial.println("❌ Failed to publish soil data");
  }
}

// ========== Publish to MQTT ==========
bool publishToMQTT(const BatchData &data) {
  if (!mqttConnected) return false;
  
  StaticJsonDocument<512> doc;
  
  doc["division_id"] = DIVISION_ID;
  doc["block_id"] = data.block_id;
  doc["hectare_id"] = data.hectare_id;
  doc["avg_temp"] = data.avg_temp;
  doc["avg_hum"] = data.avg_hum;
  doc["avg_ec"] = data.avg_ec;
  doc["avg_ph"] = data.avg_ph;
  doc["avg_n"] = data.avg_n;
  doc["avg_p"] = data.avg_p;
  doc["avg_k"] = data.avg_k;
  doc["reading_count"] = data.reading_count;
  doc["timestamp"] = data.timestamp;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  if (mqttClient.publish(mqtt_topic, jsonString.c_str())) {
    Serial.println("✅ Published: " + jsonString);
    return true;
  }
  return false;
}

void saveBatchToSD(const BatchData &batch) {
  if (!sdCardInitialized) return;
  
  String filename = "/batches.csv";
  File file = SD.open(filename.c_str(), FILE_APPEND);
  
  if (file) {
    if (file.size() == 0) {
      file.println("#block_id,hectare_id,avg_temp,avg_hum,avg_ec,avg_ph,avg_n,avg_p,avg_k,reading_count,timestamp,uploaded");
    }
    
    file.print(batch.block_id);
    file.print(",");
    file.print(batch.hectare_id);
    file.print(",");
    file.print(batch.avg_temp, 1);
    file.print(",");
    file.print(batch.avg_hum, 1);
    file.print(",");
    file.print(batch.avg_ec, 0);
    file.print(",");
    file.print(batch.avg_ph, 1);
    file.print(",");
    file.print(batch.avg_n, 0);
    file.print(",");
    file.print(batch.avg_p, 0);
    file.print(",");
    file.print(batch.avg_k, 0);
    file.print(",");
    file.print(batch.reading_count);
    file.print(",");
    file.print(batch.timestamp);
    file.print(",");
    file.println(batch.uploaded ? 1 : 0);
    
    file.close();
    Serial.println("✅ Batch saved to SD");
  } else {
    Serial.println("❌ Error saving batch to SD");
  }
}

void loadPendingUploads() {
  if (!sdCardInitialized) return;
  
  Serial.println("📂 Loading pending uploads from SD card...");
  
  File file = SD.open("/batches.csv", FILE_READ);
  if (!file) {
    Serial.println("No pending uploads file found");
    return;
  }
  
  pendingUploads.clear();
  
  while (file.available()) {
    String line = file.readStringUntil('\n');
    if (line.length() > 0 && line[0] != '#') {
      int commaIndex = 0;
      BatchData data;
      
      data.block_id = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toInt();
      data.hectare_id = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toInt();
      data.avg_temp = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_hum = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_ec = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_ph = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_n = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_p = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.avg_k = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toFloat();
      data.reading_count = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toInt();
      data.timestamp = line.substring(commaIndex, commaIndex = line.indexOf(',', commaIndex+1)).toInt();
      data.uploaded = line.substring(commaIndex).toInt();
      
      if (!data.uploaded) {
        pendingUploads.push_back(data);
      }
    }
  }
  
  file.close();
  Serial.printf("📊 Loaded %d pending uploads\n", pendingUploads.size());
}

void uploadPendingBatches() {
  if (!mqttConnected || pendingUploads.empty()) return;
  
  Serial.println("📤 Uploading pending batches...");
  
  for (auto it = pendingUploads.begin(); it != pendingUploads.end(); ) {
    if (publishToMQTT(*it)) {
      it->uploaded = true;
      saveBatchToSD(*it);
      it = pendingUploads.erase(it);
      delay(500);
    } else {
      ++it;
    }
  }
  
  Serial.printf("✅ Upload complete. %d batches remaining\n", pendingUploads.size());
}

// ========== RANDOM FOREST MODEL FUNCTIONS ==========
int tree_predict_0(float features[]) {
    if (features[4] <= 0.320000) {
        if (features[4] <= 0.305000) {
            return 1;
        } else {
            if (features[1] <= 112.209999) {
                return 0;
            } else {
                return 1;
            }
        }
    } else {
        return 1;
    }
}

int tree_predict_1(float features[]) {
    if (features[1] <= 108.474998) {
        return 1;
    } else {
        if (features[6] <= 49.305000) {
            if (features[3] <= 169.195000) {
                return 1;
            } else {
                if (features[2] <= 23.420000) {
                    return 1;
                } else {
                    if (features[2] <= 30.184999) {
                        return 0;
                    } else {
                        return 1;
                    }
                }
            }
        } else {
            return 1;
        }
    }
}

int tree_predict_2(float features[]) {
    if (features[4] <= 0.325000) {
        if (features[3] <= 171.680000) {
            return 1;
        } else {
            if (features[2] <= 29.080000) {
                return 0;
            } else {
                return 1;
            }
        }
    } else {
        return 1;
    }
}

int tree_predict_3(float features[]) {
    if (features[1] <= 108.474998) {
        return 1;
    } else {
        if (features[3] <= 171.954994) {
            return 1;
        } else {
            if (features[1] <= 129.040001) {
                return 0;
            } else {
                return 1;
            }
        }
    }
}

int tree_predict_4(float features[]) {
    if (features[6] <= 49.235001) {
        if (features[2] <= 23.305000) {
            return 1;
        } else {
            if (features[2] <= 24.800000) {
                return 0;
            } else {
                return 1;
            }
        }
    } else {
        return 1;
    }
}

int tree_predict_5(float features[]) {
    return 1;
}

int tree_predict_6(float features[]) {
    if (features[1] <= 108.474998) {
        return 1;
    } else {
        if (features[4] <= 0.320000) {
            if (features[6] <= 50.530001) {
                if (features[1] <= 112.209999) {
                    return 0;
                } else {
                    return 1;
                }
            } else {
                return 1;
            }
        } else {
            return 1;
        }
    }
}

int rf_predict(float features[]) {
    int votes[3]; 
    for(int i=0;i<3;i++) votes[i]=0;
    
    int v0 = tree_predict_0(features);
    votes[v0]++;
    int v1 = tree_predict_1(features);
    votes[v1]++;
    int v2 = tree_predict_2(features);
    votes[v2]++;
    int v3 = tree_predict_3(features);
    votes[v3]++;
    int v4 = tree_predict_4(features);
    votes[v4]++;
    int v5 = tree_predict_5(features);
    votes[v5]++;
    int v6 = tree_predict_6(features);
    votes[v6]++;
    
    int best=0; 
    for(int i=1;i<3;i++) 
        if(votes[i]>votes[best]) best=i;
    
    return best;
}

String predictSoilHealthML(const Sample &s) {
  float features[7];
  features[0] = s.ph;
  features[1] = s.n / 100.0;
  features[2] = s.p / 100.0;
  features[3] = s.k / 100.0;
  features[4] = s.ec / 1000.0;
  features[5] = s.temp;
  features[6] = s.hum;
  
  int prediction = rf_predict(features);
  
  const char* labels[] = {"Healthy", "Medium", "Poor"};
  return String(labels[prediction]);
}

// ========== TRI ANALYSIS FUNCTIONS ==========
TriResult checkTRI(const Sample &s) {
  int score = 0, total = 6;
  
  if (s.ph >= 4.5 && s.ph <= 5.5) score++;
  if (s.n >= 20.0 && s.n <= 30.0) score++;
  if (s.p >= 10.0 && s.p <= 20.0) score++;
  if (s.k >= 20.0 && s.k <= 30.0) score++;
  if (s.hum >= 40.0 && s.hum <= 70.0) score++;
  if (s.temp >= 18.0 && s.temp <= 25.0) score++;
  
  int pct = (score * 100) / total;
  String status;
  
  if (pct >= 80) status = "Excellent";
  else if (pct >= 60) status = "Good";
  else if (pct >= 40) status = "Fair";
  else status = "Poor";
  
  String recommendations = "";
  
  if (s.ph < 4.5) recommendations += "Apply 400-1000 kg Dolomite per acre. ";
  else if (s.ph > 5.5) recommendations += "Add sulfur to lower pH. ";
  
  if (s.n < 20.0) {
    float nitrogenDeficiency = (20.0 - s.n) * 2.0;
    recommendations += "Apply " + String(nitrogenDeficiency, 0) + " kg N/acre (Use VP/UM 910). ";
  }
  
  if (s.p < 10.0) {
    float pDeficiency = (10.0 - s.p) * 3.0;
    recommendations += "Apply " + String(pDeficiency, 0) + " kg P2O5/acre. ";
  }
  
  if (s.k < 20.0) {
    float kDeficiency = (20.0 - s.k) * 4.0;
    recommendations += "Apply " + String(kDeficiency, 0) + " kg K2O/acre. ";
  }
  
  if (s.hum < 40.0) recommendations += "Irrigation needed (maintain 80-85% field capacity). ";
  else if (s.hum > 70.0) recommendations += "Improve drainage. ";
  
  if (s.temp < 18.0) recommendations += "Soil temp low for optimal growth. ";
  else if (s.temp > 25.0) recommendations += "Soil temp high, consider shade management. ";
  
  recommendations += "Apply 2-4 kg Zinc Sulphate per acre as foliar spray. ";
  recommendations += "Apply in 4-6 splits during rainy seasons. ";
  recommendations += "Broadcast in 'clean strip' under canopy. ";
  
  if (recommendations == "") {
    recommendations = "Soil is optimal for up-country tea. Continue standard maintenance.";
  }
  
  TriResult result;
  result.status = status;
  result.matchPercent = pct;
  result.recommendations = recommendations;
  
  return result;
}

String composeSMS(const Sample &avg, const String &mlPrediction, const TriResult &tri, int blockId, int hectareId) {
  String sms = "";
  sms += "Tea Soil Report\n";
  sms += "Division: ";
  sms += DIVISION_ID;
  sms += "\n";
  sms += "Block: ";
  sms += String(blockId);
  sms += " | Hectare: ";
  sms += String(hectareId);
  sms += "\n";
  sms += "=========================\n";
  sms += "Temp: ";
  sms += String(avg.temp, 1);
  sms += "C (Optimal:18-25C)\n";
  sms += "Moisture: ";
  sms += String(avg.hum, 1);
  sms += "% (Target:40-70%)\n";
  sms += "pH: ";
  sms += String(avg.ph, 1);
  sms += " (Optimal:4.5-5.5)\n";
  sms += "EC: ";
  sms += String(avg.ec, 0);
  sms += " uS/cm (<200 ideal)\n";
  sms += "N: ";
  sms += String(avg.n, 0);
  sms += " mg/kg (Target:20-30)\n";
  sms += "P: ";
  sms += String(avg.p, 0);
  sms += " mg/kg (Target:10-20)\n";
  sms += "K: ";
  sms += String(avg.k, 0);
  sms += " mg/kg (Target:20-30)\n";
  sms += "=========================\n";
  sms += "ML Prediction: ";
  sms += mlPrediction;
  sms += "\n";
  sms += "TRI Assessment: ";
  sms += tri.status;
  sms += " (";
  sms += String(tri.matchPercent);
  sms += "% match)\n";
  sms += "=========================\n";
  sms += "RECOMMENDATIONS (per acre):\n";
  sms += tri.recommendations;
  sms += "\n=========================";
  
  return sms;
}

// ========== SENSOR READING FUNCTIONS ==========
uint16_t modbusCRC(byte *buf, int len) {
  uint16_t crc = 0xFFFF;
  for (int pos = 0; pos < len; pos++) {
    crc ^= buf[pos];
    for (int i = 0; i < 8; i++) {
      if (crc & 1)
        crc = (crc >> 1) ^ 0xA001;
      else
        crc >>= 1;
    }
  }
  return crc;
}

Sample readSensorData() {
  Sample sensorData = {0, 0, 0, 0, 0, 0, 0, false, "unknown"};
  
  byte cmd[8] = {0x01, 0x03, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00};
  uint16_t crc = modbusCRC(cmd, 6);
  cmd[6] = crc & 0xFF;
  cmd[7] = crc >> 8;
  
  while(RS485.available()) RS485.read();
  
  digitalWrite(RE_DE, HIGH);
  delay(10);
  RS485.write(cmd, 8);
  RS485.flush();
  digitalWrite(RE_DE, LOW);
  
  delay(300);
  
  byte resp[32];
  int bytesRead = RS485.readBytes(resp, 32);
  
  if(bytesRead < 29) {
    return sensorData;
  }
  
  sensorData.hum = ((resp[3] << 8) | resp[4]) / 10.0;
  sensorData.temp = ((resp[5] << 8) | resp[6]) / 10.0;
  sensorData.ec = ((resp[7] << 8) | resp[8]);
  sensorData.ph = ((resp[9] << 8) | resp[10]) / 10.0;
  sensorData.n = ((resp[13] << 8) | resp[14]);
  sensorData.p = ((resp[17] << 8) | resp[18]);
  sensorData.k = ((resp[19] << 8) | resp[20]);
  
  if(sensorData.hum > 5.0 && sensorData.ec > 10 && 
     sensorData.n < 1000 && sensorData.p < 1000 && sensorData.k < 1000) {
    sensorData.sensorState = "soil";
  } else if(sensorData.hum <= 5.0 && sensorData.ec == 0) {
    sensorData.sensorState = "air";
  } else {
    sensorData.sensorState = "water";
  }
  
  sensorData.isValid = true;
  
  return sensorData;
}

bool initSDCard() {
  Serial.println("Mounting SD...");
  SPI.begin(18, 19, 23, SD_CS);
  delay(1000);
  
  if (!SD.begin(SD_CS)) {
    Serial.println("SD Mount Failed!");
    playBeepPattern(5);
    return false;
  }
  
  Serial.println("SD Mounted!");
  playBeepPattern(3);
  return true;
}

void saveDataToSD(const Sample &data) {
  if (!sdCardInitialized || !data.isValid) return;
  
  String filename = "/area_" + String(currentArea) + ".csv";
  File file = SD.open(filename.c_str(), FILE_APPEND);
  
  if (file) {
    if (file.size() == 0) {
      file.println("timestamp,temp_C,humidity_percent,ec_us_cm,ph,nitrogen_mg_kg,phosphorus_mg_kg,potassium_mg_kg,state");
    }
    
    file.print(millis());
    file.print(",");
    file.print(data.temp, 1);
    file.print(",");
    file.print(data.hum, 1);
    file.print(",");
    file.print(data.ec, 0);
    file.print(",");
    file.print(data.ph, 1);
    file.print(",");
    file.print(data.n, 0);
    file.print(",");
    file.print(data.p, 0);
    file.print(",");
    file.println(data.k, 0);
    
    file.close();
    Serial.println("Data saved to SD");
    
    playBeepPattern(1);
  } else {
    Serial.println("Error opening file!");
    playBeepPattern(5);
  }
}

Sample calculateAverage() {
  Sample avg = {0, 0, 0, 0, 0, 0, 0, false, ""};
  
  if (readingCount > 0) {
    avg.temp = tempSum / readingCount;
    avg.hum = humSum / readingCount;
    avg.ec = ecSum / readingCount;
    avg.ph = phSum / readingCount;
    avg.n = nSum / readingCount;
    avg.p = pSum / readingCount;
    avg.k = kSum / readingCount;
    avg.isValid = true;
    avg.sensorState = "soil";
  }
  
  return avg;
}

void sendSMS(const String &message) {
  Serial.println("Sending SMS...");
  
  sim800.println("AT+CMGF=1");
  delay(1000);
  
  sim800.print("AT+CMGS=\"");
  sim800.print(FARMER_PHONE);
  sim800.println("\"");
  delay(1000);
  
  sim800.print(message);
  delay(1000);
  
  sim800.write(26);
  delay(5000);
  
  String response = "";
  while (sim800.available()) {
    response += sim800.readString();
  }
  
  if (response.indexOf("OK") != -1 || response.indexOf("+CMGS") != -1) {
    Serial.println("SMS sent successfully!");
    playBeepPattern(3);
  } else {
    Serial.println("SMS sending failed!");
    playBeepPattern(5);
  }
}

void processAreaData() {
  if (readingCount >= REQUIRED_READINGS) {
    Sample avgData = calculateAverage();
    
    if (avgData.isValid) {
      int currentBlock = ((currentArea - 1) / HECTARES_PER_BLOCK) + 1;
      int currentHectare = ((currentArea - 1) % HECTARES_PER_BLOCK) + 1;
      
      BatchData batch;
      batch.block_id = currentBlock;
      batch.hectare_id = currentHectare;
      batch.avg_temp = avgData.temp;
      batch.avg_hum = avgData.hum;
      batch.avg_ec = avgData.ec;
      batch.avg_ph = avgData.ph;
      batch.avg_n = avgData.n;
      batch.avg_p = avgData.p;
      batch.avg_k = avgData.k;
      batch.reading_count = readingCount;
      batch.timestamp = millis();
      batch.uploaded = false;
      
      saveBatchToSD(batch);
      pendingUploads.push_back(batch);
      
      Serial.println("\n📊 BATCH DATA READY:");
      Serial.printf("Division: %s\n", DIVISION_ID);
      Serial.printf("Block: %d, Hectare: %d\n", batch.block_id, batch.hectare_id);
      Serial.printf("Avg N: %.1f, P: %.1f, K: %.1f\n", batch.avg_n, batch.avg_p, batch.avg_k);
      Serial.printf("Avg pH: %.1f, EC: %.0f\n", batch.avg_ph, batch.avg_ec);
      Serial.printf("Avg Temp: %.1f°C, Humidity: %.1f%%\n", batch.avg_temp, batch.avg_hum);
      Serial.printf("Readings: %d\n", batch.reading_count);
      
      if (mqttConnected) {
        if (publishToMQTT(batch)) {
          batch.uploaded = true;
          saveBatchToSD(batch);
          pendingUploads.pop_back();
          
          startBeep(200);
          delay(100);
          startBeep(200);
        } else {
          Serial.println("⚠️ Will retry upload later");
        }
      } else {
        Serial.println("⚠️ No connection - saved for later upload");
      }
      
      String mlPrediction = predictSoilHealthML(avgData);
      TriResult triResult = checkTRI(avgData);
      String smsMessage = composeSMS(avgData, mlPrediction, triResult, currentBlock, currentHectare);
      
      Serial.println("\n📱 SMS MESSAGE:");
      Serial.println(smsMessage);
      
      sendSMS(smsMessage);
    }
  } else {
    Serial.println("Not enough readings to send SMS!");
    playBeepPattern(5);
  }
}

// ========== BUZZER FUNCTIONS ==========
void startBeep(unsigned long duration) {
  digitalWrite(BUZZER_PIN, LOW);
  buzzerState = true;
  buzzerStartTime = millis();
  buzzerDuration = duration;
}

void updateBuzzer() {
  if (buzzerState && (millis() - buzzerStartTime >= buzzerDuration)) {
    digitalWrite(BUZZER_PIN, HIGH);
    buzzerState = false;
  }
}

void playBeepPattern(int pattern) {
  switch(pattern) {
    case 1:
      digitalWrite(BUZZER_PIN, LOW);
      delay(500);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
      
    case 2:
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      delay(150);
      digitalWrite(BUZZER_PIN, LOW);
      delay(500);
      digitalWrite(BUZZER_PIN, HIGH);
      delay(150);
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
      
    case 3:
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      delay(100);
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
      
    case 4:
      for(int i = 0; i < 3; i++) {
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
        digitalWrite(BUZZER_PIN, HIGH);
        if (i < 2) delay(100);
      }
      break;
      
    case 5:
      digitalWrite(BUZZER_PIN, LOW);
      delay(1000);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
  }
}

void enhancedLoop() {
  checkButton();
  updateBuzzer();
  
  if (readingCount < REQUIRED_READINGS) {
    Sample sensorData = readSensorData();
    
    if (sensorData.isValid) {
      Serial.println("=== SENSOR DATA ===");
      Serial.printf("Temperature: %.1f C\n", sensorData.temp);
      Serial.printf("Humidity: %.1f %%\n", sensorData.hum);
      Serial.printf("EC: %.0f uS/cm\n", sensorData.ec);
      Serial.printf("pH: %.1f\n", sensorData.ph);
      Serial.printf("Nitrogen: %.0f mg/kg\n", sensorData.n);
      Serial.printf("Phosphorus: %.0f mg/kg\n", sensorData.p);
      Serial.printf("Potassium: %.0f mg/kg\n", sensorData.k);
      Serial.print("State: ");
      Serial.println(sensorData.sensorState);
      
      if (sensorData.sensorState == "soil" && sensorData.hum > 5.0 && sensorData.ec > 10) {
        unsigned long currentTime = millis();
        
        if (currentTime - lastSoilReadingTime >= SOIL_READING_INTERVAL || lastSoilReadingTime == 0) {
          Serial.println("SOIL DETECTED - Saving data");
          
          saveDataToSD(sensorData);
          
          tempSum += sensorData.temp;
          humSum += sensorData.hum;
          ecSum += sensorData.ec;
          phSum += sensorData.ph;
          nSum += sensorData.n;
          pSum += sensorData.p;
          kSum += sensorData.k;
          
          readingCount++;
          lastSoilReadingTime = currentTime;
          
          Serial.print("Area: ");
          Serial.print(currentArea);
          Serial.print(" | Readings: ");
          Serial.print(readingCount);
          Serial.print("/");
          Serial.println(REQUIRED_READINGS);
          
          if (readingCount >= REQUIRED_READINGS) {
            Serial.println("\n20 READINGS COMPLETE!");
            Serial.println("Press button to send SMS");
            
            playBeepPattern(2);
          }
        } else {
          unsigned long remainingTime = SOIL_READING_INTERVAL - (currentTime - lastSoilReadingTime);
          Serial.print("Please wait ");
          Serial.print(remainingTime / 1000.0);
          Serial.println(" seconds for next soil reading");
        }
      } 
      else if (sensorData.sensorState == "air" || sensorData.sensorState == "water") {
        unsigned long currentTime = millis();
        
        if (currentTime - lastAirWaterWarningTime >= AIR_WATER_WARNING_INTERVAL) {
          Serial.print("SENSOR IN ");
          Serial.print(toUpperCaseString(sensorData.sensorState));
          Serial.println(" - Not saving data");
          Serial.println("Please insert sensor into soil");
          lastAirWaterWarningTime = currentTime;
        }
        
        delay(1000);
        return;
      } 
      else {
        Serial.println("Readings questionable - check sensor");
      }
    }
    
    Serial.println("================================");
    Serial.println();
    
    if (sensorData.isValid && sensorData.sensorState == "soil" && sensorData.hum > 5.0 && sensorData.ec > 10) {
      unsigned long currentTime = millis();
      unsigned long timeSinceLastReading = currentTime - lastSoilReadingTime;
      
      if (timeSinceLastReading < SOIL_READING_INTERVAL) {
        unsigned long waitTime = SOIL_READING_INTERVAL - timeSinceLastReading;
        Serial.print("Next soil reading in ");
        Serial.print(waitTime / 1000.0);
        Serial.println(" seconds...");
        
        unsigned long waitStart = millis();
        while (millis() - waitStart < waitTime) {
          checkButton();
          updateBuzzer();
          delay(100);
        }
      }
    } else {
      delay(2000);
    }
  } else {
    checkButton();
    updateBuzzer();
    delay(100);
  }
}

void checkButton() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!buttonPressed && (millis() - lastButtonPress) > DEBOUNCE_DELAY) {
      buttonPressed = true;
      lastButtonPress = millis();
      
      Serial.println("\nButton pressed!");
      
      processAreaData();
      
      currentArea++;
      readingCount = 0;
      tempSum = humSum = ecSum = phSum = nSum = pSum = kSum = 0;
      lastSoilReadingTime = 0;
      lastAirWaterWarningTime = 0;
      
      Serial.print("Moving to Area ");
      Serial.println(currentArea);
      
      playBeepPattern(4);
    }
  } else {
    buttonPressed = false;
  }
}

String toUpperCaseString(String str) {
  String result = str;
  for (int i = 0; i < result.length(); i++) {
    result[i] = toupper(result[i]);
  }
  return result;
}

void manualSoilCheck() {
  Serial.println("\n=== MANUAL SOIL CHECK ===");
  Serial.println("If sensor is in soil with good readings,");
  Serial.println("but shows 'water', you can:");
  Serial.println("1. Continue anyway (sensor is working)");
  Serial.println("2. Dry sensor if actually wet");
  Serial.println("3. Check soil moisture (should be 20-80%)");
  Serial.println("================================");
  Serial.println();
}

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n================================");
  Serial.println("SOIL MONITORING WITH ML, TRI, WIFI & MQTT");
  Serial.println("================================");
  
  pinMode(RE_DE, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(RE_DE, LOW);
  digitalWrite(BUZZER_PIN, HIGH);
  digitalWrite(LED_PIN, LOW);
  
  RS485.begin(SENSOR_BAUD, SERIAL_8N1, RXD2, TXD2);
  Serial.print("RS485 at ");
  Serial.print(SENSOR_BAUD);
  Serial.println(" baud");
  
  sim800.begin(9600, SERIAL_8N1, SIM800_RX_PIN, SIM800_TX_PIN);
  delay(3000);
  Serial.println("SIM800L READY");
  
  sdCardInitialized = initSDCard();
  
  loadPendingUploads();
  setupWiFi();
  
  if (wifiConnected) {
    connectMQTT();
  }
  
  Serial.printf("\n📋 Farm: %s, %d blocks, %d hectares\n", 
                DIVISION_ID, BLOCKS_PER_DIVISION, TOTAL_HECTARES);
  Serial.printf("📊 Pending uploads: %d\n", pendingUploads.size());
  
  playBeepPattern(3);
  delay(200);
  playBeepPattern(3);
  
  manualSoilCheck();
  
  Serial.println("System Ready!");
  Serial.println("FEATURES:");
  Serial.println("  - 5 sec delay between soil readings");
  Serial.println("  - WiFi auto-reconnect");
  Serial.println("  - MQTT upload when connected");
  Serial.println("  - SD card batch storage");
  Serial.println("  - Automatic upload pending batches");
  Serial.println("  - 0.5 sec beep after saving data");
  Serial.println("  - Special beep when 20 readings complete");
  Serial.println("  - Success beep when SMS sent");
  Serial.println("  - 3 beeps for area change");
  Serial.println("  - Error beep for failures");
  Serial.println("  - Random Forest ML Prediction");
  Serial.println("  - TRI Analysis with Recommendations");
  Serial.println("Take 20 readings, then press button");
  Serial.println("================================");
  Serial.println();
}

void loop() {
  checkWiFiAndMQTT();
  
  if (mqttConnected && !pendingUploads.empty()) {
    uploadPendingBatches();
  }
  
  enhancedLoop();
  updateBuzzer();
}