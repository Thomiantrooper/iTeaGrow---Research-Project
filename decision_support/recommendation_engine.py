"""
Rule-Based Decision Support System for Tea Leaf Diseases
==========================================================
Generates disease-specific preventive and corrective recommendations
based on visual detection and environmental context.
"""

from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DiseaseType(Enum):
    """Types of tea leaf diseases."""
    HEALTHY = "healthy"
    RED_RUST = "red_rust"
    BLISTER_BLIGHT = "blister_blight"


class SeverityLevel(Enum):
    """Disease severity levels."""
    NONE = 0
    LOW = 1
    MODERATE = 2
    HIGH = 3
    SEVERE = 4


class RecommendationType(Enum):
    """Types of recommendations."""
    PREVENTIVE = "preventive"
    CORRECTIVE = "corrective"
    MONITORING = "monitoring"
    EMERGENCY = "emergency"


class Priority(Enum):
    """Recommendation priority levels."""
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    URGENT = 4


@dataclass
class EnvironmentalContext:
    """Environmental conditions context."""
    temperature: float
    humidity: float
    soil_moisture: float
    light_intensity: float
    is_rainy_season: bool = False
    recent_rainfall: bool = False

    def to_dict(self) -> Dict:
        return {
            'temperature': self.temperature,
            'humidity': self.humidity,
            'soil_moisture': self.soil_moisture,
            'light_intensity': self.light_intensity,
            'is_rainy_season': self.is_rainy_season,
            'recent_rainfall': self.recent_rainfall
        }


@dataclass
class DetectionContext:
    """Disease detection context."""
    disease_type: DiseaseType
    confidence: float
    affected_count: int
    total_leaves: int
    detection_time: datetime

    @property
    def infection_rate(self) -> float:
        """Calculate infection rate percentage."""
        if self.total_leaves == 0:
            return 0
        return (self.affected_count / self.total_leaves) * 100

    @property
    def severity(self) -> SeverityLevel:
        """Determine severity based on infection rate and confidence."""
        rate = self.infection_rate

        if rate == 0:
            return SeverityLevel.NONE
        elif rate < 5:
            return SeverityLevel.LOW
        elif rate < 15:
            return SeverityLevel.MODERATE
        elif rate < 30:
            return SeverityLevel.HIGH
        else:
            return SeverityLevel.SEVERE


@dataclass
class Recommendation:
    """Single recommendation."""
    id: str
    type: RecommendationType
    priority: Priority
    title: str
    description: str
    actions: List[str]
    timing: str
    disease: DiseaseType
    language_key: str = ""

    def to_dict(self) -> Dict:
        return {
            'id': self.id,
            'type': self.type.value,
            'priority': self.priority.value,
            'title': self.title,
            'description': self.description,
            'actions': self.actions,
            'timing': self.timing,
            'disease': self.disease.value
        }


@dataclass
class RecommendationReport:
    """Complete recommendation report."""
    timestamp: datetime
    disease_detected: DiseaseType
    severity: SeverityLevel
    environmental_risk: str
    recommendations: List[Recommendation]
    summary: str

    def to_dict(self) -> Dict:
        return {
            'timestamp': self.timestamp.isoformat(),
            'disease_detected': self.disease_detected.value,
            'severity': self.severity.name,
            'environmental_risk': self.environmental_risk,
            'recommendations': [r.to_dict() for r in self.recommendations],
            'summary': self.summary,
            'total_recommendations': len(self.recommendations)
        }


