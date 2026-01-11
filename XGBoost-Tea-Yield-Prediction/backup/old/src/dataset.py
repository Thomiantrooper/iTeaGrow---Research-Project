# import pandas as pd
# import numpy as np
# import random
# import os
# from datetime import timedelta, date

# # ==========================================
# # 1. CONFIGURATION
# # ==========================================
# project_root = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project"
# output_folder = os.path.join(project_root, "dataset_real_forced_corrected_covid_v4")

# if not os.path.exists(output_folder):
#     os.makedirs(output_folder)

# # ==========================================
# # 2. DATE RANGE & PARAMETERS
# # ==========================================
# start_date = date(2018, 3, 4)
# end_date = date(2025, 12, 23)
# divisions = ['LN', 'NC', 'LYN', 'ELT']

# labor_stats = {
#     'LN': {'reg': 40, 'cash': 12, 'men': 10, 'cont': 2},
#     'NC': {'reg': 55, 'cash': 18, 'men': 15, 'cont': 0},
#     'LYN': {'reg': 45, 'cash': 12, 'men': 30, 'cont': 5},
#     'ELT': {'reg': 40, 'cash': 8, 'men': 10, 'cont': 20}
# }

# pruning_schedule = {
#     'LN': [2013, 2018, 2023],
#     'NC': [2014, 2019, 2024],
#     'LYN': [2015, 2020, 2025],
#     'ELT': [2012, 2017, 2022]
# }

# monthly_patterns = {
#     1: {'flush': 0.8, 'rain_prob': 0.45, 'gamma_shape': 1.6, 'gamma_scale': 8},
#     2: {'flush': 0.7, 'rain_prob': 0.40, 'gamma_shape': 1.5, 'gamma_scale': 7},
#     3: {'flush': 0.9, 'rain_prob': 0.50, 'gamma_shape': 1.7, 'gamma_scale': 9},
#     4: {'flush': 1.1, 'rain_prob': 0.70, 'gamma_shape': 2.0, 'gamma_scale': 10},
#     5: {'flush': 1.4, 'rain_prob': 0.85, 'gamma_shape': 2.2, 'gamma_scale': 12},
#     6: {'flush': 1.3, 'rain_prob': 0.80, 'gamma_shape': 2.1, 'gamma_scale': 11},
#     7: {'flush': 1.0, 'rain_prob': 0.75, 'gamma_shape': 1.9, 'gamma_scale': 10},
#     8: {'flush': 0.9, 'rain_prob': 0.70, 'gamma_shape': 1.8, 'gamma_scale': 9},
#     9: {'flush': 1.0, 'rain_prob': 0.75, 'gamma_shape': 2.0, 'gamma_scale': 10},
#     10: {'flush': 1.2, 'rain_prob': 0.90, 'gamma_shape': 2.4, 'gamma_scale': 14},
#     11: {'flush': 1.2, 'rain_prob': 0.95, 'gamma_shape': 2.6, 'gamma_scale': 16},
#     12: {'flush': 1.0, 'rain_prob': 0.85, 'gamma_shape': 2.2, 'gamma_scale': 12}
# }

# # ==========================================
# # 3. COVID & RECOVERY LOGIC
# # ==========================================
# covid_period_1_start = date(2020, 3, 21)
# covid_period_1_end = date(2020, 6, 30)
# covid_period_2_start = date(2020, 10, 4)
# covid_period_2_end = date(2021, 5, 20)

# def is_covid_lockdown(d):
#     p1 = covid_period_1_start <= d <= covid_period_1_end
#     p2 = covid_period_2_start <= d <= covid_period_2_end
#     return p1 or p2

# def get_recovery_factor(d):
#     recovery_duration_days = 90
#     days_since_c1 = (d - covid_period_1_end).days
#     if 0 < days_since_c1 <= recovery_duration_days:
#         return 0.2 + (0.8 * (days_since_c1 / recovery_duration_days))
    
#     days_since_c2 = (d - covid_period_2_end).days
#     if 0 < days_since_c2 <= recovery_duration_days:
#         return 0.2 + (0.8 * (days_since_c2 / recovery_duration_days))
    
#     return 1.0

