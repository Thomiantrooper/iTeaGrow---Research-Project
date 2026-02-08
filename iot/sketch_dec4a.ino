/* ESP32 Soil Monitoring - ENHANCED VERSION WITH ML */

#include <HardwareSerial.h>
#include <SD.h>
#include <SPI.h>
#include <vector>
#include <ctype.h>

// Pin definitions
#define RXD2 16
#define TXD2 17
#define RE_DE 4
#define BUZZER_PIN 25
#define BUTTON_PIN 32
#define SD_CS 5
#define SIM800_RX_PIN 26
#define SIM800_TX_PIN 27

HardwareSerial RS485(2);
HardwareSerial sim800(1);

const long SENSOR_BAUD = 4800;
int currentArea = 1;
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
const unsigned long SOIL_READING_INTERVAL = 5000; // 30 seconds between soil readings
unsigned long lastAirWaterWarningTime = 0;
const unsigned long AIR_WATER_WARNING_INTERVAL = 5000; // 5 seconds between warnings

// Buzzer state control
bool buzzerState = false;
unsigned long buzzerStartTime = 0;
unsigned long buzzerDuration = 0;

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
bool isSensorInSoil(const Sample &data);
bool initSDCard();
void saveDataToSD(const Sample &data);
Sample calculateAverage();
void enhancedLoop();
void checkButton();
void manualSoilCheck();
void sendSMS(const String &message);
void processAreaData();
void startBeep(unsigned long duration);
void updateBuzzer(); // New function to handle buzzer timing
String toUpperCaseString(String str);

// ========== RANDOM FOREST MODEL FUNCTIONS ==========
int tree_predict_0(float features[]);
int tree_predict_1(float features[]);
int tree_predict_2(float features[]);
int tree_predict_3(float features[]);
int tree_predict_4(float features[]);
int tree_predict_5(float features[]);
int tree_predict_6(float features[]);
int rf_predict(float features[]);
String predictSoilHealthML(const Sample &s);
TriResult checkTRI(const Sample &s);
String composeSMS(const Sample &avg, const String &mlPrediction, const TriResult &tri);

// ========== BUZZER PATTERNS ==========
void playBeepPattern(int pattern) {
  switch(pattern) {
    case 1: // Pattern 1: Data saved beep (0.5 second)
      digitalWrite(BUZZER_PIN, LOW);
      delay(500);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
      
    case 2: // Pattern 2: Collection complete (short-long-short)
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
      
    case 3: // Pattern 3: SMS success (two short beeps)
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      delay(100);
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
      
    case 4: // Pattern 4: Area change (3 quick beeps)
      for(int i = 0; i < 3; i++) {
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
        digitalWrite(BUZZER_PIN, HIGH);
        if (i < 2) delay(100);
      }
      break;
      
    case 5: // Pattern 5: Error (one long beep)
      digitalWrite(BUZZER_PIN, LOW);
      delay(1000);
      digitalWrite(BUZZER_PIN, HIGH);
      break;
  }
}

// ========== IMPLEMENTATION ==========

// Helper function to convert string to uppercase
String toUpperCaseString(String str) {
  String result = str;
  for (int i = 0; i < result.length(); i++) {
    result[i] = toupper(result[i]);
  }
  return result;
}

// CRC function
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

// NEW: Function to start a beep for a specific duration
void startBeep(unsigned long duration) {
  digitalWrite(BUZZER_PIN, LOW);  // Turn active buzzer ON
  buzzerState = true;
  buzzerStartTime = millis();
  buzzerDuration = duration;
}

// NEW: Function to update buzzer state based on timing
void updateBuzzer() {
  if (buzzerState && (millis() - buzzerStartTime >= buzzerDuration)) {
    digitalWrite(BUZZER_PIN, HIGH);  // Turn active buzzer OFF
    buzzerState = false;
  }
}

// ========== RANDOM FOREST IMPLEMENTATION ==========
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

