# # # import openmeteo_requests
# # # import pandas as pd
# # # import os
# # # from retry_requests import retry

# # # # --- 1. SETTINGS & PATHS ---
# # # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project"
# # # DATA_DIR = os.path.join(PROJECT_ROOT, "dataset")

# # # files_to_update = [
# # #     "Master_Dataset_Full_RealForced.csv",
# # #     "Master_Reduced.csv",
# # #     "train_yield.csv",
# # #     "valid_yield.csv",
# # #     "test_yield.csv"
# # # ]

# # # # --- 2. FETCH TRUE TEMPERATURE DATA ---
# # # # Fixed the TypeError by using the standard 'retries' argument
# # # retry_strategy = retry(backoff_factor=0.2, retries=5)
# # # openmeteo = openmeteo_requests.Client(session=retry_strategy)

# # # params = {
# # #     "latitude": 6.83, # Central Tea Highlands (Sri Lanka)
# # #     "longitude": 80.64,
# # #     "start_date": "2022-02-19",
# # #     "end_date": "2025-11-16",
# # #     "daily": ["temperature_2m_max", "temperature_2m_min"],
# # #     "timezone": "auto"
# # # }

# # # print("Fetching historical weather data from Open-Meteo...")
# # # responses = openmeteo.weather_api("https://archive-api.open-meteo.com/v1/archive", params=params)
# # # response = responses[0]

# # # # Extract values
# # # daily = response.Daily()
# # # temp_max = daily.Variables(0).ValuesAsNumpy()
# # # temp_min = daily.Variables(1).ValuesAsNumpy()

# # # # Create lookup dataframe
# # # weather_dates = pd.date_range(start="2022-02-19", end="2025-11-16", freq="D")
# # # weather_df = pd.DataFrame({
# # #     'Date': weather_dates,
# # #     'Temperature_Daily_C': (temp_max + temp_min) / 2
# # # })
# # # weather_df['Date'] = weather_df['Date'].dt.strftime('%Y-%m-%d')

# # # # --- 3. LOOP AND UPDATE THE 5 FILES ---
# # # for file_name in files_to_update:
# # #     file_path = os.path.join(DATA_DIR, file_name)
    
# # #     if not os.path.exists(file_path):
# # #         print(f"Skipping {file_name}: File not found at {file_path}")
# # #         continue
    
# # #     print(f"Updating {file_name}...")
# # #     df = pd.read_csv(file_path)
    
# # #     # Standardize date to string for the merge
# # #     df['Date'] = pd.to_datetime(df['Date']).dt.strftime('%Y-%m-%d')
    
# # #     if 'Temperature_Daily_C' in df.columns:
# # #         df = df.drop(columns=['Temperature_Daily_C'])
    
# # #     # Merge and verify integrity
# # #     original_row_count = len(df)
# # #     df = df.merge(weather_df, on='Date', how='left')
    
# # #     # SKEPTICAL CHECK: Ensure no data was lost or duplicated
# # #     if len(df) != original_row_count:
# # #         print(f"⚠️ ERROR in {file_name}: Row count changed! (Original: {original_row_count}, New: {len(df)})")
    
# # #     missing_temps = df['Temperature_Daily_C'].isna().sum()
# # #     if missing_temps > 0:
# # #         print(f"⚠️ WARNING: {missing_temps} rows in {file_name} are missing temperature data!")
    
# # #     df.to_csv(file_path, index=False)
# # #     print(f"✅ {file_name} updated and verified.")

# # # print("\nFinal Result: All files are now synced with true historical temperature data.")



# # import openmeteo_requests
# # import pandas as pd
# # import os
# # import numpy as np
# # from retry_requests import retry

# # # --- 1. SETTINGS & PATHS ---
# # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project"
# # DATA_DIR = os.path.join(PROJECT_ROOT, "dataset")

