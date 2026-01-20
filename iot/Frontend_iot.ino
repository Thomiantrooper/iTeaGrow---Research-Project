#include "BluetoothSerial.h"
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

// ===== OLED Display =====
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SH1106G display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ===== Hardware Pins =====
#define PIN_DHT 4
#define DHTTYPE DHT22
DHT dht(PIN_DHT, DHTTYPE);

#define PIN_PIR 27
#define PIN_MQ_ADC 34
#define PIN_STATUS_LED 25

// ===== Bluetooth =====
BluetoothSerial SerialBT;

// ===== Timing =====
unsigned long lastUpdate = 0;
const unsigned long UPDATE_INTERVAL = 2000;
unsigned long lastConnectionCheck = 0;
const unsigned long CONNECTION_CHECK_INTERVAL = 2000;

// ===== LED Blinking Pattern =====
unsigned long lastLEDBlink = 0;
const unsigned long LED_BLINK_ON = 200;
const unsigned long LED_BLINK_OFF = 1000;
const unsigned long LED_BLINK_CYCLE = 2000;
int ledBlinkState = 0;

// ===== State Variables =====
enum ConnectionState { DISCONNECTED, CONNECTED_USB, CONNECTED_BT };
ConnectionState connectionState = DISCONNECTED;
bool btActive = false;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Initialize OLED
  Wire.begin(21, 22);
  if(!display.begin(0x3C, true)) {
    Serial.println("OLED initialization failed");
    while(1);
  }
  
  // Show startup animation
  startupAnimation();
  
  Serial.println("\n========================================");
  Serial.println("       iTeaGrow Environmental Monitor");
  Serial.println("========================================");
  
  // Initialize hardware
  pinMode(PIN_PIR, INPUT);
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);
  
  dht.begin();
  delay(2000);
  
  // Initialize Bluetooth
  if(SerialBT.begin("iTeaGrow")) {
    Serial.println("Bluetooth: Ready (iTeaGrow)");
  } else {
    Serial.println("Bluetooth: Initialization failed");
  }
  
  Serial.println("System: Ready");
  Serial.println("========================================\n");
}

void startupAnimation() {
  // Clear display
  display.clearDisplay();
  
  // Draw iTeaGrow with animation
  for(int i = 0; i < 3; i++) {
    display.setTextSize(2);
    display.setTextColor(SH110X_WHITE);
    display.setCursor(20, 20);  // Left aligned
    display.println("iTeaGrow");
    display.display();
    
    // Blink LED during startup
    digitalWrite(PIN_STATUS_LED, HIGH);
    delay(300);
    digitalWrite(PIN_STATUS_LED, LOW);
    delay(300);
  }
  
  delay(1000);
}

void updateDisplay(float temp, float hum, int air) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SH110X_WHITE);
  
  // Header - Left aligned
  display.setCursor(0, 0);
  display.print("iTeaGrow");
  
  // Connection status (top right)
  display.setCursor(90, 0);
  switch(connectionState) {
    case CONNECTED_BT:
      display.print("BT:ON");
      break;
    case CONNECTED_USB:
      display.print("USB");
      break;
    case DISCONNECTED:
      display.print("BT:OFF");
      break;
  }
  
  // Separator line
  display.drawLine(0, 10, 128, 10, SH110X_WHITE);
  
  // Temperature (Line 1)
  display.setCursor(0, 15);
  display.print("Temperature:");
  display.setCursor(85, 15);
  display.print(temp, 1);
  display.print("C");
  
  // Humidity (Line 2)
  display.setCursor(0, 25);
  display.print("Humidity:");
  display.setCursor(85, 25);
  display.print(hum, 1);
  display.print("%");
  
  // Air Quality (Line 3)
  display.setCursor(0, 35);
  display.print("Air Quality:");
  display.setCursor(85, 35);
  display.print(air);
  
  // Air quality rating (Line 4)
  display.setCursor(0, 45);
  display.print("Rating:");
  display.setCursor(50, 45);
  if(air < 200) display.print("Excellent");
  else if(air < 400) display.print("Good");
  else if(air < 600) display.print("Moderate");
  else if(air < 800) display.print("Poor");
  else display.print("Critical");
  
  // Connection Status (Line 5)
  display.setCursor(0, 55);
  display.print("Status:");
  display.setCursor(50, 55);
  
  switch(connectionState) {
    case CONNECTED_BT:
      display.print("BT CONNECTED");
      break;
    case CONNECTED_USB:
      display.print("USB CONNECTED");
      break;
    case DISCONNECTED:
      display.print("AUTO SEARCH");
      break;
  }
  
  display.display();
}