# # ==========================================
# # 4. FORCED REAL DATA
# # ==========================================
# forced_data = {
#     ('2025-12-17', 'LN'): {'Labor_Reg':24, 'Labor_Cash':9, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':748, 'G_Pct':46, 'C_Pct':40, 'D_Pct':14, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-17', 'NC'): {'Labor_Reg':36, 'Labor_Cash':22, 'Labor_Men':10, 'Labor_Cont':0, 'Crop_Harvested_Kg':1411, 'G_Pct':45, 'C_Pct':44, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-17', 'LYN'): {'Labor_Reg':29, 'Labor_Cash':10, 'Labor_Men':27, 'Labor_Cont':0, 'Crop_Harvested_Kg':1279, 'G_Pct':40, 'C_Pct':50, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-17', 'ELT'): {'Labor_Reg':40, 'Labor_Cash':5, 'Labor_Men':12, 'Labor_Cont':13, 'Crop_Harvested_Kg':1320, 'G_Pct':44, 'C_Pct':40, 'D_Pct':16, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-01', 'LN'): {'Labor_Reg':14, 'Labor_Cash':3, 'Labor_Men':4, 'Labor_Cont':0, 'Crop_Harvested_Kg':527, 'G_Pct':48, 'C_Pct':39, 'D_Pct':13, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':1555, 'Inter_Osborn_Kg':1781},
#     ('2025-12-01', 'NC'): {'Labor_Reg':0, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':0, 'G_Pct':0, 'C_Pct':0, 'D_Pct':0, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':1555, 'Inter_Osborn_Kg':1781},
#     ('2025-12-01', 'LYN'): {'Labor_Reg':32, 'Labor_Cash':8, 'Labor_Men':28, 'Labor_Cont':0, 'Crop_Harvested_Kg':1111, 'G_Pct':48, 'C_Pct':40, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':1555, 'Inter_Osborn_Kg':1781},
#     ('2025-12-01', 'ELT'): {'Labor_Reg':34, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':12, 'Crop_Harvested_Kg':856, 'G_Pct':47, 'C_Pct':43, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':1555, 'Inter_Osborn_Kg':1781},
#     ('2025-12-22', 'LN'): {'Labor_Reg':0, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':0, 'G_Pct':0, 'C_Pct':0, 'D_Pct':0, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-22', 'NC'): {'Labor_Reg':47, 'Labor_Cash':17, 'Labor_Men':1, 'Labor_Cont':0, 'Crop_Harvested_Kg':1083, 'G_Pct':45, 'C_Pct':44, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-22', 'LYN'): {'Labor_Reg':31, 'Labor_Cash':7, 'Labor_Men':30, 'Labor_Cont':1, 'Crop_Harvested_Kg':1333, 'G_Pct':46, 'C_Pct':42, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-22', 'ELT'): {'Labor_Reg':36, 'Labor_Cash':5, 'Labor_Men':0, 'Labor_Cont':14, 'Crop_Harvested_Kg':1157, 'G_Pct':45, 'C_Pct':44, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-16', 'LN'): {'Labor_Reg':28, 'Labor_Cash':7, 'Labor_Men':11, 'Labor_Cont':0, 'Crop_Harvested_Kg':982, 'G_Pct':43, 'C_Pct':46, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-16', 'NC'): {'Labor_Reg':36, 'Labor_Cash':13, 'Labor_Men':9, 'Labor_Cont':0, 'Crop_Harvested_Kg':1122, 'G_Pct':48, 'C_Pct':42, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-16', 'LYN'): {'Labor_Reg':30, 'Labor_Cash':8, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':775, 'G_Pct':45, 'C_Pct':44, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-16', 'ELT'): {'Labor_Reg':35, 'Labor_Cash':6, 'Labor_Men':9, 'Labor_Cont':13, 'Crop_Harvested_Kg':1216, 'G_Pct':48, 'C_Pct':42, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-12', 'LN'): {'Labor_Reg':21, 'Labor_Cash':10, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':794, 'G_Pct':45, 'C_Pct':45, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-12', 'NC'): {'Labor_Reg':39, 'Labor_Cash':14, 'Labor_Men':9, 'Labor_Cont':0, 'Crop_Harvested_Kg':1031, 'G_Pct':47, 'C_Pct':42, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-12', 'LYN'): {'Labor_Reg':30, 'Labor_Cash':6, 'Labor_Men':0, 'Labor_Cont':3, 'Crop_Harvested_Kg':713, 'G_Pct':45, 'C_Pct':45, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-12', 'ELT'): {'Labor_Reg':27, 'Labor_Cash':0, 'Labor_Men':4, 'Labor_Cont':7, 'Crop_Harvested_Kg':687, 'G_Pct':46, 'C_Pct':44, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-19', 'LN'): {'Labor_Reg':31, 'Labor_Cash':10, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':701, 'G_Pct':47, 'C_Pct':42, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-19', 'NC'): {'Labor_Reg':47, 'Labor_Cash':15, 'Labor_Men':12, 'Labor_Cont':0, 'Crop_Harvested_Kg':1520, 'G_Pct':46, 'C_Pct':42, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-19', 'LYN'): {'Labor_Reg':32, 'Labor_Cash':8, 'Labor_Men':9, 'Labor_Cont':0, 'Crop_Harvested_Kg':1208, 'G_Pct':45, 'C_Pct':44, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-19', 'ELT'): {'Labor_Reg':32, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':12, 'Crop_Harvested_Kg':811, 'G_Pct':44, 'C_Pct':46, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-08', 'LN'): {'Labor_Reg':33, 'Labor_Cash':9, 'Labor_Men':3, 'Labor_Cont':0, 'Crop_Harvested_Kg':1342, 'G_Pct':46, 'C_Pct':42, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':590, 'Inter_Osborn_Kg':590},
#     ('2025-12-08', 'NC'): {'Labor_Reg':43, 'Labor_Cash':15, 'Labor_Men':3, 'Labor_Cont':0, 'Crop_Harvested_Kg':1581, 'G_Pct':48, 'C_Pct':41, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':590, 'Inter_Osborn_Kg':590},
#     ('2025-12-08', 'LYN'): {'Labor_Reg':30, 'Labor_Cash':10, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':942, 'G_Pct':45, 'C_Pct':45, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':590, 'Inter_Osborn_Kg':590},
#     ('2025-12-08', 'ELT'): {'Labor_Reg':43, 'Labor_Cash':6, 'Labor_Men':14, 'Labor_Cont':17, 'Crop_Harvested_Kg':1295, 'G_Pct':46, 'C_Pct':44, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':590, 'Inter_Osborn_Kg':590},
#     ('2025-12-11', 'LN'): {'Labor_Reg':29, 'Labor_Cash':11, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':1144, 'G_Pct':43, 'C_Pct':47, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-11', 'NC'): {'Labor_Reg':42, 'Labor_Cash':14, 'Labor_Men':4, 'Labor_Cont':0, 'Crop_Harvested_Kg':1244, 'G_Pct':45, 'C_Pct':42, 'D_Pct':13, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-11', 'LYN'): {'Labor_Reg':29, 'Labor_Cash':6, 'Labor_Men':19, 'Labor_Cont':3, 'Crop_Harvested_Kg':1190, 'G_Pct':45, 'C_Pct':45, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-11', 'ELT'): {'Labor_Reg':28, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':7, 'Crop_Harvested_Kg':698, 'G_Pct':44, 'C_Pct':44, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-04', 'LN'): {'Labor_Reg':34, 'Labor_Cash':14, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':1399, 'G_Pct':44, 'C_Pct':44, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-04', 'NC'): {'Labor_Reg':50, 'Labor_Cash':10, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':1520, 'G_Pct':46, 'C_Pct':42, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-04', 'LYN'): {'Labor_Reg':34, 'Labor_Cash':10, 'Labor_Men':34, 'Labor_Cont':2, 'Crop_Harvested_Kg':1768, 'G_Pct':42, 'C_Pct':47, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-04', 'ELT'): {'Labor_Reg':0, 'Labor_Cash':6, 'Labor_Men':0, 'Labor_Cont':27, 'Crop_Harvested_Kg':1210, 'G_Pct':40, 'C_Pct':48, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-07', 'LN'): {'Labor_Reg':39, 'Labor_Cash':7, 'Labor_Men':14, 'Labor_Cont':0, 'Crop_Harvested_Kg':1949, 'G_Pct':43, 'C_Pct':46, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-07', 'NC'): {'Labor_Reg':48, 'Labor_Cash':13, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':1594, 'G_Pct':47, 'C_Pct':41, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-07', 'LYN'): {'Labor_Reg':32, 'Labor_Cash':5, 'Labor_Men':32, 'Labor_Cont':0, 'Crop_Harvested_Kg':1737, 'G_Pct':47, 'C_Pct':41, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-07', 'ELT'): {'Labor_Reg':0, 'Labor_Cash':5, 'Labor_Men':7, 'Labor_Cont':40, 'Crop_Harvested_Kg':1143, 'G_Pct':46, 'C_Pct':44, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-02', 'LN'): {'Labor_Reg':32, 'Labor_Cash':12, 'Labor_Men':12, 'Labor_Cont':0, 'Crop_Harvested_Kg':1502, 'G_Pct':46, 'C_Pct':40, 'D_Pct':14, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':339},
#     ('2025-12-02', 'NC'): {'Labor_Reg':40, 'Labor_Cash':14, 'Labor_Men':16, 'Labor_Cont':0, 'Crop_Harvested_Kg':1361, 'G_Pct':46, 'C_Pct':39, 'D_Pct':15, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':339},
#     ('2025-12-02', 'LYN'): {'Labor_Reg':32, 'Labor_Cash':8, 'Labor_Men':28, 'Labor_Cont':0, 'Crop_Harvested_Kg':1335, 'G_Pct':43, 'C_Pct':45, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':339},
#     ('2025-12-02', 'ELT'): {'Labor_Reg':37, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':17, 'Crop_Harvested_Kg':1005, 'G_Pct':44, 'C_Pct':46, 'D_Pct':10, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':339},
#     ('2025-12-21', 'LN'): {'Labor_Reg':0, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':0, 'G_Pct':0, 'C_Pct':0, 'D_Pct':0, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-21', 'NC'): {'Labor_Reg':0, 'Labor_Cash':53, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':744, 'G_Pct':44, 'C_Pct':40, 'D_Pct':16, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-21', 'LYN'): {'Labor_Reg':0, 'Labor_Cash':0, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':0, 'G_Pct':0, 'C_Pct':0, 'D_Pct':0, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-21', 'ELT'): {'Labor_Reg':0, 'Labor_Cash':12, 'Labor_Men':0, 'Labor_Cont':28, 'Crop_Harvested_Kg':1328, 'G_Pct':42, 'C_Pct':46, 'D_Pct':12, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-23', 'LN'): {'Labor_Reg':19, 'Labor_Cash':4, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':489, 'G_Pct':43, 'C_Pct':42, 'D_Pct':15, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-23', 'NC'): {'Labor_Reg':37, 'Labor_Cash':11, 'Labor_Men':0, 'Labor_Cont':0, 'Crop_Harvested_Kg':994, 'G_Pct':45, 'C_Pct':44, 'D_Pct':11, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-23', 'LYN'): {'Labor_Reg':26, 'Labor_Cash':6, 'Labor_Men':29, 'Labor_Cont':1, 'Crop_Harvested_Kg':1078, 'G_Pct':44, 'C_Pct':43, 'D_Pct':13, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
#     ('2025-12-23', 'ELT'): {'Labor_Reg':32, 'Labor_Cash':3, 'Labor_Men':0, 'Labor_Cont':7, 'Crop_Harvested_Kg':901, 'G_Pct':44, 'C_Pct':42, 'D_Pct':14, 'Inter_Poyston_Kg':0, 'Inter_Lethenty_Kg':0, 'Inter_Osborn_Kg':0},
# }

