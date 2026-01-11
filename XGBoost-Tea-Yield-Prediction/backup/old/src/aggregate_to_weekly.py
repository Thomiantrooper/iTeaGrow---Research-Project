import pandas as pd
import os
from pathlib import Path

# ==========================================
# CONFIG
# ==========================================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
DATA_DIR = os.path.join(PROJECT_ROOT, "dataset")
WEEKLY_DIR = os.path.join(DATA_DIR, "weekly_v1")
Path(WEEKLY_DIR).mkdir(parents=True, exist_ok=True)

files = ["train_yield.csv", "valid_yield.csv", "test_yield.csv"]

def aggregate_weekly(df):
    # Ensure date is datetime
    df['Date'] = pd.to_datetime(df['Date'])
    
    # Create a Year-Week index
    df['Year'] = df['Date'].dt.isocalendar().year
    df['Week'] = df['Date'].dt.isocalendar().week
    
    # Group by Division and Week
    # Sum for Yield and Labor, Mean for Weather
    agg_logic = {
        'Target_Usable_Yield_Kg': 'sum',
        'Labor_Total': 'sum',
        'Rainfall_Daily_mm': 'mean',
        'Temperature_Daily_C': 'mean',
        'Humidity_Mean_Pct': 'mean',
        'G_Pct': 'mean',
        'C_Pct': 'mean',
        'D_Pct': 'mean',
        'Kg_Per_Worker_Potential': 'mean'
    }
    
    weekly_df = df.groupby(['Division_ID', 'Year', 'Week']).agg(agg_logic).reset_index()
    
    # Re-calculate a representative date for each week (Monday)
    weekly_df['Date'] = weekly_df.apply(lambda x: pd.to_datetime(f"{int(x.Year)}-W{int(x.Week)}-1", format='%G-W%V-%u'), axis=1)
    
    return weekly_df

# ==========================================
# EXECUTE
# ==========================================
for f_name in files:
    path = os.path.join(DATA_DIR, f_name)
    if os.path.exists(path):
        print(f"Aggregating {f_name} to weekly...")
        daily_df = pd.read_csv(path)
        weekly_df = aggregate_weekly(daily_df)
        weekly_df.to_csv(os.path.join(WEEKLY_DIR, f_name), index=False)

print(f"✅ Success! Weekly datasets saved to {WEEKLY_DIR}")