class RedRustRules:
    """Rule engine for Red Rust disease recommendations."""

    @staticmethod
    def get_preventive_recommendations(
        env: EnvironmentalContext
    ) -> List[Recommendation]:
        """Generate preventive recommendations for Red Rust."""
        recommendations = []

        # Shade management
        if env.light_intensity < 500:
            recommendations.append(Recommendation(
                id="RR_P_001",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.MEDIUM,
                title="Adjust Shade Management",
                description="Excessive shade creates favorable conditions for Red Rust development.",
                actions=[
                    "Prune shade trees to allow more light penetration",
                    "Maintain optimal shade level of 40-60%",
                    "Remove lower branches of shade trees"
                ],
                timing="Within next 2 weeks",
                disease=DiseaseType.RED_RUST,
                language_key="shade_management"
            ))

        # Humidity control
        if env.humidity > 70:
            recommendations.append(Recommendation(
                id="RR_P_002",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.MEDIUM,
                title="Improve Air Circulation",
                description="High humidity promotes Red Rust spread. Improve ventilation.",
                actions=[
                    "Prune tea bushes to improve air flow",
                    "Maintain proper spacing between bushes",
                    "Remove excess growth from bush center"
                ],
                timing="During next pruning cycle",
                disease=DiseaseType.RED_RUST,
                language_key="air_circulation"
            ))

        # Preventive spray
        if 25 <= env.temperature <= 30 and env.humidity >= 70:
            recommendations.append(Recommendation(
                id="RR_P_003",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.HIGH,
                title="Apply Preventive Fungicide",
                description="Environmental conditions favor Red Rust. Apply preventive treatment.",
                actions=[
                    "Apply copper-based fungicide spray (copper oxychloride 0.25%)",
                    "Ensure complete coverage of foliage",
                    "Spray early morning or late evening",
                    "Repeat after 14 days if conditions persist"
                ],
                timing="Within next 3 days",
                disease=DiseaseType.RED_RUST,
                language_key="preventive_spray"
            ))

        # General monitoring
        recommendations.append(Recommendation(
            id="RR_P_004",
            type=RecommendationType.MONITORING,
            priority=Priority.LOW,
            title="Regular Monitoring",
            description="Regular inspection helps early detection of Red Rust.",
            actions=[
                "Inspect plants weekly during high-risk periods",
                "Focus on older leaves and shaded areas",
                "Look for orange-colored spots on leaf surface",
                "Report any suspicious symptoms immediately"
            ],
            timing="Ongoing",
            disease=DiseaseType.RED_RUST,
            language_key="monitoring"
        ))

        return recommendations

    @staticmethod
    def get_corrective_recommendations(
        detection: DetectionContext,
        env: EnvironmentalContext
    ) -> List[Recommendation]:
        """Generate corrective recommendations based on detection severity."""
        recommendations = []
        severity = detection.severity

        if severity == SeverityLevel.LOW:
            recommendations.append(Recommendation(
                id="RR_C_001",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.MEDIUM,
                title="Remove Infected Leaves",
                description="Early-stage infection detected. Remove affected leaves to prevent spread.",
                actions=[
                    "Carefully remove all visibly infected leaves",
                    "Collect and dispose of removed leaves away from plantation",
                    "Do not compost infected material",
                    "Wash hands and tools after handling"
                ],
                timing="Immediately",
                disease=DiseaseType.RED_RUST,
                language_key="remove_leaves"
            ))

        if severity in [SeverityLevel.MODERATE, SeverityLevel.HIGH]:
            recommendations.append(Recommendation(
                id="RR_C_002",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.HIGH,
                title="Apply Curative Fungicide Treatment",
                description="Significant infection detected. Apply targeted fungicide treatment.",
                actions=[
                    "Apply copper oxychloride spray at 0.5% concentration",
                    "Ensure thorough coverage of all infected areas",
                    "Repeat application after 7-10 days",
                    "Alternatively, use lime sulphur spray (1:40 dilution)"
                ],
                timing="Within 24 hours",
                disease=DiseaseType.RED_RUST,
                language_key="curative_spray"
            ))

            recommendations.append(Recommendation(
                id="RR_C_003",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.MEDIUM,
                title="Reduce Nitrogen Fertilization",
                description="Excess nitrogen promotes disease susceptibility.",
                actions=[
                    "Reduce nitrogen application by 20-30%",
                    "Avoid fertilizer application during active infection",
                    "Resume normal fertilization after disease is controlled"
                ],
                timing="Until infection subsides",
                disease=DiseaseType.RED_RUST,
                language_key="reduce_nitrogen"
            ))

        if severity == SeverityLevel.SEVERE:
            recommendations.append(Recommendation(
                id="RR_C_004",
                type=RecommendationType.EMERGENCY,
                priority=Priority.URGENT,
                title="Emergency Disease Control",
                description="Severe infection requires immediate action to prevent major loss.",
                actions=[
                    "Remove and destroy severely infected branches",
                    "Apply systemic fungicide (hexaconazole 5% EC at 2ml/L)",
                    "Isolate affected area from healthy sections",
                    "Contact agricultural extension officer",
                    "Consider skipping harvest in affected area"
                ],
                timing="Immediately",
                disease=DiseaseType.RED_RUST,
                language_key="emergency_control"
            ))

        # Monitoring after treatment
        recommendations.append(Recommendation(
            id="RR_C_005",
            type=RecommendationType.MONITORING,
            priority=Priority.HIGH,
            title="Intensive Post-Treatment Monitoring",
            description="Monitor treated areas closely for disease recurrence.",
            actions=[
                "Inspect treated areas every 3 days",
                "Document progress with photographs",
                "Apply follow-up treatment if new symptoms appear",
                "Track environmental conditions daily"
            ],
            timing="For next 2-3 weeks",
            disease=DiseaseType.RED_RUST,
            language_key="post_treatment_monitoring"
        ))

        return recommendations