# # ==========================================
# # 5. GENERATOR
# # ==========================================
# data_rows = []
# weather_history = {}
# current_date = start_date

# while current_date <= end_date:
#     date_str = current_date.strftime('%Y-%m-%d')
#     month = current_date.month
    
#     mp = monthly_patterns[month]
    
#     # --- Weather Generation ---
#     # Calculate previous 7 days sum
#     lag_rain = sum(weather_history.get(current_date - timedelta(days=x), 0) for x in range(1, 8))
    
#     rain_today = 0
#     if random.random() < mp['rain_prob']:
#         rain_today = int(np.random.gamma(mp['gamma_shape'], mp['gamma_scale']))
#         if random.random() < 0.05:
#             rain_today = int(rain_today * random.uniform(2, 5))

#     # --- RAINFALL CONTROL: STRICT LIMITS ---
#     # Throttle if lag is high
#     if lag_rain > 210:
#         rain_today = int(rain_today * 0.1) 
    
#     # Cap total
#     max_allowed = 300 - lag_rain
#     if max_allowed < 0: max_allowed = 0
    
#     if rain_today > max_allowed:
#         rain_today = max_allowed

#     # --- COVID STRICT OVERRIDE FOR RAINFALL AND LAG ---
#     # User requirement: "all records must be 0 (since its covid)"
#     # This implies Lag must be 0 in the CSV record because nobody measured it.
#     is_covid = is_covid_lockdown(current_date)
    