// ML Prediction function
String predictSoilHealthML(const Sample &s) {
  // Prepare features: [pH, N, P, K, EC, Temp, Moisture]
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

// ========== TRI ANALYSIS FUNCTIONS (UPDATED FOR 1 ACRE) ==========
TriResult checkTRI(const Sample &s) {
  int score = 0, total = 6;
  
  // Tea-specific optimal ranges for up-country Sri Lanka
  if (s.ph >= 4.5 && s.ph <= 5.5) score++;
  if (s.n >= 20.0 && s.n <= 30.0) score++;
  if (s.p >= 10.0 && s.p <= 20.0) score++;
  if (s.k >= 20.0 && s.k <= 30.0) score++;
  if (s.hum >= 40.0 && s.hum <= 70.0) score++;
  if (s.temp >= 18.0 && s.temp <= 25.0) score++; // Changed for up-country
  
  int pct = (score * 100) / total;
  String status;
  
  if (pct >= 80) status = "Excellent";
  else if (pct >= 60) status = "Good";
  else if (pct >= 40) status = "Fair";
  else status = "Poor";
  
  String recommendations = "";
  
  // pH management (1 acre = 0.4047 hectares)
  if (s.ph < 4.5) recommendations += "Apply 400-1000 kg Dolomite per acre. ";
  else if (s.ph > 5.5) recommendations += "Add sulfur to lower pH. ";
  
  // Nitrogen fertilizer calculation for 1 acre (VP/UM 910 mixture)
  float nitrogenDeficiency = 0;
  if (s.n < 20.0) {
    nitrogenDeficiency = (20.0 - s.n) * 2.0; // Scale factor for acre
    recommendations += "Apply " + String(nitrogenDeficiency, 0) + " kg N/acre (Use VP/UM 910). ";
  }
  
  // Phosphorus fertilizer calculation
  if (s.p < 10.0) {
    float pDeficiency = (10.0 - s.p) * 3.0; // Scale factor
    recommendations += "Apply " + String(pDeficiency, 0) + " kg P2O5/acre. ";
  }
  
  // Potassium fertilizer calculation
  if (s.k < 20.0) {
    float kDeficiency = (20.0 - s.k) * 4.0; // Scale factor
    recommendations += "Apply " + String(kDeficiency, 0) + " kg K2O/acre. ";
  }
  
  // Moisture management
  if (s.hum < 40.0) recommendations += "Irrigation needed (maintain 80-85% field capacity). ";
  else if (s.hum > 70.0) recommendations += "Improve drainage. ";
  
  // Temperature management
  if (s.temp < 18.0) recommendations += "Soil temp low for optimal growth. ";
  else if (s.temp > 25.0) recommendations += "Soil temp high, consider shade management. ";
  
  // Zinc recommendation (standard for up-country)
  recommendations += "Apply 2-4 kg Zinc Sulphate per acre as foliar spray. ";
  
  // Standard application guidelines
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

// ========== SMS COMPOSITION (UPDATED) ==========
String composeSMS(const Sample &avg, const String &mlPrediction, const TriResult &tri) {
  String sms = "";
  sms += "Tea Soil Report - Area ";
  sms += String(currentArea);
  sms += " (1 Acre)\n";
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

// ========== YOUR SENSOR CODE (UNCHANGED) ==========

// Read sensor with CORRECT mapping
Sample readSensorData() {
  Sample sensorData = {0, 0, 0, 0, 0, 0, 0, false, "unknown"};
  
  byte cmd[8] = {0x01, 0x03, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00};
  uint16_t crc = modbusCRC(cmd, 6);
  cmd[6] = crc & 0xFF;
  cmd[7] = crc >> 8;
  
  // Clear buffer
  while(RS485.available()) RS485.read();
  
  // Send command
  digitalWrite(RE_DE, HIGH);
  delay(10);
  RS485.write(cmd, 8);
  RS485.flush();
  digitalWrite(RE_DE, LOW);
  
  delay(300);
  
  // Read response
  byte resp[32];
  int bytesRead = RS485.readBytes(resp, 32);
  
  if(bytesRead < 29) {
    return sensorData;
  }
  
  // CORRECT MAPPING:
  sensorData.hum = ((resp[3] << 8) | resp[4]) / 10.0;
  sensorData.temp = ((resp[5] << 8) | resp[6]) / 10.0;
  sensorData.ec = ((resp[7] << 8) | resp[8]);
  sensorData.ph = ((resp[9] << 8) | resp[10]) / 10.0;
  sensorData.n = ((resp[13] << 8) | resp[14]);
  sensorData.p = ((resp[17] << 8) | resp[18]);
  sensorData.k = ((resp[19] << 8) | resp[20]);
  
  // FIXED: Better soil detection based on actual parameters
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
    playBeepPattern(5); // Error pattern
    return false;
  }
  
  Serial.println("SD Mounted!");
  playBeepPattern(3); // Success pattern
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
    
    // Use pattern 1 for data saved beep
    playBeepPattern(1);
  } else {
    Serial.println("Error opening file!");
    playBeepPattern(5); // Error pattern
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
  
  // Configure SIM800 for SMS
  sim800.println("AT+CMGF=1");
  delay(1000);
  
  // Set recipient number
  sim800.print("AT+CMGS=\"");
  sim800.print(FARMER_PHONE);
  sim800.println("\"");
  delay(1000);
  
  // Send message
  sim800.print(message);
  delay(1000);
  
  // Send Ctrl+Z to end message
  sim800.write(26);
  delay(5000);
  
  // Check for success
  String response = "";
  while (sim800.available()) {
    response += sim800.readString();
  }
  
  if (response.indexOf("OK") != -1 || response.indexOf("+CMGS") != -1) {
    Serial.println("SMS sent successfully!");
    // Success beep pattern
    playBeepPattern(3);
  } else {
    Serial.println("SMS sending failed!");
    playBeepPattern(5); // Error pattern
  }
}

// Process area data and send SMS WITH ML & TRI
void processAreaData() {
  if (readingCount >= REQUIRED_READINGS) {
    Sample avgData = calculateAverage();
    
    if (avgData.isValid) {
      // Run ML prediction
      String mlPrediction = predictSoilHealthML(avgData);
      
      // Run TRI analysis
      TriResult triResult = checkTRI(avgData);
      
      // Create SMS message with ML and TRI
      String smsMessage = composeSMS(avgData, mlPrediction, triResult);
      
      Serial.println("\nSMS MESSAGE:");
      Serial.println(smsMessage);
      Serial.println("================================");
      
      // Send SMS
      sendSMS(smsMessage);
      
    }
  } else {
    Serial.println("Not enough readings to send SMS!");
    playBeepPattern(5); // Error pattern
  }
}

// ENHANCED LOOP with timing control
void enhancedLoop() {
  checkButton();
  updateBuzzer();  // Update buzzer state
  
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
      
      // Check sensor state and handle accordingly
      if (sensorData.sensorState == "soil" && sensorData.hum > 5.0 && sensorData.ec > 10) {
        // Check if 30 seconds have passed since last soil reading
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
          lastSoilReadingTime = currentTime; // Update timing
          
          Serial.print("Area: ");
          Serial.print(currentArea);
          Serial.print(" | Readings: ");
          Serial.print(readingCount);
          Serial.print("/");
          Serial.println(REQUIRED_READINGS);
          
          if (readingCount >= REQUIRED_READINGS) {
            Serial.println("\n20 READINGS COMPLETE!");
            Serial.println("Press button to send SMS");
            
            // Use pattern 2 for collection complete
            playBeepPattern(2);
          }
        } else {
          // Not enough time has passed since last soil reading
          unsigned long remainingTime = SOIL_READING_INTERVAL - (currentTime - lastSoilReadingTime);
          Serial.print("Please wait ");
          Serial.print(remainingTime / 1000.0);
          Serial.println(" seconds for next soil reading");
          // NO BEEP for waiting
        }
      } 
      else if (sensorData.sensorState == "air" || sensorData.sensorState == "water") {
        // Air/Water state - warn user but don't delay
        unsigned long currentTime = millis();
        
        // Only show warning every 5 seconds to avoid spam
        if (currentTime - lastAirWaterWarningTime >= AIR_WATER_WARNING_INTERVAL) {
          Serial.print("SENSOR IN ");
          Serial.print(toUpperCaseString(sensorData.sensorState));
          Serial.println(" - Not saving data");
          Serial.println("Please insert sensor into soil");
          lastAirWaterWarningTime = currentTime;
        }
        
        // No delay for air/water readings
        delay(1000); // Small delay to prevent flooding
        return;
      } 
      else {
        Serial.println("Readings questionable - check sensor");
        // NO BEEP for questionable readings
      }
    }
    
    Serial.println("================================");
    Serial.println();
    
    // If we just took a soil reading, wait before next attempt
    if (sensorData.isValid && sensorData.sensorState == "soil" && sensorData.hum > 5.0 && sensorData.ec > 10) {
      // Calculate remaining wait time
      unsigned long currentTime = millis();
      unsigned long timeSinceLastReading = currentTime - lastSoilReadingTime;
      
      if (timeSinceLastReading < SOIL_READING_INTERVAL) {
        unsigned long waitTime = SOIL_READING_INTERVAL - timeSinceLastReading;
        Serial.print("Next soil reading in ");
        Serial.print(waitTime / 1000.0);
        Serial.println(" seconds...");
        
        // Check for button presses during wait
        unsigned long waitStart = millis();
        while (millis() - waitStart < waitTime) {
          checkButton();
          updateBuzzer();  // Update buzzer during wait
          delay(100);
        }
      }
    } else {
      // For air/water or invalid readings, shorter delay
      delay(2000);
    }
  } else {
    // We have enough readings, just check button
    checkButton();
    updateBuzzer();  // Update buzzer state
    delay(100);
  }
}

