"""
Quick test: publishes fake sensor data to HiveMQ so you can see
it appear in the Flutter Live tab without a real ESP32.

Usage:
    python test_mqtt_publish.py            # publishes once
    python test_mqtt_publish.py --loop     # publishes every 5 seconds
"""
import json, sys, time, random
import paho.mqtt.client as mqtt

BROKER   = "c0674ce6e5414364a46009de82230e02.s1.eu.hivemq.cloud"
PORT     = 8883
USERNAME = "Kajanthan"
PASSWORD = "Kajanthan@2002"

DEVICES = ["esp32-001", "esp32-002"]   # simulate 2 devices

published = 0

def on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0:
        print(f"Connected to HiveMQ broker")
        _publish(client)
    else:
        print(f"Connection failed: {reason_code}")

def _publish(client):
    global published
    for device_id in DEVICES:
        payload = {
            "device_id":    device_id,
            "temperature":  round(random.uniform(22.0, 32.0), 1),
            "humidity":     round(random.uniform(60.0, 90.0), 1),
            "soil_moisture": round(random.uniform(40.0, 80.0), 1),
            "air_quality":  round(random.uniform(380.0, 600.0), 0),
            "light_level":  round(random.uniform(5000, 12000), 0),
        }
        topic = f"iteagrow/sensors/{device_id}"
        client.publish(topic, json.dumps(payload), qos=1)
        print(f"  Published → {topic}")
        print(f"    {json.dumps(payload)}")
        published += 1

client = mqtt.Client(
    callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
    client_id="iteagrow-test-publisher", clean_session=True
)
client.username_pw_set(USERNAME, PASSWORD)
client.tls_set()
client.on_connect = on_connect

loop_mode = "--loop" in sys.argv

client.connect_async(BROKER, PORT)
client.loop_start()
time.sleep(3)   # wait for connect + first publish

if loop_mode:
    print("\nLoop mode — publishing every 5 seconds. Press Ctrl-C to stop.\n")
    try:
        while True:
            time.sleep(5)
            _publish(client)
    except KeyboardInterrupt:
        print(f"\nStopped. Published {published} messages total.")
else:
    print(f"\nDone. Published {published} messages.")

client.loop_stop()
client.disconnect()