class BlisterBlightRules:
    """Rule engine for Blister Blight disease recommendations."""

    @staticmethod
    def get_preventive_recommendations(
        env: EnvironmentalContext
    ) -> List[Recommendation]:
        """Generate preventive recommendations for Blister Blight."""
        recommendations = []

        # High humidity warning
        if env.humidity >= 85:
            recommendations.append(Recommendation(
                id="BB_P_001",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.HIGH,
                title="High Humidity Alert",
                description="Very high humidity creates ideal conditions for Blister Blight.",
                actions=[
                    "Apply protective copper fungicide spray immediately",
                    "Avoid plucking during wet conditions",
                    "Ensure good drainage in the field",
                    "Increase monitoring of young leaves"
                ],
                timing="Within 24 hours",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="high_humidity_alert"
            ))

        # Cool temperature + high humidity
        if 15 <= env.temperature <= 25 and env.humidity >= 75:
            recommendations.append(Recommendation(
                id="BB_P_002",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.MEDIUM,
                title="Apply Protective Fungicide",
                description="Cool, humid conditions favor Blister Blight development.",
                actions=[
                    "Apply copper-based fungicide (copper hydroxide 0.25%)",
                    "Focus on young shoots and tender leaves",
                    "Spray before expected rainfall",
                    "Repeat every 7-10 days during high-risk period"
                ],
                timing="Before next rainfall",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="protective_spray"
            ))

        # Rainy season preparation
        if env.is_rainy_season or env.recent_rainfall:
            recommendations.append(Recommendation(
                id="BB_P_003",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.HIGH,
                title="Monsoon Season Protection",
                description="Rainy season significantly increases Blister Blight risk.",
                actions=[
                    "Apply systemic fungicide before monsoon onset",
                    "Increase plucking frequency to remove young leaves",
                    "Maintain drainage channels clear",
                    "Reduce shade to minimize leaf wetness duration"
                ],
                timing="Before monsoon season",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="monsoon_protection"
            ))

        # Drainage maintenance
        if env.soil_moisture > 65:
            recommendations.append(Recommendation(
                id="BB_P_004",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.MEDIUM,
                title="Improve Field Drainage",
                description="Waterlogged conditions promote disease development.",
                actions=[
                    "Clear and maintain drainage channels",
                    "Create additional drainage if needed",
                    "Avoid over-irrigation",
                    "Add mulch to prevent soil splash"
                ],
                timing="As soon as possible",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="drainage"
            ))

        return recommendations

    @staticmethod
    def get_corrective_recommendations(
        detection: DetectionContext,
        env: EnvironmentalContext
    ) -> List[Recommendation]:
        """Generate corrective recommendations based on detection severity."""
        recommendations = []
        severity = detection.severity

        if severity == SeverityLevel.LOW:
            recommendations.append(Recommendation(
                id="BB_C_001",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.MEDIUM,
                title="Remove Infected Shoots",
                description="Early infection detected. Remove affected young shoots.",
                actions=[
                    "Pluck and remove infected young leaves and shoots",
                    "Increase plucking frequency to 5-7 day rounds",
                    "Destroy infected material away from field",
                    "Apply contact fungicide after removal"
                ],
                timing="Immediately",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="remove_shoots"
            ))

        if severity in [SeverityLevel.MODERATE, SeverityLevel.HIGH]:
            recommendations.append(Recommendation(
                id="BB_C_002",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.HIGH,
                title="Apply Systemic Fungicide",
                description="Moderate to severe infection requires systemic treatment.",
                actions=[
                    "Apply hexaconazole (5% EC at 1ml/L) or propiconazole (25% EC at 0.5ml/L)",
                    "Ensure complete wetting of leaf surface",
                    "Apply in early morning when leaves are dry",
                    "Repeat after 10-14 days"
                ],
                timing="Within 24 hours",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="systemic_fungicide"
            ))

            recommendations.append(Recommendation(
                id="BB_C_003",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.MEDIUM,
                title="Suspend Plucking Temporarily",
                description="Allow fungicide to take effect before harvesting.",
                actions=[
                    "Stop plucking in affected area for 7-10 days",
                    "Mark treated areas clearly",
                    "Resume plucking only after waiting period",
                    "Check pre-harvest interval of used fungicide"
                ],
                timing="For 7-10 days after treatment",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="suspend_plucking"
            ))

        if severity == SeverityLevel.SEVERE:
            recommendations.append(Recommendation(
                id="BB_C_004",
                type=RecommendationType.EMERGENCY,
                priority=Priority.URGENT,
                title="Emergency Blister Blight Control",
                description="Severe outbreak requires emergency measures.",
                actions=[
                    "Apply combination of systemic and contact fungicides",
                    "Remove severely infected bushes from production",
                    "Implement strict sanitation measures",
                    "Contact Tea Research Institute for assistance",
                    "Document outbreak extent for reporting"
                ],
                timing="Immediately",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="emergency_blight"
            ))

        # Weather-based follow-up
        if env.recent_rainfall:
            recommendations.append(Recommendation(
                id="BB_C_005",
                type=RecommendationType.CORRECTIVE,
                priority=Priority.HIGH,
                title="Post-Rain Treatment",
                description="Recent rainfall may have washed off previous treatments.",
                actions=[
                    "Reapply fungicide if rain occurred within 6 hours of spraying",
                    "Use sticker/spreader additive with fungicide",
                    "Time application for dry weather forecast",
                    "Consider rain-fast formulations"
                ],
                timing="After rainfall stops",
                disease=DiseaseType.BLISTER_BLIGHT,
                language_key="post_rain"
            ))

        return recommendations