void checkButton() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!buttonPressed && (millis() - lastButtonPress) > DEBOUNCE_DELAY) {
      buttonPressed = true;
      lastButtonPress = millis();
      
      Serial.println("\nButton pressed!");
      
      // Process and send data
      processAreaData();
      
      // Reset for next area
      currentArea++;
      readingCount = 0;
      tempSum = humSum = ecSum = phSum = nSum = pSum = kSum = 0;
      lastSoilReadingTime = 0; // Reset timing for new area
      lastAirWaterWarningTime = 0; // Reset warning timer
      
      Serial.print("Moving to Area ");
      Serial.println(currentArea);
      
      // Use pattern 4 for area change
      playBeepPattern(4);
    }
  } else {
    buttonPressed = false;
  }
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
  Serial.println("SOIL MONITORING WITH ML & RECOMMENDATIONS");
  Serial.println("================================");
  Serial.println();
  
  pinMode(RE_DE, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  digitalWrite(RE_DE, LOW);
  digitalWrite(BUZZER_PIN, HIGH); // Ensure active buzzer is OFF initially
  
  RS485.begin(SENSOR_BAUD, SERIAL_8N1, RXD2, TXD2);
  Serial.print("RS485 at ");
  Serial.print(SENSOR_BAUD);
  Serial.println(" baud");
  
  sim800.begin(9600, SERIAL_8N1, SIM800_RX_PIN, SIM800_TX_PIN);
  delay(3000);
  Serial.println("SIM800L READY");
  
  sdCardInitialized = initSDCard();
  
  // Startup beep pattern
  playBeepPattern(3);
  delay(200);
  playBeepPattern(3);
  
  manualSoilCheck();
  
  Serial.println("System Ready!");
  Serial.println("FEATURES:");
  Serial.println("  - 30 sec delay between soil readings");
  Serial.println("  - 0.5 sec beep after saving data (Pattern 1)");
  Serial.println("  - Warnings for air/water detection (NO BEEP)");
  Serial.println("  - Special beep when 20 readings complete (Pattern 2)");
  Serial.println("  - Success beep when SMS sent (Pattern 3)");
  Serial.println("  - 3 beeps for area change (Pattern 4)");
  Serial.println("  - Error beep for failures (Pattern 5)");
  Serial.println("  - Random Forest ML Prediction");
  Serial.println("  - TRI Analysis with Recommendations");
  Serial.println("Take 20 readings, then press button");
  Serial.println("================================");
  Serial.println();
}

void loop() {
  enhancedLoop();
  updateBuzzer();  // Always update buzzer state
}