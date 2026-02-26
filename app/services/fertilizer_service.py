from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

class FertilizerRecommender:
    """Service for fertilizer recommendations based on soil parameters"""
    
    # Optimal ranges for tea cultivation
    OPTIMAL_RANGES = {
        'N': {'min': 20, 'max': 30, 'unit': 'mg/kg'},
        'P': {'min': 10, 'max': 20, 'unit': 'mg/kg'},
        'K': {'min': 20, 'max': 30, 'unit': 'mg/kg'},
        'pH': {'min': 4.5, 'max': 5.5, 'unit': ''},
        'EC': {'min': 0.1, 'max': 0.5, 'unit': 'dS/m'},  # Optional
        'temperature': {'min': 18, 'max': 25, 'unit': '°C'},  # Optional
        'humidity': {'min': 40, 'max': 70, 'unit': '%'}  # Optional
    }
    
    # Recommendation messages
    RECOMMENDATIONS = {
        # Deficiency messages
        'N_low': "Apply nitrogen fertilizer (Urea 50kg/ha)",
        'P_low': "Apply phosphorus fertilizer (SSP 40kg/ha)",
        'K_low': "Apply potassium fertilizer (MOP 60kg/ha)",
        'pH_low': "Apply lime to increase pH (1 ton/ha)",
        'EC_low': "Consider organic matter addition",
        'temp_low': "Soil temperature low - consider mulching",
        'humidity_low': "Irrigation needed - humidity too low",
        
        # Excess messages
        'N_high': "⚠️ REDUCE nitrogen - excess causing poor health",
        'P_high': "⚠️ REDUCE phosphorus - excess causing imbalance",
        'K_high': "⚠️ REDUCE potassium - excess causing poor health",
        'pH_high': "Apply sulfur to lower pH",
        'EC_high': "⚠️ High salinity - improve drainage, leach soil",
        'temp_high': "⚠️ Temperature too high - provide shade",
        'humidity_high': "⚠️ Humidity too high - improve ventilation",
        
        # Maintenance
        'maintain': "Maintain current practice",
        'soil_good': "Soil health is optimal"
    }

    @classmethod
    def get_recommendations(cls, N: float, P: float, K: float, pH: float, 
                           EC: float = None, temperature: float = None, 
                           humidity: float = None, soil_health: str = None) -> List[str]:
        """
        Get fertilizer recommendations based on soil parameters
        Now handles both deficiencies AND excesses
        """
        recommendations = []
        
        try:
            # ===== NITROGEN recommendations =====
            if N < cls.OPTIMAL_RANGES['N']['min']:
                recommendations.append(cls.RECOMMENDATIONS['N_low'])
                logger.debug(f"Nitrogen deficient: {N} < {cls.OPTIMAL_RANGES['N']['min']}")
            elif N > cls.OPTIMAL_RANGES['N']['max']:
                recommendations.append(cls.RECOMMENDATIONS['N_high'])
                logger.debug(f"Nitrogen excess: {N} > {cls.OPTIMAL_RANGES['N']['max']}")

            # ===== PHOSPHORUS recommendations =====
            if P < cls.OPTIMAL_RANGES['P']['min']:
                recommendations.append(cls.RECOMMENDATIONS['P_low'])
                logger.debug(f"Phosphorus deficient: {P} < {cls.OPTIMAL_RANGES['P']['min']}")
            elif P > cls.OPTIMAL_RANGES['P']['max']:
                recommendations.append(cls.RECOMMENDATIONS['P_high'])
                logger.debug(f"Phosphorus excess: {P} > {cls.OPTIMAL_RANGES['P']['max']}")

            # ===== POTASSIUM recommendations =====
            if K < cls.OPTIMAL_RANGES['K']['min']:
                recommendations.append(cls.RECOMMENDATIONS['K_low'])
                logger.debug(f"Potassium deficient: {K} < {cls.OPTIMAL_RANGES['K']['min']}")
            elif K > cls.OPTIMAL_RANGES['K']['max']:
                recommendations.append(cls.RECOMMENDATIONS['K_high'])
                logger.debug(f"Potassium excess: {K} > {cls.OPTIMAL_RANGES['K']['max']}")

            # ===== pH recommendations =====
            if pH < cls.OPTIMAL_RANGES['pH']['min']:
                recommendations.append(cls.RECOMMENDATIONS['pH_low'])
                logger.debug(f"pH too low: {pH} < {cls.OPTIMAL_RANGES['pH']['min']}")
            elif pH > cls.OPTIMAL_RANGES['pH']['max']:
                recommendations.append(cls.RECOMMENDATIONS['pH_high'])
                logger.debug(f"pH too high: {pH} > {cls.OPTIMAL_RANGES['pH']['max']}")

            # ===== EC recommendations (if provided) =====
            if EC is not None:
                if EC < cls.OPTIMAL_RANGES['EC']['min']:
                    recommendations.append(cls.RECOMMENDATIONS['EC_low'])
                elif EC > cls.OPTIMAL_RANGES['EC']['max']:
                    recommendations.append(cls.RECOMMENDATIONS['EC_high'])

            # ===== Temperature recommendations (if provided) =====
            if temperature is not None:
                if temperature < cls.OPTIMAL_RANGES['temperature']['min']:
                    recommendations.append(cls.RECOMMENDATIONS['temp_low'])
                elif temperature > cls.OPTIMAL_RANGES['temperature']['max']:
                    recommendations.append(cls.RECOMMENDATIONS['temp_high'])

            # ===== Humidity recommendations (if provided) =====
            if humidity is not None:
                if humidity < cls.OPTIMAL_RANGES['humidity']['min']:
                    recommendations.append(cls.RECOMMENDATIONS['humidity_low'])
                elif humidity > cls.OPTIMAL_RANGES['humidity']['max']:
                    recommendations.append(cls.RECOMMENDATIONS['humidity_high'])

            # ===== If ML says Poor but no specific recommendations, add general advice =====
            if soil_health == "Poor" and not recommendations:
                recommendations.append("⚠️ Soil health is poor - conduct detailed soil analysis")
                recommendations.append("Consider soil amendment and organic matter addition")
            
            # ===== If ML says Good and no issues, add maintenance =====
            elif soil_health == "Good" and not recommendations:
                recommendations.append(cls.RECOMMENDATIONS['soil_good'])
            
            # ===== Default recommendation if nothing else =====
            elif not recommendations:
                recommendations.append(cls.RECOMMENDATIONS['maintain'])

        except Exception as e:
            logger.error(f"Error generating recommendations: {e}")
            recommendations.append(cls.RECOMMENDATIONS['maintain'])

        return recommendations

# Update the convenience function to include all parameters
def fertilizer_recommendation(N: float, P: float, K: float, pH: float, 
                             soil_health: str, EC: float = None, 
                             temperature: float = None, humidity: float = None) -> List[str]:
    return FertilizerRecommender.get_recommendations(N, P, K, pH, EC, temperature, humidity, soil_health)