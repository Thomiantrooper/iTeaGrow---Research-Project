"""
iTeaGrow IoT Bridge Server
==========================
This script bridges the ESP32 serial data to the Flutter app via WebSocket.

How it works:
1. Connects to ESP32 via USB/Bluetooth Serial (COM port)
2. Starts a WebSocket server on localhost:8765
3. Flutter app connects to ws://localhost:8765 (or your PC's IP for mobile)
4. Real-time sensor data is streamed to the Flutter app

Usage:
    python iot_bridge_server.py

For mobile app testing, use your PC's IP address instead of localhost.
"""

import asyncio
import json
import serial
import serial.tools.list_ports
import time
from datetime import datetime
import websockets
import threading
from queue import Queue

# Configuration
WEBSOCKET_HOST = "0.0.0.0"  # Listen on all interfaces
WEBSOCKET_PORT = 8765
SERIAL_BAUDRATE = 115200

# Global state
sensor_data_queue = Queue()
connected_clients = set()
current_sensor_data = {
    "temperature": 0.0,
    "humidity": 0.0,
    "airQuality": 0,
    "motionDetected": False,
    "timestamp": "",
    "connectionType": "Disconnected",
    "port": ""
}
serial_connected = False


def get_available_ports():
    """Get all available COM ports"""
    ports = list(serial.tools.list_ports.comports())
    port_list = []

    print("\n" + "=" * 60)
    print("AVAILABLE PORTS")
    print("=" * 60)

    if not ports:
        print("No ports found!")
        return port_list

    for i, port_info in enumerate(ports, 1):
        port_name = port_info.device
        description = port_info.description

        desc_lower = description.lower()
        if "bluetooth" in desc_lower or "bt" in desc_lower:
            conn_type = "Bluetooth"
        elif "serial" in desc_lower or "usb" in desc_lower or "cp210" in desc_lower:
            conn_type = "USB"
        else:
            conn_type = "Unknown"

        print(f"  [{i}] {port_name:8s} | {conn_type:10s} | {description}")
        port_list.append({
            'number': i,
            'name': port_name,
            'description': description,
            'type': conn_type
        })

    print("=" * 60)
    return port_list


def parse_sensor_data(line):
    """Parse sensor data from ESP32 format: T:21.8,H:81.4,A:663,M:1"""
    global current_sensor_data

    line = line.strip()
    if "T:" in line and "H:" in line and "A:" in line and "M:" in line:
        try:
            temp = float(line.split('T:')[1].split(',')[0])
            hum = float(line.split('H:')[1].split(',')[0])
            air = int(line.split('A:')[1].split(',')[0])
            motion = int(line.split('M:')[1].strip())

            current_sensor_data.update({
                "temperature": temp,
                "humidity": hum,
                "airQuality": air,
                "motionDetected": motion == 1,
                "timestamp": datetime.now().isoformat(),
            })

            return True
        except Exception as e:
            print(f"Parse error: {e}")
    return False


def get_air_quality_rating(air_value):
    """Get air quality rating string"""
    if air_value < 200:
        return "Excellent"
    elif air_value < 400:
        return "Good"
    elif air_value < 600:
        return "Moderate"
    elif air_value < 800:
        return "Poor"
    else:
        return "Critical"


def serial_reader_thread(port, connection_type):
    """Thread to read serial data from ESP32"""
    global serial_connected, current_sensor_data

    try:
        ser = serial.Serial(
            port=port,
            baudrate=SERIAL_BAUDRATE,
            timeout=2,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )

        print(f"\nConnected to {port} ({connection_type})")
        time.sleep(2)  # Wait for ESP32 to initialize
        ser.reset_input_buffer()

        current_sensor_data["connectionType"] = connection_type
        current_sensor_data["port"] = port
        serial_connected = True

        while serial_connected:
            if ser.in_waiting:
                try:
                    line = ser.readline().decode('utf-8', errors='ignore').strip()
                    if line and parse_sensor_data(line):
                        # Put data in queue for WebSocket broadcast
                        sensor_data_queue.put(current_sensor_data.copy())

                        # Print to console
                        air_rating = get_air_quality_rating(current_sensor_data["airQuality"])
                        motion_str = "MOTION" if current_sensor_data["motionDetected"] else "STILL"
                        print(f"[{datetime.now().strftime('%H:%M:%S')}] "
                              f"T:{current_sensor_data['temperature']:.1f}°C | "
                              f"H:{current_sensor_data['humidity']:.1f}% | "
                              f"Air:{current_sensor_data['airQuality']} ({air_rating}) | "
                              f"{motion_str}")
                except Exception as e:
                    print(f"Read error: {e}")

            time.sleep(0.1)

        ser.close()
        print("Serial connection closed")

    except serial.SerialException as e:
        print(f"Serial error: {e}")
        serial_connected = False
    except Exception as e:
        print(f"Error: {e}")
        serial_connected = False


