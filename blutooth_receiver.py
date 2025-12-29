import serial
import time
import csv
from datetime import datetime
import os
import sys
import serial.tools.list_ports

class iTeaGrowLogger:
    def __init__(self):
        self.csv_file = "iTeaGrow_Data.csv"
        self.connection_type = None
        self.port = None
        self.serial_conn = None
        self.data_count = 0
        self.initialize_csv()
        
    def initialize_csv(self):
        """Initialize CSV file with headers if not exists"""
        if not os.path.exists(self.csv_file):
            try:
                with open(self.csv_file, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    writer.writerow([
                        "Timestamp", "Temperature (C)", "Humidity (%)", 
                        "Air Quality", "Air Quality Rating", "Motion", 
                        "Connection Type", "Port"
                    ])
                print(f"CSV File created: {self.csv_file}")
            except PermissionError:
                print(f"ERROR: Cannot create {self.csv_file}")
                print("Please close Excel or any program using this file")
                sys.exit(1)
    
    def get_available_ports(self):
        """Get all available COM ports with clear information"""
        ports = list(serial.tools.list_ports.comports())
        
        print("\n" + "=" * 70)
        print("SCANNING FOR AVAILABLE PORTS")
        print("=" * 70)
        
        if not ports:
            print("NO PORTS FOUND!")
            print("Please check:")
            print("  1. Is ESP32 connected via USB?")
            print("  2. Is Bluetooth paired? (Check Bluetooth Settings)")
            print("  3. Are drivers installed?")
            return []
        
        print(f"Found {len(ports)} available port(s):")
        print("-" * 70)
        
        port_list = []
        for i, port_info in enumerate(ports, 1):
            port_name = port_info.device
            description = port_info.description
            
            # Determine connection type
            desc_lower = description.lower()
            if "bluetooth" in desc_lower or "bt" in desc_lower:
                conn_type = "Bluetooth"
                type_indicator = "[BT]"
            elif "serial" in desc_lower or "usb" in desc_lower or "cp210" in desc_lower:
                conn_type = "USB Cable"
                type_indicator = "[USB]"
            else:
                conn_type = "Unknown"
                type_indicator = "[?]"
            
            print(f"  [{i:2d}] {type_indicator} {port_name:6s} | {description}")
            
            port_list.append({
                'number': i,
                'name': port_name,
                'description': description,
                'type': conn_type,
                'indicator': type_indicator
            })
        
        print("=" * 70)
        return port_list
    
    def connect(self):
        """Establish connection with ESP32"""
        print("\n" + "=" * 70)
        print("               iTeaGrow Data Logger - Windows")
        print("=" * 70)
        
        # Get available ports
        port_list = self.get_available_ports()
        
        if not port_list:
            print("\nNo ports available. Please:")
            print("  1. Connect ESP32 via USB cable, OR")
            print("  2. Pair ESP32 via Bluetooth (Device name: 'iTeaGrow')")
            print("\nPress Enter to retry...")
            input()
            return False
        
        # Show connection options
        print("\n" + "=" * 70)
        print("CONNECTION OPTIONS:")
        print("=" * 70)
        print("OPTION 1: Enter NUMBER from the list above")
        print("         Example: Enter '1' for COM3, or '6' for COM9")
        print()
        print("OPTION 2: Enter PORT NAME directly")
        print("         Example: Enter 'COM9' or 'COM3'")
        print()
        print("OPTION 3: Enter 'A' for AUTO-DETECT (Recommended)")
        print("         Will try to find iTeaGrow automatically")
        print()
        print("OPTION 4: Enter 'R' to refresh port list")
        print()
        print("OPTION 5: Enter 'Q' to quit")
        print("=" * 70)
        
        while True:
            try:
                choice = input("\nEnter your choice: ").strip()
                
                # Option 5: Quit
                if choice.upper() == 'Q':
                    print("Exiting program.")
                    return False
                
                # Option 4: Refresh
                if choice.upper() == 'R':
                    print("\nRefreshing port list...")
                    return self.connect()
                
                # Option 3: Auto-detect
                if choice.upper() == 'A':
                    print("\nAUTO-DETECTING iTeaGrow...")
                    # Try to find USB ports first (most likely for iTeaGrow)
                    usb_ports = [p for p in port_list if p['type'] == "USB Cable"]
                    if usb_ports:
                        selected = usb_ports[0]
                        print(f"Selected USB port: {selected['name']} - {selected['description']}")
                        return self.establish_connection(selected['name'])
                    else:
                        print("No USB ports found. Trying first available port...")
                        return self.establish_connection(port_list[0]['name'])
                
                # Option 1: Check if it's a number
                if choice.isdigit():
                    port_num = int(choice)
                    if 1 <= port_num <= len(port_list):
                        selected_port = port_list[port_num - 1]
                        print(f"\nSelected: [{port_num}] {selected_port['name']}")
                        return self.establish_connection(selected_port['name'])
                    else:
                        print(f"Invalid number! Please choose between 1 and {len(port_list)}")
                        continue
                
                # Option 2: Check if it's a port name
                port_names = [p['name'].upper() for p in port_list]
                if choice.upper() in port_names:
                    print(f"\nSelected: {choice.upper()}")
                    return self.establish_connection(choice.upper())
                
                # Invalid input
                print(f"\nINVALID INPUT: '{choice}'")
                print("Valid options:")
                print(f"  - Enter a number 1-{len(port_list)}")
                print(f"  - Enter a port name (e.g., {', '.join([p['name'] for p in port_list[:3]])})")
                print("  - Enter 'A' for auto-detect")
                print("  - Enter 'R' to refresh")
                print("  - Enter 'Q' to quit")
                
            except KeyboardInterrupt:
                print("\n\nOperation cancelled by user.")
                return False
            except Exception as e:
                print(f"\nError: {e}")
                continue
    
    def establish_connection(self, port):
        """Establish serial connection"""
        print(f"\n" + "=" * 70)
        print(f"CONNECTING TO: {port}")
        print("=" * 70)
        
        try:
            print(f"1. Opening {port} at 115200 baud...")
            self.serial_conn = serial.Serial(
                port=port,
                baudrate=115200,
                timeout=2,
                write_timeout=2,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE
            )
            
            print("2. Waiting for ESP32 initialization...")
            time.sleep(3)
            self.serial_conn.reset_input_buffer()
            
            print("3. Testing connection...")
            self.serial_conn.write(b'\n')
            time.sleep(1)
            
            # Determine connection type
            ports_info = list(serial.tools.list_ports.comports())
            for p in ports_info:
                if p.device.upper() == port.upper():
                    desc = p.description
                    desc_lower = desc.lower()
                    if "bluetooth" in desc_lower or "bt" in desc_lower:
                        self.connection_type = "Bluetooth"
                    else:
                        self.connection_type = "USB Cable"
                    break
            
            self.port = port
            
            print(f"\n" + "=" * 70)
            print("CONNECTION ESTABLISHED SUCCESSFULLY")
            print("=" * 70)
            print(f"Connection Type: {self.connection_type}")
            print(f"Port: {self.port}")
            print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"Data File: {self.csv_file}")
            print("=" * 70)
            print("\nCOLLECTING SENSOR DATA...")
            print("Press CTRL+C to stop logging")
            print("-" * 70)
            
            return True
            
        except serial.SerialException as e:
            print(f"\nCONNECTION FAILED!")
            print("=" * 70)
            print(f"Error: {e}")
            print("\nTROUBLESHOOTING:")
            print("  1. Verify ESP32 is powered ON")
            print("  2. Verify correct port is selected")
            print("  3. Close Serial Monitor, Arduino IDE, or any other program using this port")
            print("  4. Try unplugging and re-plugging USB cable")
            print("  5. For Bluetooth: Re-pair the device if needed")
            print("=" * 70)
            return False
        except Exception as e:
            print(f"\nUnexpected error: {e}")
            return False
    
    def parse_sensor_data(self, line):
        """Parse sensor data from ESP32"""
        line = line.strip()
        
        # Format: T:35.6,H:65.8,A:306,M:1
        if "T:" in line and "H:" in line and "A:" in line and "M:" in line:
            try:
                temp = float(line.split('T:')[1].split(',')[0])
                hum = float(line.split('H:')[1].split(',')[0])
                air = int(line.split('A:')[1].split(',')[0])
                motion = int(line.split('M:')[1].strip())
                return temp, hum, air, motion, True
            except:
                return 0, 0, 0, 0, False
        
        return 0, 0, 0, 0, False
    
    def get_air_quality(self, air_value):
        """Determine air quality rating"""
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
    
    def save_data(self, temp, hum, air, motion):
        """Save data to CSV file"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        air_rating = self.get_air_quality(air)
        motion_text = "Detected" if motion == 1 else "None"
        
        try:
            with open(self.csv_file, 'a', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                writer.writerow([
                    timestamp, f"{temp:.1f}", f"{hum:.1f}", 
                    air, air_rating, motion_text,
                    self.connection_type, self.port
                ])
            
            print(f"Data saved to {self.csv_file}")
            
        except PermissionError:
            print(f"ERROR: Cannot save data - {self.csv_file} is open in another program!")
            print("Please close Excel or any other program using this file")
        except Exception as e:
            print(f"Save error: {e}")
    
    def monitor(self):
        """Main monitoring loop"""
        last_save = time.time()
        save_interval = 10
        last_data_time = time.time()
        warning_shown = False
        
        try:
            print("\nWaiting for sensor data...")
            print("(Data should appear every 2 seconds)")
            print("-" * 70)
            
            while True:
                if self.serial_conn.in_waiting:
                    try:
                        line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    except UnicodeDecodeError:
                        continue
                    
                    if not line:
                        continue
                    
                    # Parse sensor data
                    temp, hum, air, motion, success = self.parse_sensor_data(line)
                    
                    if success:
                        self.data_count += 1
                        last_data_time = time.time()
                        warning_shown = False
                        
                        # Display data
                        motion_str = "MOTION" if motion else "STILL "
                        print(f"[{datetime.now().strftime('%H:%M:%S')}] "
                              f"Temp: {temp:5.1f}C | "
                              f"Hum: {hum:5.1f}% | "
                              f"Air: {air:4d} | "
                              f"{motion_str}")
                        
                        # Save every 10 seconds
                        current_time = time.time()
                        if current_time - last_save >= save_interval:
                            self.save_data(temp, hum, air, motion)
                            last_save = current_time
                
                # Check for data timeout
                if time.time() - last_data_time > 10 and not warning_shown:
                    print("\nWARNING: No data received for 10 seconds!")
                    print("Check if ESP32 is still connected and powered")
                    warning_shown = True
                
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            print(f"\n\n" + "=" * 70)
            print("LOGGING SESSION ENDED")
            print("=" * 70)
            print(f"Total records: {self.data_count}")
            print(f"CSV file: {self.csv_file}")
            print(f"Connection: {self.connection_type} on {self.port}")
            print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print("=" * 70)
            
        except Exception as e:
            print(f"\nError: {e}")
            
        finally:
            if self.serial_conn:
                self.serial_conn.close()
                print("Connection closed")
    
    def run(self):
        """Main execution"""
        print("\n" + "=" * 70)
        print("           iTeaGrow Data Logger - Windows")
        print("=" * 70)
        
        while True:
            if self.connect():
                self.monitor()
            
            # Ask if user wants to reconnect
            print("\n" + "=" * 70)
            print("SESSION ENDED - NEXT STEPS")
            print("=" * 70)
            print("  1. Enter 'R' to restart and reconnect")
            print("  2. Enter 'Q' to quit the program")
            print("  3. Press Enter to reconnect to same device")
            print("=" * 70)
            
            choice = input("\nEnter your choice: ").strip().upper()
            
            if choice == 'Q':
                print("\nExiting program.")
                break
            elif choice == 'R':
                # Full restart
                self.data_count = 0
                self.serial_conn = None
                self.connection_type = None
                self.port = None
                continue
            else:
                # Try to reconnect to same port
                if self.port:
                    print(f"\nReconnecting to {self.port}...")
                    if self.establish_connection(self.port):
                        self.monitor()
                else:
                    print("No previous connection to reconnect to")

if __name__ == "__main__":
    try:
        logger = iTeaGrowLogger()
        logger.run()
    except KeyboardInterrupt:
        print("\n\nProgram terminated by user.")
    except Exception as e:
        print(f"\nFatal error: {e}")
        input("Press Enter to exit...")