class HealthyLeafRules:
    """Rule engine for healthy leaf maintenance recommendations."""

    @staticmethod
    def get_preventive_recommendations(
        env: EnvironmentalContext
    ) -> List[Recommendation]:
        """Generate maintenance recommendations for healthy plants."""
        recommendations = []

        # General monitoring
        recommendations.append(Recommendation(
            id="HL_P_001",
            type=RecommendationType.MONITORING,
            priority=Priority.LOW,
            title="Continue Regular Monitoring",
            description="Maintain regular inspection schedule for early disease detection.",
            actions=[
                "Inspect plants weekly during favorable disease conditions",
                "Pay attention to young leaves and shaded areas",
                "Record any unusual symptoms",
                "Use mobile app for regular photo documentation"
            ],
            timing="Ongoing",
            disease=DiseaseType.HEALTHY,
            language_key="regular_monitoring"
        ))

        # Optimal management
        recommendations.append(Recommendation(
            id="HL_P_002",
            type=RecommendationType.PREVENTIVE,
            priority=Priority.LOW,
            title="Maintain Optimal Growing Conditions",
            description="Healthy plants are more resistant to disease.",
            actions=[
                "Follow recommended fertilization schedule",
                "Maintain proper shade management (40-60%)",
                "Ensure adequate drainage",
                "Practice integrated pest management"
            ],
            timing="Ongoing",
            disease=DiseaseType.HEALTHY,
            language_key="optimal_conditions"
        ))

        # High-risk period warning
        if (15 <= env.temperature <= 30 and env.humidity >= 75):
            recommendations.append(Recommendation(
                id="HL_P_003",
                type=RecommendationType.PREVENTIVE,
                priority=Priority.MEDIUM,
                title="High-Risk Period Alert",
                description="Current conditions may become favorable for disease development.",
                actions=[
                    "Increase monitoring frequency",
                    "Prepare preventive fungicide",
                    "Check weather forecast for prolonged humidity",
                    "Ensure quick response capability"
                ],
                timing="Current period",
                disease=DiseaseType.HEALTHY,
                language_key="high_risk_period"
            ))

        return recommendations