async def websocket_handler(websocket, path=None):
    """Handle WebSocket connections from Flutter app"""
    global connected_clients

    client_address = websocket.remote_address
    print(f"\n[WS] Client connected: {client_address}")
    connected_clients.add(websocket)

    try:
        # Send current data immediately on connect
        await websocket.send(json.dumps({
            "type": "sensor_data",
            "data": current_sensor_data,
            "connected": serial_connected
        }))

        # Handle incoming messages from Flutter
        async for message in websocket:
            try:
                data = json.loads(message)
                command = data.get("command", "")

                if command == "get_status":
                    await websocket.send(json.dumps({
                        "type": "status",
                        "connected": serial_connected,
                        "port": current_sensor_data.get("port", ""),
                        "connectionType": current_sensor_data.get("connectionType", "")
                    }))
                elif command == "get_data":
                    await websocket.send(json.dumps({
                        "type": "sensor_data",
                        "data": current_sensor_data,
                        "connected": serial_connected
                    }))

            except json.JSONDecodeError:
                pass

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        connected_clients.discard(websocket)
        print(f"[WS] Client disconnected: {client_address}")


async def broadcast_sensor_data():
    """Broadcast sensor data to all connected WebSocket clients"""
    while True:
        if not sensor_data_queue.empty() and connected_clients:
            data = sensor_data_queue.get()
            message = json.dumps({
                "type": "sensor_data",
                "data": data,
                "connected": serial_connected
            })

            # Broadcast to all connected clients
            disconnected = set()
            for client in connected_clients:
                try:
                    await client.send(message)
                except:
                    disconnected.add(client)

            # Remove disconnected clients
            connected_clients.difference_update(disconnected)

        await asyncio.sleep(0.1)


async def main():
    """Main entry point"""
    global serial_connected

    print("\n" + "=" * 60)
    print("    iTeaGrow IoT Bridge Server")
    print("=" * 60)
    print(f"WebSocket server will start on ws://0.0.0.0:{WEBSOCKET_PORT}")
    print("=" * 60)

    # Get available ports
    port_list = get_available_ports()

    if not port_list:
        print("\nNo ports found! Please connect ESP32 and restart.")
        print("Starting WebSocket server anyway (will show disconnected)...")
        selected_port = None
        connection_type = "Disconnected"
    else:
        print("\nSelect port (enter number, port name, or 'A' for auto):")
        choice = input("> ").strip()

        selected_port = None
        connection_type = "USB"

        if choice.upper() == 'A':
            # Auto-select first USB port
            usb_ports = [p for p in port_list if p['type'] == "USB"]
            if usb_ports:
                selected_port = usb_ports[0]['name']
                connection_type = usb_ports[0]['type']
            elif port_list:
                selected_port = port_list[0]['name']
                connection_type = port_list[0]['type']
        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(port_list):
                selected_port = port_list[idx]['name']
                connection_type = port_list[idx]['type']
        else:
            # Direct port name
            for p in port_list:
                if p['name'].upper() == choice.upper():
                    selected_port = p['name']
                    connection_type = p['type']
                    break

    # Start serial reader thread if port selected
    if selected_port:
        serial_thread = threading.Thread(
            target=serial_reader_thread,
            args=(selected_port, connection_type),
            daemon=True
        )
        serial_thread.start()
        print(f"\nSerial reader started on {selected_port}")

    # Start WebSocket server
    print(f"\nStarting WebSocket server on port {WEBSOCKET_PORT}...")
    print("\nFlutter app connection URLs:")
    print(f"  - Local:  ws://localhost:{WEBSOCKET_PORT}")
    print(f"  - Mobile: ws://<your-pc-ip>:{WEBSOCKET_PORT}")
    print("\nPress Ctrl+C to stop\n")
    print("-" * 60)

    # Create WebSocket server
    server = await websockets.serve(
        websocket_handler,
        WEBSOCKET_HOST,
        WEBSOCKET_PORT
    )

    # Start broadcast task
    broadcast_task = asyncio.create_task(broadcast_sensor_data())

    try:
        await asyncio.Future()  # Run forever
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        serial_connected = False
        broadcast_task.cancel()
        server.close()
        await server.wait_closed()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
