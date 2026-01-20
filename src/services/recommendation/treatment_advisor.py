"""
Treatment advisor with detailed fungicide and cultural practice recommendations.
Provides specific treatment protocols for tea leaf diseases in Sri Lanka.
"""

from typing import Optional
from datetime import datetime, timezone

from src.core.logging import get_logger
from src.api.schemas import DiseaseClass, SeverityLevel

logger = get_logger(__name__)


class FungicideInfo:
    """Information about a fungicide treatment."""

    def __init__(
        self,
        name: str,
        active_ingredient: str,
        concentration: str,
        application_method: str,
        frequency: str,
        withholding_period: int,
        precautions: list[str],
        cost_category: str,
    ):
        self.name = name
        self.active_ingredient = active_ingredient
        self.concentration = concentration
        self.application_method = application_method
        self.frequency = frequency
        self.withholding_period = withholding_period
        self.precautions = precautions
        self.cost_category = cost_category

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "active_ingredient": self.active_ingredient,
            "concentration": self.concentration,
            "application_method": self.application_method,
            "frequency": self.frequency,
            "withholding_period_days": self.withholding_period,
            "precautions": self.precautions,
            "cost_category": self.cost_category,
        }


class TreatmentAdvisor:
    """
    Provides detailed treatment recommendations for tea leaf diseases.
    Tailored for Sri Lankan tea plantation conditions.
    """

    FUNGICIDES = {
        "bordeaux_mixture": FungicideInfo(
            name="Bordeaux Mixture",
            active_ingredient="Copper sulfate + Lime",
            concentration="1% solution (1:1:100)",
            application_method="Foliar spray with fine droplets",
            frequency="7-10 day intervals during disease pressure",
            withholding_period=7,
            precautions=[
                "Avoid application during rain or high humidity",
                "Do not mix with other chemicals",
                "Wear protective equipment during application",
                "May cause leaf burn if concentration too high",
            ],
            cost_category="low",
        ),
        "copper_oxychloride": FungicideInfo(
            name="Copper Oxychloride",
            active_ingredient="Copper oxychloride 50% WP",
            concentration="3g per liter of water",
            application_method="High volume spray to runoff",
            frequency="10-14 day intervals",
            withholding_period=7,
            precautions=[
                "Apply in early morning or late evening",
                "Ensure good coverage of leaf undersides",
                "Rotate with other fungicides to prevent resistance",
            ],
            cost_category="low",
        ),
        "hexaconazole": FungicideInfo(
            name="Hexaconazole",
            active_ingredient="Hexaconazole 5% EC",
            concentration="1ml per liter of water",
            application_method="Foliar spray with sticker",
            frequency="14-21 day intervals",
            withholding_period=14,
            precautions=[
                "Systemic action - do not apply before harvest",
                "Use only when disease pressure is high",
                "Maximum 3 applications per season",
            ],
            cost_category="moderate",
        ),
        "carbendazim": FungicideInfo(
            name="Carbendazim",
            active_ingredient="Carbendazim 50% WP",
            concentration="1g per liter of water",
            application_method="Foliar spray",
            frequency="10-14 day intervals",
            withholding_period=10,
            precautions=[
                "Systemic fungicide - follow label strictly",
                "Rotate with contact fungicides",
                "Not for use during flush period",
            ],
            cost_category="moderate",
        ),
        "mancozeb": FungicideInfo(
            name="Mancozeb",
            active_ingredient="Mancozeb 75% WP",
            concentration="2.5g per liter of water",
            application_method="High volume spray",
            frequency="7-10 day intervals",
            withholding_period=7,
            precautions=[
                "Contact fungicide - thorough coverage needed",
                "Preventive action only",
                "Do not apply in hot sunny conditions",
            ],
            cost_category="low",
        ),
    }

    CULTURAL_PRACTICES = {
        "red_rust": [
            {
                "practice": "Pruning",
                "description": "Remove infected branches during dry weather",
                "timing": "Immediately upon detection, continue monthly",
                "benefits": "Removes inoculum source, improves air circulation",
            },
            {
                "practice": "Shade Management",
                "description": "Maintain optimal shade levels (40-50%)",
                "timing": "Seasonal adjustment",
                "benefits": "Reduces humidity in canopy",
            },
            {
                "practice": "Drainage Improvement",
                "description": "Clear blocked drains, create new drainage channels",
                "timing": "Before monsoon season",
                "benefits": "Reduces waterlogging and humidity",
            },
            {
                "practice": "Weed Control",
                "description": "Remove weeds that harbor fungal spores",
                "timing": "Monthly during wet season",
                "benefits": "Reduces alternate hosts and improves airflow",
            },
        ],
        "blister_blight": [
            {
                "practice": "Plucking Round Adjustment",
                "description": "Increase plucking frequency to 4-5 day rounds",
                "timing": "During disease outbreaks",
                "benefits": "Removes susceptible young leaves",
            },
            {
                "practice": "Shade Reduction",
                "description": "Temporary shade reduction during outbreaks",
                "timing": "When humidity exceeds 85%",
                "benefits": "Reduces leaf wetness duration",
            },
            {
                "practice": "Fertilizer Management",
                "description": "Reduce nitrogen application during outbreaks",
                "timing": "During active disease period",
                "benefits": "Reduces production of susceptible young growth",
            },
            {
                "practice": "Wind Breaks",
                "description": "Establish or maintain wind breaks",
                "timing": "Long-term measure",
                "benefits": "Reduces spore dispersal between sections",
            },
        ],
    }

    def __init__(self):
        """Initialize the treatment advisor."""
        self._treatment_history: dict[str, list[dict]] = {}

    def get_treatment_protocol(
        self,
        disease: DiseaseClass,
        severity: SeverityLevel,
        environmental_factors: Optional[dict] = None,
    ) -> dict:
        """
        Get complete treatment protocol for a disease.

        Args:
            disease: Type of disease detected
            severity: Severity level of infection
            environmental_factors: Optional environmental context

        Returns:
            Complete treatment protocol dictionary
        """
        if disease == DiseaseClass.HEALTHY:
            return self._get_preventive_protocol()

        protocol = {
            "disease": disease.value,
            "severity": severity.value,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "chemical_treatments": [],
            "cultural_practices": [],
            "monitoring_schedule": {},
            "expected_timeline": {},
            "precautions": [],
        }

        if disease == DiseaseClass.RED_RUST:
            protocol = self._get_red_rust_protocol(severity, protocol)
        elif disease == DiseaseClass.BLISTER_BLIGHT:
            protocol = self._get_blister_blight_protocol(severity, protocol)

        if environmental_factors:
            protocol = self._adjust_for_environment(protocol, environmental_factors)

        return protocol

    def _get_red_rust_protocol(self, severity: SeverityLevel, protocol: dict) -> dict:
        """Get treatment protocol for red rust."""
        if severity in [SeverityLevel.HIGH, SeverityLevel.CRITICAL]:
            protocol["chemical_treatments"] = [
                self.FUNGICIDES["copper_oxychloride"].to_dict(),
                self.FUNGICIDES["mancozeb"].to_dict(),
            ]
            protocol["application_schedule"] = {
                "initial": "Immediate application",
                "follow_up": "Repeat after 7-10 days",
                "total_applications": 3,
            }
        else:
            protocol["chemical_treatments"] = [
                self.FUNGICIDES["bordeaux_mixture"].to_dict(),
            ]
            protocol["application_schedule"] = {
                "initial": "Within 2-3 days",
                "follow_up": "Repeat after 14 days if needed",
                "total_applications": 2,
            }

        protocol["cultural_practices"] = self.CULTURAL_PRACTICES["red_rust"]

        protocol["monitoring_schedule"] = {
            "inspection_frequency": "Daily during treatment",
            "documentation": "Photo records of affected areas",
            "success_indicators": [
                "No new lesions appearing",
                "Existing lesions drying up",
                "New growth remaining healthy",
            ],
        }

        protocol["expected_timeline"] = {
            "initial_response": "3-5 days",
            "visible_improvement": "7-14 days",
            "full_control": "21-30 days",
        }

        return protocol

    def _get_blister_blight_protocol(
        self, severity: SeverityLevel, protocol: dict
    ) -> dict:
        """Get treatment protocol for blister blight."""
        if severity in [SeverityLevel.HIGH, SeverityLevel.CRITICAL]:
            protocol["chemical_treatments"] = [
                self.FUNGICIDES["hexaconazole"].to_dict(),
                self.FUNGICIDES["copper_oxychloride"].to_dict(),
            ]
            protocol["application_schedule"] = {
                "initial": "Immediate - within 12 hours",
                "follow_up": "Alternate fungicides every 7 days",
                "total_applications": 4,
            }
        else:
            protocol["chemical_treatments"] = [
                self.FUNGICIDES["carbendazim"].to_dict(),
            ]
            protocol["application_schedule"] = {
                "initial": "Within 24-48 hours",
                "follow_up": "Repeat after 10-14 days",
                "total_applications": 2,
            }

        protocol["cultural_practices"] = self.CULTURAL_PRACTICES["blister_blight"]

        protocol["monitoring_schedule"] = {
            "inspection_frequency": "Twice daily during outbreaks",
            "documentation": "Track weather conditions and disease spread",
            "success_indicators": [
                "Reduction in new blister formation",
                "Young leaves remaining clean",
                "Decrease in leaf curling",
            ],
        }

        protocol["expected_timeline"] = {
            "initial_response": "2-3 days",
            "visible_improvement": "7-10 days",
            "full_control": "14-21 days",
        }

        protocol["special_considerations"] = [
            "Suspend harvest in severely affected areas",
            "Avoid walking through wet infected areas",
            "Clean equipment between sections",
        ]

        return protocol

    def _get_preventive_protocol(self) -> dict:
        """Get preventive protocol for healthy plants."""
        return {
            "disease": "none",
            "severity": "none",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "preventive_measures": [
                {
                    "category": "Monitoring",
                    "actions": [
                        "Weekly field inspections",
                        "Weather monitoring for disease conditions",
                        "Scout field margins and susceptible areas",
                    ],
                },
                {
                    "category": "Cultural",
                    "actions": [
                        "Maintain optimal shade (40-50%)",
                        "Regular pruning for air circulation",
                        "Proper drainage maintenance",
                        "Balanced fertilization",
                    ],
                },
                {
                    "category": "Preventive Sprays",
                    "actions": [
                        "Apply copper-based fungicide during wet weather",
                        "Schedule preventive sprays before monsoon",
                        "Treat field margins as buffer zones",
                    ],
                },
            ],
            "recommended_fungicide": self.FUNGICIDES["bordeaux_mixture"].to_dict(),
            "spray_schedule": "Monthly during high-risk periods",
        }

    def _adjust_for_environment(
        self, protocol: dict, environmental_factors: dict
    ) -> dict:
        """Adjust protocol based on environmental conditions."""
        humidity = environmental_factors.get("humidity")
        temperature = environmental_factors.get("temperature")
        rainfall_expected = environmental_factors.get("rainfall_expected", False)

        adjustments = []

        if humidity and humidity > 85:
            adjustments.append(
                "High humidity detected - consider adding sticker/spreader to spray mix"
            )
            adjustments.append(
                "Increase spray frequency to every 5-7 days during humid conditions"
            )

        if rainfall_expected:
            adjustments.append(
                "Rain expected - apply treatment during dry window (minimum 4 hours before rain)"
            )
            adjustments.append("Consider rain-fast formulations")

        if temperature and temperature > 30:
            adjustments.append(
                "High temperature - apply sprays early morning or late evening only"
            )
            adjustments.append("Increase water volume to prevent concentration")

        protocol["environmental_adjustments"] = adjustments

        return protocol

    def get_fungicide_rotation_schedule(
        self,
        disease: DiseaseClass,
        treatment_duration_weeks: int = 8,
    ) -> list[dict]:
        """
        Generate fungicide rotation schedule to prevent resistance.

        Args:
            disease: Target disease
            treatment_duration_weeks: Duration of treatment program

        Returns:
            List of weekly treatment recommendations
        """
        schedule = []

        if disease == DiseaseClass.RED_RUST:
            rotation = ["copper_oxychloride", "mancozeb", "bordeaux_mixture"]
        elif disease == DiseaseClass.BLISTER_BLIGHT:
            rotation = ["hexaconazole", "carbendazim", "copper_oxychloride"]
        else:
            rotation = ["bordeaux_mixture"]

        for week in range(treatment_duration_weeks):
            fungicide_key = rotation[week % len(rotation)]
            fungicide = self.FUNGICIDES[fungicide_key]

            schedule.append({
                "week": week + 1,
                "fungicide": fungicide.name,
                "active_ingredient": fungicide.active_ingredient,
                "concentration": fungicide.concentration,
                "notes": f"Mode of action group rotation - Week {week + 1}",
            })

        return schedule

    def calculate_treatment_cost(
        self,
        area_hectares: float,
        disease: DiseaseClass,
        severity: SeverityLevel,
    ) -> dict:
        """
        Estimate treatment cost for a given area.

        Args:
            area_hectares: Area to be treated in hectares
            disease: Type of disease
            severity: Severity level

        Returns:
            Cost estimate breakdown
        """
        base_costs_per_hectare = {
            "low": 5000,      # LKR
            "moderate": 10000,
            "high": 20000,
        }

        if severity in [SeverityLevel.HIGH, SeverityLevel.CRITICAL]:
            cost_category = "high"
            num_applications = 4
        elif severity == SeverityLevel.MODERATE:
            cost_category = "moderate"
            num_applications = 3
        else:
            cost_category = "low"
            num_applications = 2

        fungicide_cost = base_costs_per_hectare[cost_category] * area_hectares

        labor_cost = 2500 * num_applications * area_hectares

        equipment_cost = 500 * num_applications * area_hectares

        total_cost = (fungicide_cost * num_applications) + labor_cost + equipment_cost

        return {
            "area_hectares": area_hectares,
            "disease": disease.value,
            "severity": severity.value,
            "num_applications": num_applications,
            "breakdown": {
                "fungicide_cost_lkr": fungicide_cost * num_applications,
                "labor_cost_lkr": labor_cost,
                "equipment_cost_lkr": equipment_cost,
            },
            "total_cost_lkr": total_cost,
            "cost_per_hectare_lkr": total_cost / area_hectares if area_hectares > 0 else 0,
            "notes": "Estimates based on 2024 prices. Actual costs may vary.",
        }

    def record_treatment(
        self,
        plantation_id: str,
        treatment_details: dict,
    ) -> str:
        """
        Record a treatment application for tracking.

        Args:
            plantation_id: Plantation identifier
            treatment_details: Details of treatment applied

        Returns:
            Treatment record ID
        """
        record_id = f"TRT-{datetime.now().strftime('%Y%m%d%H%M%S')}"

        if plantation_id not in self._treatment_history:
            self._treatment_history[plantation_id] = []

        record = {
            "record_id": record_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **treatment_details,
        }

        self._treatment_history[plantation_id].append(record)

        logger.info(f"Recorded treatment {record_id} for plantation {plantation_id}")

        return record_id

    def get_treatment_history(
        self,
        plantation_id: str,
        limit: int = 10,
    ) -> list[dict]:
        """Get treatment history for a plantation."""
        history = self._treatment_history.get(plantation_id, [])
        return history[-limit:]