class RecommendationEngine:
    """
    Main engine for generating disease management recommendations.
    Combines visual detection with environmental context.
    """

    def __init__(self):
        self.red_rust_rules = RedRustRules()
        self.blister_blight_rules = BlisterBlightRules()
        self.healthy_rules = HealthyLeafRules()

    def generate_recommendations(
        self,
        detection: DetectionContext,
        environmental: EnvironmentalContext
    ) -> RecommendationReport:
        """
        Generate comprehensive recommendations based on detection and environment.

        Args:
            detection: Disease detection context
            environmental: Environmental conditions

        Returns:
            Complete recommendation report
        """
        recommendations = []

        # Get disease-specific recommendations
        if detection.disease_type == DiseaseType.RED_RUST:
            recommendations.extend(
                self.red_rust_rules.get_corrective_recommendations(detection, environmental)
            )
            recommendations.extend(
                self.red_rust_rules.get_preventive_recommendations(environmental)
            )

        elif detection.disease_type == DiseaseType.BLISTER_BLIGHT:
            recommendations.extend(
                self.blister_blight_rules.get_corrective_recommendations(detection, environmental)
            )
            recommendations.extend(
                self.blister_blight_rules.get_preventive_recommendations(environmental)
            )

        else:  # Healthy
            recommendations.extend(
                self.healthy_rules.get_preventive_recommendations(environmental)
            )

        # Sort by priority (highest first)
        recommendations.sort(key=lambda r: r.priority.value, reverse=True)

        # Determine environmental risk level
        env_risk = self._assess_environmental_risk(environmental)

        # Generate summary
        summary = self._generate_summary(detection, recommendations, env_risk)

        return RecommendationReport(
            timestamp=datetime.now(),
            disease_detected=detection.disease_type,
            severity=detection.severity,
            environmental_risk=env_risk,
            recommendations=recommendations,
            summary=summary
        )

    def _assess_environmental_risk(self, env: EnvironmentalContext) -> str:
        """Assess overall environmental risk level."""
        risk_score = 0

        # Temperature risk
        if 15 <= env.temperature <= 30:
            risk_score += 1

        # Humidity risk
        if env.humidity >= 85:
            risk_score += 2
        elif env.humidity >= 70:
            risk_score += 1

        # Soil moisture risk
        if env.soil_moisture >= 60:
            risk_score += 1

        # Light risk
        if env.light_intensity <= 300:
            risk_score += 1

        if risk_score >= 4:
            return "high"
        elif risk_score >= 2:
            return "medium"
        else:
            return "low"

    def _generate_summary(
        self,
        detection: DetectionContext,
        recommendations: List[Recommendation],
        env_risk: str
    ) -> str:
        """Generate human-readable summary."""
        disease = detection.disease_type.value.replace('_', ' ').title()
        severity = detection.severity.name.lower()

        if detection.disease_type == DiseaseType.HEALTHY:
            summary = f"No disease detected. Environmental risk level: {env_risk}. "
            summary += f"Continue regular monitoring and maintenance practices."
        else:
            urgent = len([r for r in recommendations if r.priority == Priority.URGENT])
            high = len([r for r in recommendations if r.priority == Priority.HIGH])

            summary = f"{disease} detected with {severity} severity. "
            summary += f"Infection rate: {detection.infection_rate:.1f}%. "
            summary += f"Environmental risk: {env_risk}. "

            if urgent > 0:
                summary += f"URGENT: {urgent} immediate action(s) required. "
            if high > 0:
                summary += f"{high} high-priority recommendation(s) to address promptly."

        return summary

    def get_recommendations_for_language(
        self,
        report: RecommendationReport,
        language: str = "en"
    ) -> RecommendationReport:
        """
        Get recommendations translated to specified language.
        Translation is handled by the localization module.
        """
        # The actual translation happens in the mobile app using language_key
        # This method is a placeholder for server-side translation if needed
        return report


# Factory function
def create_recommendation_engine() -> RecommendationEngine:
    """Create and return a recommendation engine instance."""
    return RecommendationEngine()


if __name__ == "__main__":
    # Test the recommendation engine
    engine = create_recommendation_engine()

    # Test case 1: Red Rust detection
    detection = DetectionContext(
        disease_type=DiseaseType.RED_RUST,
        confidence=0.85,
        affected_count=5,
        total_leaves=20,
        detection_time=datetime.now()
    )

    environmental = EnvironmentalContext(
        temperature=27,
        humidity=82,
        soil_moisture=65,
        light_intensity=350
    )

    report = engine.generate_recommendations(detection, environmental)

    print("=" * 60)
    print("RECOMMENDATION REPORT")
    print("=" * 60)
    print(f"Summary: {report.summary}")
    print(f"\nTotal Recommendations: {len(report.recommendations)}")

    for rec in report.recommendations:
        print(f"\n[{rec.priority.name}] {rec.title}")
        print(f"  Type: {rec.type.value}")
        print(f"  {rec.description}")
        print(f"  Actions:")
        for action in rec.actions:
            print(f"    - {action}")
        print(f"  Timing: {rec.timing}")