# # files_to_update = [
# #     "Master_Dataset_Full_RealForced.csv",
# #     "Master_Reduced.csv",
# #     "train_yield.csv",
# #     "valid_yield.csv",
# #     "test_yield.csv"
# # ]

# # # --- 2. FETCH HUMIDITY DATA ---
# # retry_strategy = retry(backoff_factor=0.2, retries=5)
# # openmeteo = openmeteo_requests.Client(session=retry_strategy)

# # params = {
# #     "latitude": 6.83, # Central Highlands Sri Lanka
# #     "longitude": 80.64,
# #     "start_date": "2022-02-19",
# #     "end_date": "2025-11-16",
# #     "daily": ["relative_humidity_2m_mean"],
# #     "timezone": "auto"
# # }

# # print("Fetching Humidity data from Open-Meteo...")
# # responses = openmeteo.weather_api("https://archive-api.open-meteo.com/v1/archive", params=params)
# # response = responses[0]

# # # Process data
# # daily = response.Daily()
# # rh_mean = daily.Variables(0).ValuesAsNumpy()

# # # Create lookup dataframe
# # weather_dates = pd.date_range(start="2022-02-19", end="2025-11-16", freq="D")
# # humidity_df = pd.DataFrame({
# #     'Date': weather_dates.strftime('%Y-%m-%d'),
# #     'Humidity_Mean_Pct': rh_mean
# # })

# # # --- 3. LOOP AND UPDATE THE 5 FILES ---
# # for file_name in files_to_update:
# #     file_path = os.path.join(DATA_DIR, file_name)
    
# #     if not os.path.exists(file_path):
# #         print(f"Skipping {file_name}: Not found.")
# #         continue
    
# #     print(f"Adding Humidity to {file_name}...")
    
# #     try:
# #         df = pd.read_csv(file_path)
        
# #         # Standardize date format for merge
# #         df['Date'] = pd.to_datetime(df['Date']).dt.strftime('%Y-%m-%d')
        
# #         # Drop if column already exists to prevent duplication
# #         if 'Humidity_Mean_Pct' in df.columns:
# #             df = df.drop(columns=['Humidity_Mean_Pct'])
        
# #         # Merge
# #         original_rows = len(df)
# #         df = df.merge(humidity_df, on='Date', how='left')
        
# #         # Integrity Check
# #         if len(df) != original_rows:
# #             print(f"⚠️ Row count error in {file_name}!")
            
# #         df.to_csv(file_path, index=False)
# #         print(f"✅ {file_name} updated successfully.")
        
# #     except PermissionError:
# #         print(f"❌ ERROR: Close {file_name} in Excel before running!")

# # print("\nTask Complete: Humidity column added to all files.")




# import openmeteo_requests
# import pandas as pd
# import os
# import numpy as np
# from retry_requests import retry
# from datetime import datetime, timedelta

# # --- 1. SETTINGS & PATHS ---
# PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project"
# DATA_DIR = os.path.join(PROJECT_ROOT, "dataset")

# files_to_update = [
#     "Master_Dataset_Full_RealForced.csv",
#     "Master_Reduced.csv",
#     "train_yield.csv",
#     "valid_yield.csv",
#     "test_yield.csv"
# ]

# # --- 2. FETCH AND PROCESS HUMIDITY DATA ---
# retry_strategy = retry(backoff_factor=0.2, retries=5)
# openmeteo = openmeteo_requests.Client(session=retry_strategy)

# params = {
#     "latitude": 6.83,  # Central Highlands Sri Lanka
#     "longitude": 80.64,
#     "start_date": "2022-02-19",
#     "end_date": "2025-11-16",
#     "daily": ["relative_humidity_2m_mean"],
#     "timezone": "auto"
# }

# print("Fetching Humidity data from Open-Meteo...")
# responses = openmeteo.weather_api("https://archive-api.open-meteo.com/v1/archive", params=params)
# response = responses[0]