#     if is_covid:
#         rain_today = 0
#         lag_rain = 0  # <--- FIXED: Force Lag to 0 in the dataset for COVID days

#     # Save finalized rain to history 
#     # (Note: we save 0 for today, so tomorrow's lag calc naturally starts dropping)
#     weather_history[current_date] = rain_today

#     # --- RECOVERY LOGIC ---
#     rec_factor = get_recovery_factor(current_date)

#     for div in divisions:
#         reg = cash = men = cont = total_labor = 0
#         crop = g_pct = c_pct = d_pct = 0
#         est_ha = pot_yield = waste_calc = usable_yield = 0
#         inter_p = inter_l = inter_o = 0

#         if is_covid:
#             # During COVID periods, everything is 0
#             pass 
#         else:
#             use_forced = False
#             row = None
            
#             # Check forced data
#             if (date_str, div) in forced_data:
#                 row = forced_data[(date_str, div)]
#                 forced_labor = row['Labor_Reg'] + row['Labor_Cash'] + row['Labor_Men'] + row.get('Labor_Cont', 0)
#                 if row['Crop_Harvested_Kg'] > 0 and forced_labor > 0:
#                     use_forced = True
            
#             if use_forced and row:
#                 reg = row['Labor_Reg']
#                 cash = row['Labor_Cash']
#                 men = row['Labor_Men']
#                 cont = row.get('Labor_Cont', 0)
#                 total_labor = reg + cash + men + cont
                
#                 crop = row['Crop_Harvested_Kg']
#                 g_pct = row['G_Pct']
#                 c_pct = row['C_Pct']
#                 d_pct = row['D_Pct']
#                 inter_p = row['Inter_Poyston_Kg']
#                 inter_l = row['Inter_Lethenty_Kg']
#                 inter_o = row['Inter_Osborn_Kg']
                
#                 est_ha = round(total_labor / 8.5, 2)
#                 pot_yield = round(crop / total_labor, 2)
#                 waste_calc = d_pct + (c_pct / 2)
#                 usable_yield = round(crop * (1 - (waste_calc / 100)), 2) + (inter_p + inter_l + inter_o)
                
#             else:
#                 # SYNTHETIC GENERATION
#                 prune_years = [yr for yr in pruning_schedule[div] if yr <= current_date.year]
#                 last_prune = max(prune_years) if prune_years else current_date.year - 10
#                 years_since = current_date.year - last_prune
#                 age_factor = {0: 0.6, 1: 1.0, 2: 1.2, 3: 1.1, 4: 0.9, 5: 0.8}.get(years_since, 0.7)
                
#                 base = labor_stats[div]
                
#                 reg = max(5, int(np.random.normal(base['reg'], 6)))
#                 cash = max(2, int(np.random.normal(base['cash'], 5)))
#                 men = max(2, int(np.random.normal(base['men'], 5)))
#                 cont = max(1, int(np.random.normal(base['cont'], 5)))
                
#                 if current_date.weekday() == 6: 
#                     reg = max(5, int(reg * random.uniform(0.15, 0.35)))
#                     men = max(2, int(men * 0.15))
#                     cash = max(2, int(cash * random.uniform(0.95, 1.2)))
                    
#                 if current_date.month == 4 and 10 <= current_date.day <= 20: 
#                     reg = max(5, int(reg * 0.35))
#                     cash = max(2, int(cash * 0.2))
                    
#                 if mp['flush'] > 1.2:
#                     cash = max(5, int(cash * random.uniform(1.4, 1.8)))
                
