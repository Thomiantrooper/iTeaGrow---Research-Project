from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

class FertilizerRecommender:
    """Service for fertilizer recommendations based on soil parameters"""
    
    # Recommendation thresholds
    THRESHOLDS = {
        'N': {'low': 80, 'high': 200},
        'P': {'low': 25},
        'K': {'low': 150},
        'pH': {'low': 4.5, 'high': 6.5}
    }
    
    # Recommendation messages
    RECOMMENDATIONS = {
        'N_low': "Apply_Urea_50kg_per_ha",
        'N_high': "Reduce_Nitrogen_Input",
        'P_low': "Apply_SSP_40kg_per_ha",
        'K_low': "Apply_MOP_60kg_per_ha",
        'pH_low': "Apply_Lime_1ton_per_ha",
        'pH_high': "Apply_Sulfur",
        'soil_good': "No_Immediate_Fertilizer",
        'maintain': "Maintain_Current_Practice"
    }

    @classmethod
    def get_recommendations(cls, N: float, P: float, K: float, pH: float, soil_health: str) -> List[str]:
        """
        Get fertilizer recommendations based on soil parameters
        
        Args:
            N: Nitrogen level
            P: Phosphorus level
            K: Potassium level
            pH: pH level
            soil_health: Predicted soil health status
            
        Returns:
            List of fertilizer recommendations
        """
        recommendations = []
        
        try:
            # Nitrogen recommendations
            if N < cls.THRESHOLDS['N']['low']:
                recommendations.append(cls.RECOMMENDATIONS['N_low'])
                logger.debug(f"Nitrogen low: {N} < {cls.THRESHOLDS['N']['low']}")
            elif N > cls.THRESHOLDS['N']['high']:
                recommendations.append(cls.RECOMMENDATIONS['N_high'])
                logger.debug(f"Nitrogen high: {N} > {cls.THRESHOLDS['N']['high']}")

            # Phosphorus recommendations
            if P < cls.THRESHOLDS['P']['low']:
                recommendations.append(cls.RECOMMENDATIONS['P_low'])
                logger.debug(f"Phosphorus low: {P} < {cls.THRESHOLDS['P']['low']}")

            # Potassium recommendations
            if K < cls.THRESHOLDS['K']['low']:
                recommendations.append(cls.RECOMMENDATIONS['K_low'])
                logger.debug(f"Potassium low: {K} < {cls.THRESHOLDS['K']['low']}")

            # pH recommendations
            if pH < cls.THRESHOLDS['pH']['low']:
                recommendations.append(cls.RECOMMENDATIONS['pH_low'])
                logger.debug(f"pH low: {pH} < {cls.THRESHOLDS['pH']['low']}")
            elif pH > cls.THRESHOLDS['pH']['high']:
                recommendations.append(cls.RECOMMENDATIONS['pH_high'])
                logger.debug(f"pH high: {pH} > {cls.THRESHOLDS['pH']['high']}")

            # Soil health based recommendation
            if soil_health.lower() == "good":
                recommendations.append(cls.RECOMMENDATIONS['soil_good'])

            # Default recommendation
            if not recommendations:
                recommendations.append(cls.RECOMMENDATIONS['maintain'])

        except Exception as e:
            logger.error(f"Error generating recommendations: {e}")
            recommendations.append(cls.RECOMMENDATIONS['maintain'])

        return recommendations

# Convenience function
def fertilizer_recommendation(N: float, P: float, K: float, pH: float, soil_health: str) -> List[str]:
    return FertilizerRecommender.get_recommendations(N, P, K, pH, soil_health)