# # Process data
# daily = response.Daily()
# rh_mean = daily.Variables(0).ValuesAsNumpy()

# # Create date range
# weather_dates = pd.date_range(start="2022-02-19", end="2025-11-16", freq="D")

# # --- 3. CREATE ADVANCED HUMIDITY FEATURES ---
# print("Creating research-grade humidity features...")

# # Calculate rolling statistics (critical for plant stress memory)
# humidity_series = pd.Series(rh_mean, index=weather_dates)

# # 1. Optimal Humidity Zone Indicator (U-shaped relationship)
# def classify_humidity_stress(rh):
#     """Classify humidity based on optimal ranges for tea"""
#     if rh < 60:
#         return "low_stress"  # Leathery leaves
#     elif 60 <= rh <= 70:
#         return "mild_stress"
#     elif 70 < rh < 90:
#         return "optimal"
#     elif 90 <= rh <= 95:
#         return "high_humidity"
#     else:
#         return "extreme_humidity"

# # 2. Humidity Deficit (distance from optimal range)
# def humidity_deficit(rh):
#     """Calculate how far from optimal 80% humidity"""
#     optimal = 80
#     return abs(rh - optimal)

# # 3. Consecutive stress days
# def consecutive_stress_days(rh_series, threshold_low=60, threshold_high=95):
#     """Count consecutive days with suboptimal humidity"""
#     stress_mask = (rh_series < threshold_low) | (rh_series > threshold_high)
#     consecutive = []
#     count = 0
#     for val in stress_mask:
#         if val:
#             count += 1
#         else:
#             count = 0
#         consecutive.append(count)
#     return consecutive

# # Create advanced features dataframe
# humidity_df = pd.DataFrame({
#     'Date': weather_dates.strftime('%Y-%m-%d'),
#     'Humidity_Mean_Pct': rh_mean,
#     'Humidity_Stress_Class': [classify_humidity_stress(x) for x in rh_mean],
#     'Humidity_Deficit': humidity_deficit(rh_mean),
#     'Consecutive_Stress_Days': consecutive_stress_days(pd.Series(rh_mean)),
#     'Humidity_3Day_Avg': humidity_series.rolling(window=3, min_periods=1).mean().values,
#     'Humidity_7Day_Avg': humidity_series.rolling(window=7, min_periods=1).mean().values,
#     'Humidity_Std_7Day': humidity_series.rolling(window=7, min_periods=1).std().fillna(0).values,
#     'Is_Low_Humidity': (rh_mean < 65).astype(int),  # Binary indicator for leathery leaves
#     'Is_High_Humidity': (rh_mean > 92).astype(int)  # Binary indicator for fog/mist
# })

# # --- 4. LOOP AND UPDATE THE 5 FILES ---
# print("\nUpdating datasets with humidity features...")

# for file_name in files_to_update:
#     file_path = os.path.join(DATA_DIR, file_name)
    
#     if not os.path.exists(file_path):
#         print(f"Skipping {file_name}: Not found.")
#         continue
    
#     print(f"\nProcessing {file_name}...")
    
#     try:
#         df = pd.read_csv(file_path)
#         original_rows = len(df)
        
#         # Standardize date format for merge
#         df['Date'] = pd.to_datetime(df['Date']).dt.strftime('%Y-%m-%d')
        
#         # Drop existing humidity columns if present
#         humidity_cols = [col for col in df.columns if 'humidity' in col.lower() or 'Humidity' in col]
#         if humidity_cols:
#             df = df.drop(columns=humidity_cols)
#             print(f"  Removed existing humidity columns: {humidity_cols}")
        
#         # Merge with all humidity features
#         df = df.merge(humidity_df, on='Date', how='left')
        
#         # Integrity Check
#         if len(df) != original_rows:
#             print(f"  ⚠️ Row count changed from {original_rows} to {len(df)}!")
#         else:
#             print(f"  ✅ Row count preserved: {original_rows}")
        