void updateConnectionStatus() {
  // Check if Bluetooth has client
  btActive = SerialBT.hasClient();
  
  // Check USB activity
  bool usbActive = false;
  static unsigned long lastSerialActivity = 0;
  
  if (Serial.available()) {
    lastSerialActivity = millis();
    usbActive = true;
  }
  
  // Determine connection state
  ConnectionState newState;
  
  if (btActive && usbActive) {
    newState = CONNECTED_BT;
  } else if (usbActive && (millis() - lastSerialActivity < 5000)) {
    newState = CONNECTED_USB;
  } else if (btActive) {
    newState = CONNECTED_BT;
  } else {
    newState = DISCONNECTED;
  }
  
  // Update if state changed
  if (newState != connectionState) {
    connectionState = newState;
    
    switch(connectionState) {
      case CONNECTED_USB:
        Serial.println("Connected: USB Cable");
        break;
      case CONNECTED_BT:
        Serial.println("Connected: Bluetooth");
        SerialBT.println("iTeaGrow: Connected");
        break;
      case DISCONNECTED:
        Serial.println("Disconnected: No active connection");
        break;
    }
  }
}

void controlConnectionLED() {
  unsigned long currentMillis = millis();
  
  switch(connectionState) {
    case DISCONNECTED:
      digitalWrite(PIN_STATUS_LED, LOW);
      ledBlinkState = 0;
      break;
      
    case CONNECTED_USB:
    case CONNECTED_BT:
      if (ledBlinkState == 0) {
        if (currentMillis - lastLEDBlink > LED_BLINK_CYCLE) {
          ledBlinkState = 1;
          lastLEDBlink = currentMillis;
          digitalWrite(PIN_STATUS_LED, HIGH);
        }
      } 
      else if (ledBlinkState == 1) {
        if (currentMillis - lastLEDBlink > LED_BLINK_ON) {
          ledBlinkState = 2;
          digitalWrite(PIN_STATUS_LED, LOW);
          lastLEDBlink = currentMillis;
        }
      }
      else if (ledBlinkState == 2) {
        if (currentMillis - lastLEDBlink > LED_BLINK_OFF) {
          ledBlinkState = 0;
        }
      }
      break;
  }
}

void sendSensorData(float temp, float hum, int air, int motion) {
  char data[64];
  snprintf(data, sizeof(data), "T:%.1f,H:%.1f,A:%d,M:%d", temp, hum, air, motion);
  
  Serial.println(data);
  
  if (btActive) {
    SerialBT.println(data);
  }
}

void handleCommands() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    
    if (cmd == "status") {
      Serial.print("Connection: ");
      switch(connectionState) {
        case CONNECTED_USB: Serial.println("USB Cable"); break;
        case CONNECTED_BT: Serial.println("Bluetooth"); break;
        case DISCONNECTED: Serial.println("Searching"); break;
      }
    }
  }
  
  if (SerialBT.available()) {
    String cmd = SerialBT.readStringUntil('\n');
    cmd.trim();
    
    if (cmd == "status") {
      char statusMsg[100];
      snprintf(statusMsg, sizeof(statusMsg), 
               "iTeaGrow: Active | Connection: %s", 
               connectionState == CONNECTED_BT ? "Bluetooth" : 
               connectionState == CONNECTED_USB ? "USB Cable" : "Searching");
      SerialBT.println(statusMsg);
    }
    else if (cmd == "data") {
      float temp = dht.readTemperature();
      float hum = dht.readHumidity();
      int motion = digitalRead(PIN_PIR);
      int air = analogRead(PIN_MQ_ADC);
      
      char immediate[64];
      snprintf(immediate, sizeof(immediate), 
               "NOW: T:%.1fC, H:%.1f%%, A:%d, M:%d", 
               temp, hum, air, motion);
      SerialBT.println(immediate);
    }
  }
}

void loop() {
  if (millis() - lastConnectionCheck > CONNECTION_CHECK_INTERVAL) {
    updateConnectionStatus();
    lastConnectionCheck = millis();
  }
  
  controlConnectionLED();
  handleCommands();
  
  if (millis() - lastUpdate > UPDATE_INTERVAL) {
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    int motion = digitalRead(PIN_PIR);
    int air = analogRead(PIN_MQ_ADC);
    
    if (isnan(temp) || isnan(hum)) {
      temp = 0.0;
      hum = 0.0;
    }
    
    updateDisplay(temp, hum, air);
    sendSensorData(temp, hum, air, motion);
    
    lastUpdate = millis();
  }
  
  delay(100);
}