#                 # RECOVERY FACTOR ON LABOR
#                 if rec_factor < 1.0:
#                     reg = int(reg * rec_factor)
#                     cash = int(cash * rec_factor)
#                     men = int(men * rec_factor)
#                     cont = int(cont * rec_factor)

#                 total_labor = reg + cash + men + cont
                
#                 if total_labor > 0:
#                     base_cpk = np.random.uniform(18, 26) * mp['flush'] * age_factor
                    
#                     rain_penalty = 1.0
#                     if rain_today > 20:
#                         rain_penalty = random.uniform(0.65, 0.9)
#                     if rain_today > 60:
#                         rain_penalty *= 0.5 
#                     if lag_rain < 20:
#                         rain_penalty *= random.uniform(0.7, 0.9)
                        
#                     men_ratio = men / total_labor
#                     men_penalty = 1.0 - (men_ratio * random.uniform(0.2, 0.3))
                    
#                     raw_crop = int(total_labor * base_cpk * rain_penalty * men_penalty)
                    
#                     # RECOVERY FACTOR ON CROP
#                     if rec_factor < 1.0:
#                         raw_crop = int(raw_crop * rec_factor)

#                     crop = max(50, raw_crop) 
#                 else:
#                     crop = 0

#                 waste_base = 12
#                 coarse_base = 42
#                 if rain_today > 5:
#                     waste_base += random.uniform(1, 4)
                    
#                 d_pct = max(2, int(np.random.normal(waste_base, 1.5)))
#                 c_pct = max(10, int(np.random.normal(coarse_base, 2.5)))
                
#                 if d_pct + c_pct > 95:
#                     d_pct = int(d_pct * 0.8)
#                     c_pct = int(c_pct * 0.8)
                    
#                 g_pct = 100 - d_pct - c_pct
#                 if g_pct <= 0: g_pct = 5
                
#                 est_ha = round(total_labor / 8.5, 2)
#                 if est_ha <= 0: est_ha = 0.5
                
#                 pot_yield = 0
#                 if total_labor > 0:
#                     pot_yield = round(crop / total_labor, 2)
                
#                 waste_calc = d_pct + (c_pct / 2)
#                 if waste_calc <= 0: waste_calc = 1
                
#                 usable_yield = round(crop * (1 - (waste_calc / 100)), 2)
#                 if usable_yield <= 0: usable_yield = 0

#                 if rec_factor > 0.8: 
#                     transfer_prob = 0.22 
#                     if mp['flush'] > 1.1:
#                         transfer_prob += 0.08
                        
#                     if random.random() < transfer_prob:
#                         if random.random() < 0.6:
#                             inter_total = random.randint(300, 900)
#                         else:
#                             inter_total = random.randint(1200, 4000)
                            
#                         weights = [random.uniform(0.1, 1.5) for _ in range(3)]
#                         total_w = sum(weights)
#                         splits = [int(inter_total * w / total_w) for w in weights]
#                         inter_p, inter_l, inter_o = splits
#                         usable_yield += inter_total

#         data_rows.append([
#             current_date, div, rain_today, lag_rain,
#             reg, cash, men, cont, total_labor,
#             crop, g_pct, c_pct, d_pct,
#             est_ha, pot_yield, waste_calc, usable_yield,
#             inter_p, inter_l, inter_o
#         ])

#     current_date += timedelta(days=1)

# # ==========================================
# # 6. SAVE
# # ==========================================
# cols = [
#     "Date", "Division_ID", "Rainfall_Daily_mm", "Rainfall_Lag_7d",
#     "Labor_Reg", "Labor_Cash", "Labor_Men", "Labor_Cont", "Labor_Total",
#     "Crop_Harvested_Kg", "G_Pct", "C_Pct", "D_Pct",
#     "Est_Field_Size_Ha", "Kg_Per_Worker_Potential", "Calculated_Waste_Pct", "Target_Usable_Yield_Kg",
#     "Inter_Poyston_Kg", "Inter_Lethenty_Kg", "Inter_Osborn_Kg"
# ]

# df = pd.DataFrame(data_rows, columns=cols)
# df['Date'] = pd.to_datetime(df['Date'])

# full_path = os.path.join(output_folder, "Master_Dataset_Full_RealForced.csv")
# df.sort_values(by=['Date', 'Division_ID']).reset_index(drop=True).to_csv(full_path, index=False)
# print(f"File 1 saved: {full_path}")

# reduced_cols = [
#     "Date", "Division_ID", "Rainfall_Daily_mm", "Rainfall_Lag_7d",
#     "Labor_Total", "Crop_Harvested_Kg", "G_Pct", "C_Pct", "D_Pct",
#     "Est_Field_Size_Ha", "Kg_Per_Worker_Potential", "Calculated_Waste_Pct", "Target_Usable_Yield_Kg"
# ]
# df_reduced = df[reduced_cols]
# master_path = os.path.join(output_folder, "Master_Reduced.csv")
# df_reduced.sort_values(by=['Date', 'Division_ID']).reset_index(drop=True).to_csv(master_path, index=False)
# print(f"File 2 saved: {master_path}")

# # Split for ML
# df_shuffled = df_reduced.sample(frac=1, random_state=42).reset_index(drop=True)
# train_end = int(0.70 * len(df_shuffled))
# val_end = int(0.85 * len(df_shuffled))

# train_df = df_shuffled.iloc[:train_end]
# test_df = df_shuffled.iloc[val_end:]
# valid_df = df_shuffled.iloc[train_end:val_end]

