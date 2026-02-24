import joblib
import numpy as np
from typing import Dict, Any, Optional
import logging
from pathlib import Path
from app.config import settings

logger = logging.getLogger(__name__)

class MLService:
    """Machine Learning service for soil health prediction with 7 features"""
    
    _instance = None
    _model = None
    _expected_features = 7  # Set to 7 for N, P, K, pH, EC, Temperature, Humidity
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if self._model is None:
            try:
                self.load_model()
                logger.info(f"✅ ML Service initialized with {self._expected_features} features")
            except Exception as e:
                logger.warning(f"Could not load model: {e}")
                logger.warning("Using rule-based fallback prediction")
                self._model = None
    
    def load_model(self):
        """Load the ML model from disk"""
        try:
            model_path = Path(settings.MODEL_PATH)
            if not model_path.exists():
                raise FileNotFoundError(f"Model not found at {model_path}")
            
            self._model = joblib.load(model_path)
            logger.info(f"✅ Model loaded from {model_path}")
            
            # Verify model expects 7 features
            if hasattr(self._model, 'n_features_in_'):
                if self._model.n_features_in_ != 7:
                    logger.warning(f"Model expects {self._model.n_features_in_} features, but code expects 7")
            
        except Exception as e:
            logger.error(f"❌ Failed to load model: {e}")
            self._model = None
    
    def prepare_features(self, data: Dict[str, Any]) -> np.ndarray:
        """
        Prepare 7 features array: N, P, K, pH, EC, Temperature, Humidity
        """
        features = [
            float(data["N"]),
            float(data["P"]),
            float(data["K"]),
            float(data["pH"]),
            float(data.get("EC", 0.5)),  # Default if not provided
            float(data.get("temperature", 25.0)),
            float(data.get("humidity", 60.0))
        ]
        
        logger.debug(f"Prepared 7 features: {features}")
        return np.array([features])
    
    def predict(self, data: Dict[str, Any]) -> str:
        """
        Predict soil health based on 7 sensor features
        
        Args:
            data: Dictionary containing N, P, K, pH, EC, temperature, humidity
            
        Returns:
            Predicted soil health status (Good, Fair, Poor)
        """
        try:
            if self._model is not None:
                # Prepare 7 features
                features = self.prepare_features(data)
                
                # Make prediction
                prediction = self._model.predict(features)
                
                # Map prediction to human-readable format
                # Adjust this mapping based on your model's output
                prediction_map = {0: "Poor", 1: "Fair", 2: "Good"}
                
                # Handle different prediction formats
                if isinstance(prediction[0], (int, np.integer)):
                    result = prediction_map.get(int(prediction[0]), "Unknown")
                elif isinstance(prediction[0], (float, np.floating)):
                    # If model outputs probabilities or continuous values
                    if prediction[0] < 0.33:
                        result = "Poor"
                    elif prediction[0] < 0.66:
                        result = "Fair"
                    else:
                        result = "Good"
                else:
                    result = str(prediction[0])
                
                logger.info(f"✅ ML Prediction: {result} for features: {features[0]}")
                return result
            else:
                # Fallback to rule-based prediction
                logger.warning("Using rule-based fallback prediction")
                return self._rule_based_prediction(data)
                
        except Exception as e:
            logger.error(f"❌ Prediction failed: {e}")
            logger.error(f"Data received: {data}")
            return self._rule_based_prediction(data)
    
    def _rule_based_prediction(self, data: Dict[str, Any]) -> str:
        """Rule-based fallback prediction using all 7 features"""
        n = data["N"]
        p = data["P"]
        k = data["K"]
        ph = data["pH"]
        ec = data.get("EC", 0.5)
        temp = data.get("temperature", 25.0)
        humidity = data.get("humidity", 60.0)
        
        # Simple scoring system (adjust thresholds based on your domain knowledge)
        score = 0
        
        # Nitrogen (optimal 80-200)
        if 80 <= n <= 200:
            score += 2
        elif 50 <= n <= 250:
            score += 1
        
        # Phosphorus (optimal >25)
        if p >= 25:
            score += 2
        elif p >= 15:
            score += 1
        
        # Potassium (optimal >150)
        if k >= 150:
            score += 2
        elif k >= 100:
            score += 1
        
        # pH (optimal 5.5-6.5)
        if 5.5 <= ph <= 6.5:
            score += 2
        elif 5.0 <= ph <= 7.0:
            score += 1
        
        # EC - Electrical Conductivity (optimal 0.5-1.5 dS/m)
        if 0.5 <= ec <= 1.5:
            score += 2
        elif 0.3 <= ec <= 2.0:
            score += 1
        
        # Temperature (optimal 20-30°C)
        if 20 <= temp <= 30:
            score += 2
        elif 15 <= temp <= 35:
            score += 1
        
        # Humidity (optimal 60-80%)
        if 60 <= humidity <= 80:
            score += 2
        elif 50 <= humidity <= 90:
            score += 1
        
        # Determine soil health (max score = 14)
        if score >= 11:
            return "Good"
        elif score >= 7:
            return "Fair"
        else:
            return "Poor"


# Create singleton instance
try:
    ml_service = MLService()
except Exception as e:
    logger = logging.getLogger(__name__)
    logger.error(f"Failed to create ML service: {e}")
    ml_service = None

def predict_soil_health(data: Dict[str, Any]) -> str:
    """Convenience function for soil health prediction with 7 features"""
    if ml_service is not None:
        return ml_service.predict(data)
    else:
        # Ultimate fallback if service not available
        n, p, k, ph = data["N"], data["P"], data["K"], data["pH"]
        ec = data.get("EC", 0.5)
        temp = data.get("temperature", 25.0)
        humidity = data.get("humidity", 60.0)
        
        # Very simple fallback
        good_count = 0
        if 80 <= n <= 200: good_count += 1
        if p >= 25: good_count += 1
        if k >= 150: good_count += 1
        if 5.5 <= ph <= 6.5: good_count += 1
        if 0.5 <= ec <= 1.5: good_count += 1
        if 20 <= temp <= 30: good_count += 1
        if 60 <= humidity <= 80: good_count += 1
        
        if good_count >= 6:
            return "Good"
        elif good_count >= 4:
            return "Fair"
        else:
            return "Poor"