#         # Check for missing values
#         missing_humidity = df['Humidity_Mean_Pct'].isnull().sum()
#         if missing_humidity > 0:
#             print(f"  ⚠️ Missing humidity values: {missing_humidity}")
        
#         df.to_csv(file_path, index=False)
#         print(f"  ✅ {file_name} updated with {len(humidity_df.columns)} humidity features.")
        
#     except PermissionError:
#         print(f"  ❌ ERROR: Close {file_name} in Excel before running!")
#     except Exception as e:
#         print(f"  ❌ ERROR processing {file_name}: {str(e)}")

# # --- 5. SUMMARY STATISTICS ---
# print("\n" + "="*50)
# print("HUMIDITY DATA SUMMARY")
# print("="*50)

# print(f"\nDate Range: {weather_dates[0].date()} to {weather_dates[-1].date()}")
# print(f"Total Days: {len(humidity_df)}")
# print(f"Mean Humidity: {humidity_df['Humidity_Mean_Pct'].mean():.1f}%")
# print(f"Humidity Range: {humidity_df['Humidity_Mean_Pct'].min():.1f}% to {humidity_df['Humidity_Mean_Pct'].max():.1f}%")

# # Stress day analysis
# low_days = humidity_df['Is_Low_Humidity'].sum()
# high_days = humidity_df['Is_High_Humidity'].sum()
# optimal_days = ((humidity_df['Humidity_Mean_Pct'] >= 70) & (humidity_df['Humidity_Mean_Pct'] <= 90)).sum()

# print(f"\nStress Analysis:")
# print(f"  Optimal days (70-90%): {optimal_days} ({optimal_days/len(humidity_df)*100:.1f}%)")
# print(f"  Low humidity days (<65%): {low_days} ({low_days/len(humidity_df)*100:.1f}%)")
# print(f"  High humidity days (>92%): {high_days} ({high_days/len(humidity_df)*100:.1f}%)")

# print("\n✅ Task Complete: Advanced humidity features added to all files.")



# verification_humidity.py
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load and verify
df = pd.read_csv(r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\dataset\train_yield.csv")

print("VERIFICATION REPORT")
print("="*50)
print(f"Dataset shape: {df.shape}")
print(f"\nNew columns added:")
humidity_cols = [col for col in df.columns if 'Humidity' in col or 'humidity' in col.lower()]
for col in humidity_cols:
    print(f"  - {col}: {df[col].dtype}")

print(f"\nBasic Statistics:")
print(df[humidity_cols].describe().round(2))

print(f"\nMissing values:")
print(df[humidity_cols].isnull().sum())

# Quick visualization
plt.figure(figsize=(12, 6))
plt.plot(pd.to_datetime(df['Date']), df['Humidity_Mean_Pct'], alpha=0.7, label='Daily Mean')
plt.axhline(y=80, color='g', linestyle='--', label='Optimal (80%)')
plt.axhline(y=65, color='r', linestyle=':', label='Low Threshold')
plt.axhline(y=92, color='orange', linestyle=':', label='High Threshold')
plt.fill_between(pd.to_datetime(df['Date']), 70, 90, alpha=0.2, color='green', label='Optimal Zone')
plt.xlabel('Date')
plt.ylabel('Relative Humidity (%)')
plt.title('Humidity Time Series with Optimal Zones')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# Stress class distribution
if 'Humidity_Stress_Class' in df.columns:
    stress_counts = df['Humidity_Stress_Class'].value_counts()
    print("\nStress Class Distribution:")
    print(stress_counts)
    
    plt.figure(figsize=(8, 6))
    stress_counts.plot(kind='bar', color=['green', 'lightgreen', 'yellow', 'orange', 'red'])
    plt.title('Humidity Stress Class Distribution')
    plt.xlabel('Stress Class')
    plt.ylabel('Count')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()