# train_df.to_csv(os.path.join(output_folder, "train_yield.csv"), index=False)
# test_df.to_csv(os.path.join(output_folder, "test_yield.csv"), index=False)
# valid_df.to_csv(os.path.join(output_folder, "valid_yield.csv"), index=False)

# print("\nAll 5 files generated successfully.")







# ### to verify and visualize the generated data



import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# =================================================
#  CONFIG - CHANGE THIS PATH TO WHERE YOUR FILE ACTUALLY IS
# =================================================
# Pick ONE of the following (uncomment the correct one)

# Most likely locations based on your previous messages
MASTER_FILE_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\dataset\Master_Reduced.csv"
# MASTER_FILE_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\dataset2\Master_Dataset_Full.csv"
# MASTER_FILE_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\dataset3\Master_Dataset_Full.csv"
# MASTER_FILE_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\dataset\Master_Dataset_Full_Messy.csv"

# =================================================
#  Safety checks
# =================================================
if not os.path.exists(MASTER_FILE_PATH):
    print("\n" + "="*70)
    print("ERROR: File not found!")
    print(f"Path tried: {MASTER_FILE_PATH}")
    print("\nPlease check the following:")
    print("1. Did you run the data generation script successfully?")
    print("2. In which folder was Master_Dataset_Full.csv created?")
    print("   → Look in: dataset, dataset2, dataset3, etc.")
    print("3. Update MASTER_FILE_PATH above to the correct location.")
    print("="*70 + "\n")
    raise FileNotFoundError(f"Cannot find: {MASTER_FILE_PATH}")

print(f"Loading data from: {MASTER_FILE_PATH}")

# Load the data
try:
    df = pd.read_csv(MASTER_FILE_PATH)
    df['Date'] = pd.to_datetime(df['Date'])
    print(f"Success → Loaded {len(df):,} rows")
except Exception as e:
    print("Error reading CSV:", str(e))
    raise

# Required columns check
required_cols = ['Date', 'Labor_Total', 'Crop_Harvested_Kg', 'Rainfall_Daily_mm']
missing = [col for col in required_cols if col not in df.columns]
if missing:
    print(f"ERROR: Missing columns: {missing}")
    print("Available columns:", list(df.columns))
    raise ValueError("Missing required columns")

# =================================================
#  Aggregate to estate level per day (most realistic view)
# =================================================
daily = df.groupby('Date').agg({
    'Crop_Harvested_Kg': 'sum',
    'Labor_Total': 'sum',
    'Rainfall_Daily_mm': 'mean'   # or 'sum' if you prefer total rainfall
}).reset_index()

print(f"Aggregated to {len(daily)} daily estate-level records")

# =================================================
#  Plotting
# =================================================
sns.set(style="whitegrid")
plt.figure(figsize=(18, 6))

# --- GRAPH 1: Daily Crop – Full recent period + zoom ---
plt.subplot(1, 3, 1)

# Show last 2–3 years if available, or maximum available
recent = daily[daily['Date'].dt.year >= 2023]
if len(recent) == 0:
    recent = daily.tail(400)  # fallback: last ~1 year

plt.plot(recent['Date'], recent['Crop_Harvested_Kg'], color='green', linewidth=1.8, alpha=0.9)
plt.title("Estate Daily Crop Harvested (recent period)\nLook for Sunday dips & flush peaks", fontsize=11)
plt.xlabel("Date")
plt.ylabel("Crop (kg)")
plt.xticks(rotation=45)
plt.grid(True, alpha=0.3)

# Optional: highlight Sundays
sundays = recent[recent['Date'].dt.weekday == 6]
if not sundays.empty:
    plt.scatter(sundays['Date'], sundays['Crop_Harvested_Kg'], color='red', s=30, alpha=0.6, label='Sundays')
    plt.legend()

# --- GRAPH 2: Labor vs Yield (estate total) ---
plt.subplot(1, 3, 2)
sns.scatterplot(
    x=daily['Labor_Total'],
    y=daily['Crop_Harvested_Kg'],
    alpha=0.4, color='blue', s=40
)
plt.title("Total Labor vs Total Crop (daily estate level)\nLook for strong positive trend", fontsize=11)
plt.xlabel("Total Labor (all divisions)")
plt.ylabel("Total Crop Harvested (kg)")
plt.grid(True, alpha=0.3)

# --- GRAPH 3: Rainfall Distribution ---
plt.subplot(1, 3, 3)
sns.histplot(daily['Rainfall_Daily_mm'], bins=40, color='purple', kde=True)
plt.title("Daily Rainfall Distribution (estate average)", fontsize=11)
plt.xlabel("Rainfall (mm)")
plt.ylabel("Count of days")
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# Bonus: Quick stats summary
print("\nQuick Summary Stats:")
print(daily[['Crop_Harvested_Kg', 'Labor_Total', 'Rainfall_Daily_mm']].describe().round(1))
print(f"\nDays with zero crop: { (daily['Crop_Harvested_Kg'] == 0).sum() } ({(daily['Crop_Harvested_Kg'] == 0).mean():.1%})")







# import pandas as pd
# import numpy as np
# import random
# import os
# from datetime import date, timedelta

