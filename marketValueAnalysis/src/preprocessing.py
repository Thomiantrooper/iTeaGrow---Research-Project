import pandas as pd
import numpy as np
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import joblib

def preprocess_for_xgboost(df, is_training=True, save_encoders=True):
    """
    Complete preprocessing pipeline optimized for XGBoost
    
    Args:
        df: Raw dataframe
        is_training: True for training (fits encoders), False for inference
        save_encoders: Save encoders for later use
    
    Returns:
        X, y (if training) or X (if inference)
        Also returns feature names for model
    """
    
    # Make a copy to avoid modifying original
    data = df.copy()
    
    # ============================================
    # 1. DATE FEATURES (Cyclical Encoding)
    # ============================================
    print("Creating date features...")
    data['date_dt'] = pd.to_datetime(data['date'], dayfirst=True)
    
    # Cyclical encoding - better for XGBoost than raw month
    data['month'] = data['date_dt'].dt.month
    data['day_of_month'] = data['date_dt'].dt.day
    data['day_of_week'] = data['date_dt'].dt.dayofweek
    
    # Cyclical features (allows model to understand Jan -> Dec continuity)
    data['month_sin'] = np.sin(2 * np.pi * data['month'] / 12)
    data['month_cos'] = np.cos(2 * np.pi * data['month'] / 12)
    data['dow_sin'] = np.sin(2 * np.pi * data['day_of_week'] / 7)
    data['dow_cos'] = np.cos(2 * np.pi * data['day_of_week'] / 7)
    
    # ============================================
    # 2. GRADE ENCODING (Label Encoding for XGBoost)
    # ============================================
    print("Encoding grade...")
    
    # XGBoost works well with label encoding for ordinal categories
    # But since grades have natural order, we can use ordinal encoding
    grade_order = {
        'Dust1': 0,      # Lowest quality
        'Dust': 1,
        'Fanning1': 2,
        'Pekoe': 3,
        'BOP': 4,
        'BOPF': 5        # Highest quality
    }
    
    if is_training:
        # Create encoder during training
        grade_encoder = {grade: i for i, grade in enumerate(grade_order.keys())}
        joblib.dump(grade_encoder, '../results/preprocessing/grade_encoder.pkl')
    else:
        # Load encoder for inference
        grade_encoder = joblib.load('../results/preprocessing/grade_encoder.pkl')
    
    data['grade_encoded'] = data['grade'].map(grade_encoder)
    
    # ============================================
    # 3. SEASON ENCODING (Label Encoding)
    # ============================================
    print("Encoding season...")
    
    season_order = {'Off': 0, 'Normal': 1, 'Peak': 2}
    
    if is_training:
        season_encoder = season_order
        joblib.dump(season_encoder, '../results/preprocessing/season_encoder.pkl')
    else:
        season_encoder = joblib.load('../results/preprocessing/season_encoder.pkl')
    
    data['season_encoded'] = data['season'].map(season_encoder)
    
    # ============================================
    # 4. MARKET TRENDS (Calculate during preprocessing)
    # ============================================
    print("Calculating market trends...")
    
    # Sort by date for trend calculations
    data = data.sort_values('date')
    
    # Price momentum (percentage change)
    data['price_momentum_3d'] = data.groupby('grade')['market_price'].pct_change(periods=3)
    data['price_momentum_7d'] = data.groupby('grade')['market_price'].pct_change(periods=7)
    
    # Rolling statistics
    data['price_ma_7d'] = data.groupby('grade')['market_price'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    data['price_std_7d'] = data.groupby('grade')['market_price'].transform(
        lambda x: x.rolling(7, min_periods=1).std()
    )
    
    # ============================================
    # 5. RAINFALL FEATURES (Lagged effects)
    # ============================================
    print("Creating rainfall features...")
    
    # Rainfall has lagged effect on price (supply impact)
    data['rainfall_lag_7d'] = data.groupby('grade')['rainfall_mm'].shift(7)
    data['rainfall_lag_14d'] = data.groupby('grade')['rainfall_mm'].shift(14)
    data['rainfall_lag_30d'] = data.groupby('grade')['rainfall_mm'].shift(30)
    
    # Cumulative rainfall (supply shock)
    data['rainfall_cum_30d'] = data.groupby('grade')['rainfall_mm'].transform(
        lambda x: x.rolling(30, min_periods=1).sum()
    )
    
    # ============================================
    # 6. EXCHANGE RATE FEATURES
    # ============================================
    print("Processing exchange rates...")
    
    # Exchange rate trend
    data['exchange_momentum_7d'] = data['exchange_rate'].pct_change(periods=7)
    data['exchange_ma_7d'] = data['exchange_rate'].rolling(7, min_periods=1).mean()
    
    # ============================================
    # 7. QUALITY SCORES (Keep as is)
    # ============================================
    print("Quality scores already encoded...")
    # color, aroma, age are already 0, 0.5, 1 - perfect for XGBoost
    
    # ============================================
    # 8. CREATE INTERACTION FEATURES (FIXED)
    # ============================================
    print("Creating interaction features (Decomposed)...")
    
    # Decompose dominant feature
    data['grade_color'] = data['grade_encoded'] * data['color']
    data['grade_aroma'] = data['grade_encoded'] * data['aroma']
    data['grade_age'] = data['grade_encoded'] * data['age']
    
    data['market_rainfall_interaction'] = data['market_price'] * (data['rainfall_mm'] / 100)
    
    # ============================================
    # 9. HANDLE MISSING VALUES
    # ============================================
    print("Handling missing values...")
    
    # For XGBoost, we can use -999 for missing (XGBoost handles this well)
    # But better to use median/forward fill
    data = data.ffill().bfill()
    numeric_cols = data.select_dtypes(include=[np.number]).columns
    data[numeric_cols] = data[numeric_cols].fillna(data[numeric_cols].median())
    
    # ============================================
    # 10. SELECT FINAL FEATURES
    # ============================================
    print("Selecting final features...")
    
    feature_columns = [
        # From image model
        'grade_encoded',
        'confidence',
        
        # User inputs
        'color',
        'aroma', 
        'age',
        'quantity_kg',
        
        # Market data
        'market_price',
        'price_momentum_3d',
        'price_momentum_7d',
        # 'price_ma_7d',  # Dropped (Leaky)
        # 'price_std_7d', # Dropped (Leaky)
        
        # Rainfall features
        # Rainfall features
        'rainfall_mm',
        'rainfall_lag_7d',
        # 'rainfall_lag_14d', # Dropped
        'rainfall_lag_30d',
        # 'rainfall_cum_30d', # Dropped
        
        # Exchange rate
        # Exchange rate
        'exchange_rate',
        # 'exchange_momentum_7d', # Dropped
        
        # Seasonal
        # Seasonal
        # 'season_encoded', # Dropped to reduce noise
        # 'month_sin',      # Dropped
        # 'month_cos',      # Dropped
        
        # Interactions (Decomposed to reduce overfitting)
        'grade_color',
        'grade_aroma',
        'grade_age',
        'market_rainfall_interaction'
    ]
    
    # Ensure all features exist
    available_features = [col for col in feature_columns if col in data.columns]
    missing = set(feature_columns) - set(available_features)
    if missing:
        print(f"Missing features: {missing}")
    
    X = data[available_features]
    
    if is_training:
        y = data['actual_price']
        
        # Save feature names for inference
        joblib.dump(available_features, '../results/preprocessing/feature_names.pkl')
        print(f"Features saved: {len(available_features)} features")
        
        return X, y
    else:
        return X

# ============================================
# MAIN EXECUTION
# ============================================
if __name__ == "__main__":
    print("="*60)
    print("XGBoost Preprocessing Pipeline - Tea Price Prediction")
    print("="*60)
    
    # Load your dataset
    try:
        df = pd.read_csv("../dataset/tea pricing.csv")
    except FileNotFoundError:
        df = pd.read_csv("tea pricing.csv")
    print(f"Loaded {len(df)} rows")
    
    # Preprocess
    X, y = preprocess_for_xgboost(df, is_training=True)
    
    # Train/Test Split (time-based for time series!)
    print("\nSplitting data (time-based)...")
    split_idx = int(len(X) * 0.8)
    
    X_train = X.iloc[:split_idx]
    X_test = X.iloc[split_idx:]
    y_train = y.iloc[:split_idx]
    y_test = y.iloc[split_idx:]
    
    print(f"  Train: {len(X_train)} rows ({X_train.index[0]} to {X_train.index[-1]})")
    print(f"  Test: {len(X_test)} rows ({X_test.index[0]} to {X_test.index[-1]})")
    
    # ============================================
    # TRAIN XGBOOST MODEL
    # ============================================
    import xgboost as xgb
    from sklearn.metrics import mean_absolute_error, r2_score
    
    print("\nTraining XGBoost model...")
    
    model = xgb.XGBRegressor(
        n_estimators=300,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        early_stopping_rounds=20,
        eval_metric=['mae', 'rmse']
    )
    
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=False
    )
    
    # Evaluate
    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    print(f"\nModel Performance:")
    print(f"  MAE: Rs. {mae:.2f}/kg")
    print(f"  R² Score: {r2:.4f}")
    print(f"  Accuracy within Rs.20: {np.mean(np.abs(y_test - y_pred) < 20)*100:.1f}%")
    
    # ============================================
    # FEATURE IMPORTANCE
    # ============================================
    print("\nTop 10 Feature Importance:")
    importance = pd.DataFrame({
        'feature': X.columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False).head(10)
    
    for idx, row in importance.iterrows():
        print(f"  {row['feature']}: {row['importance']:.3f}")
    
    # ============================================
    # SAVE MODEL
    # ============================================
    joblib.dump(model, '../results/preprocessing/xgboost_tea_pricing_model.pkl')
    print("\nModel saved: ../results/preprocessing/xgboost_tea_pricing_model.pkl")
    
    # ============================================
    # PREDICTION FUNCTION (For your app)
    # ============================================
    def predict_single_batch(image_grade, confidence, user_inputs, market_data):
        """
        Predict price for a single batch
        
        Args:
            image_grade: "BOPF", "BOP", etc.
            confidence: 0.94
            user_inputs: {'color':1, 'aroma':0.5, 'age':0.5, 'quantity':500}
            market_data: {'market_price':1143, 'rainfall_mm':125, 
                         'season':'Peak', 'exchange_rate':332}
        """
        # Load model and encoders
        model = joblib.load('../results/preprocessing/xgboost_tea_pricing_model.pkl')
        grade_encoder = joblib.load('../results/preprocessing/grade_encoder.pkl')
        season_encoder = joblib.load('../results/preprocessing/season_encoder.pkl')
        feature_names = joblib.load('../results/preprocessing/feature_names.pkl')
        
        # Create single row dataframe
        row = {
            'grade_encoded': grade_encoder[image_grade],
            'confidence': confidence,
            'color': user_inputs['color'],
            'aroma': user_inputs['aroma'],
            'age': user_inputs['age'],
            'quantity_kg': user_inputs['quantity'],
            'market_price': market_data['market_price'],
            'rainfall_mm': market_data['rainfall_mm'],
            'exchange_rate': market_data['exchange_rate'],
            'season_encoded': season_encoder[market_data['season']]
        }
        
        # Add derived features (simplified for single prediction)
        row['quality_score'] = (row['color'] + row['aroma'] + row['age']) / 3
        row['grade_quality_interaction'] = row['grade_encoded'] * row['quality_score']
        row['market_rainfall_interaction'] = row['market_price'] * (row['rainfall_mm'] / 100)
        
        # Set default values for other features
        row['price_momentum_3d'] = 0
        row['price_momentum_7d'] = 0
        row['price_ma_7d'] = row['market_price']
        row['price_std_7d'] = 0
        row['rainfall_lag_7d'] = row['rainfall_mm']
        row['rainfall_lag_14d'] = row['rainfall_mm']
        row['rainfall_lag_30d'] = row['rainfall_mm']
        row['rainfall_cum_30d'] = row['rainfall_mm'] * 30
        row['exchange_momentum_7d'] = 0
        row['month_sin'] = np.sin(2 * np.pi * datetime.now().month / 12)
        row['month_cos'] = np.cos(2 * np.pi * datetime.now().month / 12)
        
        # Create DataFrame with correct feature order
        import pandas as pd
        X_pred = pd.DataFrame([row])[feature_names]
        
        # Predict
        price = model.predict(X_pred)[0]
        
        return round(float(price[0]), 2)

# ============================================
# DATA AUGMENTATION (LIGHT - ANTI-OVERFITTING)
# ============================================
def augment_training_data(X, y, num_copies=1, noise_level=0.08):
    """
    Creates ONE noisy copy to prevent memorization (Light Augmentation).
    """
    print(f"\nLIGHT AUGMENTATION: Generating {num_copies} noisy copy per sample...")
    
    X_augmented = [X]
    y_augmented = [y]
    
    # Identify numeric columns for noise injection
    numeric_cols = ['market_price', 'rainfall_mm', 'quantity_kg']
    
    valid_cols = [c for c in numeric_cols if c in X.columns]
    
    for i in range(num_copies):
        X_copy = X.copy()
        y_copy = y.copy()
        
        # Inject noise into features
        for col in valid_cols:
            std = X[col].std()
            noise = np.random.normal(0, std * noise_level, size=len(X))
            X_copy[col] += noise
            
        # Inject slight noise into target
        y_noise = np.random.normal(0, y.std() * 0.02, size=len(y))
        y_copy += y_noise
        
        X_augmented.append(X_copy)
        y_augmented.append(y_copy)
    
    X_final = pd.concat(X_augmented, axis=0).reset_index(drop=True)
    y_final = pd.concat(y_augmented, axis=0).reset_index(drop=True)
    
    print(f"Data expanded: {len(X)} -> {len(X_final)} rows")
    return X_final, y_final
    
    print("\n Pipeline ready for predictions!")