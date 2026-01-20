"""
Rule-based recommendation engine for tea leaf disease management.
Generates actionable recommendations based on detection results and environmental conditions.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional
import uuid

from src.core.logging import get_logger
from src.api.schemas import (
    DiseaseClass,
    SeverityLevel,
    DetectionSummary,
    EnvironmentalConditions,
    Recommendation,
    RecommendationPriority,
    RecommendationRequest,
    RecommendationResponse,
)

logger = get_logger(__name__)


class Rule:
    """Base class for recommendation rules."""

    def __init__(
        self,
        name: str,
        description: str,
        priority: RecommendationPriority,
    ):
        self.name = name
        self.description = description
        self.priority = priority

    def evaluate(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> Optional[Recommendation]:
        """
        Evaluate the rule and generate recommendation if applicable.

        Args:
            detection: Detection summary
            environment: Environmental conditions

        Returns:
            Recommendation if rule triggers, None otherwise
        """
        raise NotImplementedError


class RedRustTreatmentRule(Rule):
    """Rule for red rust disease treatment recommendations."""

    def __init__(self):
        super().__init__(
            name="red_rust_treatment",
            description="Treatment recommendations for red rust disease",
            priority=RecommendationPriority.HIGH,
        )

    def evaluate(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> Optional[Recommendation]:
        if detection is None:
            return None

        if detection.red_rust_count == 0:
            return None

        severity = self._calculate_severity(detection)

        if severity == "critical":
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.URGENT,
                title="Immediate Red Rust Intervention Required",
                description=(
                    f"Critical red rust infection detected affecting "
                    f"{detection.red_rust_count} leaves. Immediate fungicide "
                    "application is necessary to prevent spread."
                ),
                action_steps=[
                    "Apply copper-based fungicide (e.g., Bordeaux mixture) at 1% concentration",
                    "Remove and destroy severely infected leaves",
                    "Improve air circulation by pruning dense areas",
                    "Schedule follow-up inspection in 5-7 days",
                    "Consider preventive spraying of adjacent areas",
                ],
                expected_outcome=(
                    "Reduction in infection spread within 7-10 days with proper treatment"
                ),
                timing="Immediate - within 24 hours",
                cost_estimate="Moderate - fungicide and labor costs",
                related_diseases=[DiseaseClass.RED_RUST],
            )
        elif severity == "high":
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.HIGH,
                title="Red Rust Treatment Recommended",
                description=(
                    f"Significant red rust infection detected on "
                    f"{detection.red_rust_count} leaves. Treatment should be "
                    "initiated promptly."
                ),
                action_steps=[
                    "Apply copper oxychloride spray at recommended dosage",
                    "Remove visibly infected leaves during dry conditions",
                    "Monitor surrounding plants for spread",
                    "Adjust irrigation to reduce leaf wetness duration",
                ],
                expected_outcome=(
                    "Control of infection spread within 10-14 days"
                ),
                timing="Within 2-3 days",
                cost_estimate="Low to moderate",
                related_diseases=[DiseaseClass.RED_RUST],
            )
        else:
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.MEDIUM,
                title="Monitor Red Rust Infection",
                description=(
                    f"Early stage red rust detected on {detection.red_rust_count} leaves. "
                    "Close monitoring and preventive measures recommended."
                ),
                action_steps=[
                    "Monitor affected areas daily for spread",
                    "Apply preventive fungicide spray if conditions favor disease",
                    "Improve drainage in affected areas",
                    "Document infection progression with photos",
                ],
                expected_outcome=(
                    "Prevention of disease escalation with early intervention"
                ),
                timing="Within 1 week",
                cost_estimate="Low",
                related_diseases=[DiseaseClass.RED_RUST],
            )

    def _calculate_severity(self, detection: DetectionSummary) -> str:
        """Calculate severity based on infection rate."""
        if detection.total_leaves_detected == 0:
            return "low"

        infection_rate = detection.red_rust_count / detection.total_leaves_detected

        if infection_rate > 0.4:
            return "critical"
        elif infection_rate > 0.2:
            return "high"
        else:
            return "moderate"


class BlisterBlightTreatmentRule(Rule):
    """Rule for blister blight disease treatment recommendations."""

    def __init__(self):
        super().__init__(
            name="blister_blight_treatment",
            description="Treatment recommendations for blister blight disease",
            priority=RecommendationPriority.HIGH,
        )

    def evaluate(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> Optional[Recommendation]:
        if detection is None:
            return None

        if detection.blister_blight_count == 0:
            return None

        severity = self._calculate_severity(detection)

        if severity == "critical":
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.URGENT,
                title="Emergency Blister Blight Control Required",
                description=(
                    f"Severe blister blight outbreak detected affecting "
                    f"{detection.blister_blight_count} leaves. Young shoots "
                    "and tender leaves are at high risk."
                ),
                action_steps=[
                    "Apply systemic fungicide (e.g., hexaconazole) immediately",
                    "Suspend harvesting of affected areas for 7-10 days",
                    "Increase plucking frequency to remove infected tissues",
                    "Apply protective fungicide to adjacent unaffected areas",
                    "Monitor weather conditions - high humidity accelerates spread",
                ],
                expected_outcome=(
                    "Control of outbreak within 14 days with aggressive treatment"
                ),
                timing="Immediate - within 12 hours",
                cost_estimate="High - intensive treatment and harvest loss",
                related_diseases=[DiseaseClass.BLISTER_BLIGHT],
            )
        elif severity == "high":
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.HIGH,
                title="Blister Blight Treatment Required",
                description=(
                    f"Active blister blight infection on {detection.blister_blight_count} "
                    "leaves. Prompt treatment will prevent significant crop loss."
                ),
                action_steps=[
                    "Apply copper-based or carbendazim fungicide spray",
                    "Focus treatment on young shoots and tender leaves",
                    "Increase air circulation by light pruning",
                    "Avoid overhead irrigation during outbreak",
                ],
                expected_outcome=(
                    "Disease control and protection of new growth within 10 days"
                ),
                timing="Within 24-48 hours",
                cost_estimate="Moderate",
                related_diseases=[DiseaseClass.BLISTER_BLIGHT],
            )
        else:
            return Recommendation(
                category="disease_treatment",
                priority=RecommendationPriority.MEDIUM,
                title="Blister Blight Monitoring Advised",
                description=(
                    f"Early blister blight symptoms on {detection.blister_blight_count} "
                    "leaves. Favorable conditions may lead to rapid spread."
                ),
                action_steps=[
                    "Increase inspection frequency to twice daily",
                    "Apply protective fungicide as preventive measure",
                    "Monitor humidity levels - disease favors >80% humidity",
                    "Consider temporary shade reduction if possible",
                ],
                expected_outcome=(
                    "Prevention of outbreak with proactive measures"
                ),
                timing="Within 3 days",
                cost_estimate="Low",
                related_diseases=[DiseaseClass.BLISTER_BLIGHT],
            )

    def _calculate_severity(self, detection: DetectionSummary) -> str:
        """Calculate severity based on infection rate."""
        if detection.total_leaves_detected == 0:
            return "low"

        infection_rate = detection.blister_blight_count / detection.total_leaves_detected

        if infection_rate > 0.3:
            return "critical"
        elif infection_rate > 0.15:
            return "high"
        else:
            return "moderate"


class EnvironmentalRiskRule(Rule):
    """Rule for environmental risk-based prevention recommendations."""

    def __init__(self):
        super().__init__(
            name="environmental_risk",
            description="Prevention recommendations based on environmental conditions",
            priority=RecommendationPriority.MEDIUM,
        )

    def evaluate(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> Optional[Recommendation]:
        if environment is None:
            return None

        risks = environment.disease_risk_factors
        if not risks:
            return None

        high_risk_diseases = []
        if risks.get("red_rust", 0) > 0.6:
            high_risk_diseases.append("red rust")
        if risks.get("blister_blight", 0) > 0.6:
            high_risk_diseases.append("blister blight")

        if not high_risk_diseases:
            return None

        action_steps = []

        if environment.humidity_avg and environment.humidity_avg > 80:
            action_steps.append(
                f"High humidity ({environment.humidity_avg:.1f}%) - improve ventilation"
            )

        if environment.temperature_avg:
            if 15 <= environment.temperature_avg <= 25:
                action_steps.append(
                    "Temperature conditions favor disease - increase monitoring"
                )

        if environment.soil_moisture_avg and environment.soil_moisture_avg > 70:
            action_steps.append(
                f"High soil moisture ({environment.soil_moisture_avg:.1f}%) - reduce irrigation"
            )

        action_steps.extend([
            "Apply preventive fungicide spray within 24-48 hours",
            "Increase field inspection frequency",
            "Prepare disease management materials for rapid response",
        ])

        return Recommendation(
            category="prevention",
            priority=RecommendationPriority.HIGH,
            title=f"High Risk Conditions for {', '.join(high_risk_diseases).title()}",
            description=(
                f"Current environmental conditions favor {', '.join(high_risk_diseases)} "
                "development. Preventive action recommended."
            ),
            action_steps=action_steps,
            expected_outcome=(
                "Reduced disease outbreak probability with preventive measures"
            ),
            timing="Within 24-48 hours",
            cost_estimate="Low to moderate - preventive treatments",
            related_diseases=[
                DiseaseClass.RED_RUST if "red rust" in high_risk_diseases else None,
                DiseaseClass.BLISTER_BLIGHT if "blister blight" in high_risk_diseases else None,
            ],
        )


class HealthMaintenanceRule(Rule):
    """Rule for general health maintenance recommendations."""

    def __init__(self):
        super().__init__(
            name="health_maintenance",
            description="General recommendations for maintaining plant health",
            priority=RecommendationPriority.LOW,
        )

    def evaluate(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> Optional[Recommendation]:
        if detection is None:
            return None

        if detection.overall_health_score < 90:
            return None

        return Recommendation(
            category="maintenance",
            priority=RecommendationPriority.LOW,
            title="Continue Good Agricultural Practices",
            description=(
                f"Plants are generally healthy (health score: "
                f"{detection.overall_health_score:.1f}%). Maintain current practices."
            ),
            action_steps=[
                "Continue regular monitoring schedule",
                "Maintain balanced fertilization program",
                "Ensure proper drainage and irrigation",
                "Practice regular pruning for air circulation",
                "Keep field sanitation by removing debris",
            ],
            expected_outcome=(
                "Sustained plant health and optimal yield"
            ),
            timing="Ongoing",
            cost_estimate="Standard operational costs",
            related_diseases=[DiseaseClass.HEALTHY],
        )


class RulesEngine:
    """
    Rule-based recommendation engine that evaluates multiple rules
    and generates prioritized recommendations.
    """

    def __init__(self):
        """Initialize the rules engine with default rules."""
        self.rules: list[Rule] = [
            RedRustTreatmentRule(),
            BlisterBlightTreatmentRule(),
            EnvironmentalRiskRule(),
            HealthMaintenanceRule(),
        ]

    def add_rule(self, rule: Rule) -> None:
        """Add a custom rule to the engine."""
        self.rules.append(rule)
        logger.info(f"Added rule: {rule.name}")

    def generate_recommendations(
        self,
        request: RecommendationRequest,
    ) -> RecommendationResponse:
        """
        Generate recommendations based on detection and environmental data.

        Args:
            request: Recommendation request with context

        Returns:
            RecommendationResponse with prioritized recommendations
        """
        request_id = str(uuid.uuid4())
        recommendations: list[Recommendation] = []

        for rule in self.rules:
            try:
                recommendation = rule.evaluate(
                    request.detection_summary,
                    request.environmental_conditions,
                )
                if recommendation is not None:
                    recommendations.append(recommendation)
            except Exception as e:
                logger.error(f"Error evaluating rule {rule.name}: {e}")
                continue

        if request.include_preventive:
            preventive_recs = self._generate_preventive_recommendations(
                request.detection_summary,
                request.environmental_conditions,
            )
            recommendations.extend(preventive_recs)

        recommendations = self._deduplicate_recommendations(recommendations)

        priority_order = {
            RecommendationPriority.URGENT: 0,
            RecommendationPriority.HIGH: 1,
            RecommendationPriority.MEDIUM: 2,
            RecommendationPriority.LOW: 3,
        }
        recommendations.sort(key=lambda r: priority_order[r.priority])

        if request.max_recommendations:
            recommendations = recommendations[:request.max_recommendations]

        risk_assessment = self._generate_risk_assessment(
            request.detection_summary,
            request.environmental_conditions,
            recommendations,
        )

        next_assessment = self._calculate_next_assessment(recommendations)

        logger.info(
            f"Generated {len(recommendations)} recommendations for plantation "
            f"{request.plantation_id}"
        )

        return RecommendationResponse(
            request_id=request_id,
            plantation_id=request.plantation_id,
            timestamp=datetime.now(timezone.utc),
            recommendations=recommendations,
            overall_risk_assessment=risk_assessment,
            next_assessment_date=next_assessment,
        )

    def _generate_preventive_recommendations(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
    ) -> list[Recommendation]:
        """Generate preventive recommendations for healthy areas."""
        preventive = []

        if detection and detection.severity_level == SeverityLevel.NONE:
            preventive.append(
                Recommendation(
                    category="prevention",
                    priority=RecommendationPriority.LOW,
                    title="Preventive Monitoring Schedule",
                    description=(
                        "No active diseases detected. Implement preventive monitoring "
                        "to maintain plant health."
                    ),
                    action_steps=[
                        "Conduct weekly visual inspections of field margins",
                        "Monitor weather forecasts for disease-favorable conditions",
                        "Maintain spray equipment for rapid response",
                        "Keep fungicide inventory stocked for 2 applications",
                    ],
                    expected_outcome="Early detection and prevention of outbreaks",
                    timing="Weekly schedule",
                    cost_estimate="Minimal - routine operations",
                    related_diseases=[],
                )
            )

        if environment:
            if environment.humidity_avg and 60 <= environment.humidity_avg <= 80:
                preventive.append(
                    Recommendation(
                        category="prevention",
                        priority=RecommendationPriority.LOW,
                        title="Moderate Humidity Management",
                        description=(
                            f"Current humidity ({environment.humidity_avg:.1f}%) is in "
                            "moderate range. Monitor for increases."
                        ),
                        action_steps=[
                            "Check humidity readings twice daily",
                            "Prepare drainage improvements if humidity rises",
                            "Consider light pruning for improved airflow",
                        ],
                        expected_outcome="Maintenance of favorable conditions",
                        timing="Ongoing monitoring",
                        cost_estimate="Minimal",
                        related_diseases=[],
                    )
                )

        return preventive

    def _deduplicate_recommendations(
        self,
        recommendations: list[Recommendation],
    ) -> list[Recommendation]:
        """Remove duplicate or overlapping recommendations."""
        seen_titles = set()
        unique = []

        for rec in recommendations:
            if rec.title not in seen_titles:
                seen_titles.add(rec.title)
                unique.append(rec)

        return unique

    def _generate_risk_assessment(
        self,
        detection: Optional[DetectionSummary],
        environment: Optional[EnvironmentalConditions],
        recommendations: list[Recommendation],
    ) -> str:
        """Generate overall risk assessment summary."""
        urgent_count = sum(
            1 for r in recommendations if r.priority == RecommendationPriority.URGENT
        )
        high_count = sum(
            1 for r in recommendations if r.priority == RecommendationPriority.HIGH
        )

        if urgent_count > 0:
            return (
                f"CRITICAL: {urgent_count} urgent issue(s) require immediate attention. "
                "Disease outbreak in progress or imminent."
            )
        elif high_count > 0:
            return (
                f"ELEVATED: {high_count} high-priority issue(s) detected. "
                "Prompt action recommended to prevent escalation."
            )
        elif detection and detection.severity_level != SeverityLevel.NONE:
            return (
                "MODERATE: Disease presence detected at manageable levels. "
                "Continue monitoring and implement preventive measures."
            )
        else:
            return (
                "LOW: No significant disease threats detected. "
                "Maintain standard monitoring and prevention practices."
            )

    def _calculate_next_assessment(
        self,
        recommendations: list[Recommendation],
    ) -> datetime:
        """Calculate recommended next assessment date."""
        now = datetime.now(timezone.utc)

        has_urgent = any(
            r.priority == RecommendationPriority.URGENT for r in recommendations
        )
        has_high = any(
            r.priority == RecommendationPriority.HIGH for r in recommendations
        )

        if has_urgent:
            return now + timedelta(days=1)
        elif has_high:
            return now + timedelta(days=3)
        else:
            return now + timedelta(days=7)