# # ==========================================
# # 1. CONFIGURATION
# # ==========================================
# project_root = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project"
# output_folder = os.path.join(project_root, "dataset")
# os.makedirs(output_folder, exist_ok=True)

# # ==========================================
# # 2. DATE RANGE (exactly as you asked)
# # ==========================================
# start_date = date(2022, 2, 19)
# end_date   = date(2025, 11, 16)

# divisions = ['LN', 'NC', 'LYN', 'ELT']

# labor_stats = {
#     'LN':  {'reg': 40, 'cash': 12, 'men': 10, 'cont': 2},
#     'NC':  {'reg': 55, 'cash': 18, 'men': 15, 'cont': 0},
#     'LYN': {'reg': 45, 'cash': 12, 'men': 30, 'cont': 5},
#     'ELT': {'reg': 40, 'cash': 8,  'men': 10, 'cont': 20},
# }

# pruning_schedule = {
#     'LN':  [2013, 2018, 2023],
#     'NC':  [2014, 2019, 2024],
#     'LYN': [2015, 2020, 2025],
#     'ELT': [2012, 2017, 2022],
# }

# # Monthly flush + rainfall params (tightened for realism)
# monthly_patterns = {
#     1:  {'flush': 0.80, 'rain_prob': 0.50, 'shape': 1.4, 'scale':  9.0, 'max_rain': 120},
#     2:  {'flush': 0.75, 'rain_prob': 0.45, 'shape': 1.3, 'scale':  8.0, 'max_rain': 110},
#     3:  {'flush': 0.90, 'rain_prob': 0.55, 'shape': 1.6, 'scale': 10.0, 'max_rain': 140},
#     4:  {'flush': 1.10, 'rain_prob': 0.75, 'shape': 2.0, 'scale': 11.0, 'max_rain': 180},
#     5:  {'flush': 1.40, 'rain_prob': 0.90, 'shape': 2.3, 'scale': 12.5, 'max_rain': 220},
#     6:  {'flush': 1.35, 'rain_prob': 0.85, 'shape': 2.2, 'scale': 12.0, 'max_rain': 200},
#     7:  {'flush': 1.05, 'rain_prob': 0.80, 'shape': 1.9, 'scale': 11.0, 'max_rain': 160},
#     8:  {'flush': 0.95, 'rain_prob': 0.75, 'shape': 1.8, 'scale': 10.0, 'max_rain': 140},
#     9:  {'flush': 1.00, 'rain_prob': 0.80, 'shape': 1.9, 'scale': 10.5, 'max_rain': 150},
#     10: {'flush': 1.20, 'rain_prob': 0.92, 'shape': 2.5, 'scale': 13.5, 'max_rain': 250},
#     11: {'flush': 1.25, 'rain_prob': 0.95, 'shape': 2.6, 'scale': 15.0, 'max_rain': 280},
#     12: {'flush': 1.05, 'rain_prob': 0.88, 'shape': 2.2, 'scale': 12.0, 'max_rain': 220},
# }

# # Paste your full forced_data dictionary here
# forced_data = {
#     # ('2025-12-17', 'LN'): {...},   # your original entries
#     # ... all of them ...
# }

# # ==========================================
# # 5. GENERATOR
# # ==========================================
# data_rows = []
# weather_history = {}

# current_date = start_date
# while current_date <= end_date:
#     date_str = current_date.strftime('%Y-%m-%d')
#     month = current_date.month
#     mp = monthly_patterns[month]

#     # Rainfall — now with monthly max cap
#     lag_rain = sum(weather_history.get(current_date - timedelta(days=x), 0) for x in range(1, 8))
#     rain_today = 0
#     if random.random() < mp['rain_prob']:
#         rain_today = int(np.random.gamma(mp['shape'], mp['scale']))
#         if random.random() < 0.06:
#             rain_today = int(rain_today * random.uniform(1.8, 3.5))

#     rain_today = max(0, min(rain_today, mp['max_rain']))
#     if lag_rain > 400:
#         rain_today = int(rain_today * 0.25)

#     weather_history[current_date] = rain_today

#     for div in divisions:
#         if (date_str, div) in forced_data:
#             row = forced_data[(date_str, div)]
#             reg   = row['Labor_Reg']
#             cash  = row['Labor_Cash']
#             men   = row['Labor_Men']
#             cont  = row.get('Labor_Cont', 0)
#             total_labor = reg + cash + men + cont
#             crop    = row['Crop_Harvested_Kg']
#             g_pct   = row['G_Pct']
#             c_pct   = row['C_Pct']
#             d_pct   = row['D_Pct']
#             inter_p = row['Inter_Poyston_Kg']
#             inter_l = row['Inter_Lethenty_Kg']
#             inter_o = row['Inter_Osborn_Kg']

#         else:
#             base = labor_stats[div]

#             reg  = max(4,  int(np.random.normal(base['reg'],  6.5)))
#             cash = max(2,  int(np.random.normal(base['cash'], 5.5)))
#             men  = max(2,  int(np.random.normal(base['men'],  7.5)))
#             cont = max(0,  int(np.random.normal(base['cont'], 4.5)))

#             if current_date.weekday() == 6:
#                 reg  = max(3, int(reg * random.uniform(0.45, 0.75)))
#                 men  = max(1, int(men * 0.55))

#             total_labor = reg + cash + men + cont

#             # Pruning effect
#             yrs = [y for y in pruning_schedule[div] if y <= current_date.year]
#             last = max(yrs) if yrs else current_date.year - 12
#             age = current_date.year - last
#             age_f = {0:0.70, 1:1.00, 2:1.20, 3:1.10, 4:0.92, 5:0.82}.get(age, 0.78)

#             base_cpk = np.random.uniform(19, 27)          # tighter range than before
#             rain_penalty = 1.0
#             if rain_today > 50:   rain_penalty *= random.uniform(0.60, 0.88)
#             if rain_today > 90:   rain_penalty *= 0.50
#             if lag_rain < 12:     rain_penalty *= random.uniform(0.78, 0.94)

#             raw_crop = total_labor * base_cpk * mp['flush'] * age_f * rain_penalty
#             # Enforce realistic minimum kg/worker
#             min_crop = total_labor * 18.5
#             crop = max(int(min_crop), int(raw_crop))
#             crop = min(crop, total_labor * 50)           # upper realistic bound

#             # Quality — forced into sample-like range
#             g_mean = random.uniform(43, 47)
#             c_mean = random.uniform(40, 46)
#             d_mean = 100 - g_mean - c_mean
#             g_pct = np.random.normal(g_mean, 3.5)
#             c_pct = np.random.normal(c_mean, 4.0)
#             d_pct = 100 - g_pct - c_pct

#             # Fix composition
#             if d_pct < 5 or g_pct < 35 or c_pct < 30:
#                 vec = np.array([max(35, g_pct), max(30, c_pct), max(5, d_pct)])
#                 vec = vec / vec.sum() * 100
#                 g_pct, c_pct, d_pct = vec.round().astype(int)

#             g_pct, c_pct, d_pct = int(g_pct), int(c_pct), int(d_pct)

#             # Inter-division transfer — less frequent, larger when occurs
#             inter_p = inter_l = inter_o = 0
#             if random.random() < 0.12:
#                 total_inter = random.randint(600, 2800)
#                 w = np.random.dirichlet([1, 1.2, 0.8])
#                 inter_p, inter_l, inter_o = (total_inter * w).round().astype(int)

#         est_ha = round(total_labor / 8.5, 2) if total_labor > 0 else 0.0
#         kg_per_worker = round(crop / total_labor, 2) if total_labor > 0 else 0.0
#         waste_calc = d_pct + (c_pct / 2.0)
#         usable_yield = round(crop * (1 - waste_calc / 100), 2) + inter_p + inter_l + inter_o

#         data_rows.append([
#             current_date, div, rain_today, lag_rain,
#             reg, cash, men, cont, total_labor,
#             crop, g_pct, c_pct, d_pct,
#             est_ha, kg_per_worker, waste_calc, usable_yield,
#             inter_p, inter_l, inter_o
#         ])

#     current_date += timedelta(days=1)

# # ==========================================
# # 6. SAVE (exactly your requested structure)
# # ==========================================
# cols = [
#     "Date", "Division_ID", "Rainfall_Daily_mm", "Rainfall_Lag_7d",
#     "Labor_Reg", "Labor_Cash", "Labor_Men", "Labor_Cont", "Labor_Total",
#     "Crop_Harvested_Kg", "G_Pct", "C_Pct", "D_Pct",
#     "Est_Field_Size_Ha", "Kg_Per_Worker_Potential",
#     "Calculated_Waste_Pct", "Target_Usable_Yield_Kg",
#     "Inter_Poyston_Kg", "Inter_Lethenty_Kg", "Inter_Osborn_Kg"
# ]

# df = pd.DataFrame(data_rows, columns=cols)
# df['Date'] = pd.to_datetime(df['Date'])

# full_path = os.path.join(output_folder, "Master_Dataset_Full_RealForced.csv")
# df.sort_values(by=['Date', 'Division_ID']).reset_index(drop=True).to_csv(full_path, index=False)
# print(f"File 1 saved: {full_path}")

# reduced_cols = [
#     "Date", "Division_ID", "Rainfall_Daily_mm", "Rainfall_Lag_7d",
#     "Labor_Total", "Crop_Harvested_Kg", "G_Pct", "C_Pct", "D_Pct",
#     "Est_Field_Size_Ha", "Kg_Per_Worker_Potential",
#     "Calculated_Waste_Pct", "Target_Usable_Yield_Kg"
# ]

# df_reduced = df[reduced_cols]
# master_path = os.path.join(output_folder, "Master_Reduced.csv")
# df_reduced.sort_values(by=['Date', 'Division_ID']).reset_index(drop=True).to_csv(master_path, index=False)
# print(f"File 2 saved: {master_path}")

# # Correct time-series split (80/10/10 chronological)
# df_sorted = df_reduced.sort_values("Date").reset_index(drop=True)
# n = len(df_sorted)
# train_end = int(0.8 * n)
# val_end   = train_end + int(0.1 * n)

# train_df = df_sorted.iloc[:train_end]
# valid_df = df_sorted.iloc[train_end:val_end]
# test_df  = df_sorted.iloc[val_end:]

# train_df.to_csv(os.path.join(output_folder, "train_yield.csv"), index=False)
# valid_df.to_csv(os.path.join(output_folder, "valid_yield.csv"), index=False)
# test_df.to_csv(os.path.join(output_folder, "test_yield.csv"), index=False)

# print("\nAll 5 files generated successfully.")