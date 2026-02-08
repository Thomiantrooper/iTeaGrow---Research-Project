"""
Recommendation API routes for disease management.
"""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Query

from src.core.logging import get_logger
from src.api.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    DetectionSummary,
    EnvironmentalConditions,
    DiseaseClass,
    SeverityLevel,
    ErrorResponse,
)
from src.services.recommendation import RulesEngine, TreatmentAdvisor

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/recommendations", tags=["Recommendations"])

rules_engine: Optional[RulesEngine] = None
treatment_advisor: Optional[TreatmentAdvisor] = None


def get_rules_engine() -> RulesEngine:
    """Dependency to get rules engine instance."""
    global rules_engine
    if rules_engine is None:
        rules_engine = RulesEngine()
    return rules_engine


def get_treatment_advisor() -> TreatmentAdvisor:
    """Dependency to get treatment advisor instance."""
    global treatment_advisor
    if treatment_advisor is None:
        treatment_advisor = TreatmentAdvisor()
    return treatment_advisor


@router.post(
    "/generate",
    response_model=RecommendationResponse,
    responses={
        500: {"model": ErrorResponse, "description": "Generation error"},
    },
)
async def generate_recommendations(
    request: RecommendationRequest,
    engine: RulesEngine = Depends(get_rules_engine),
):
    """
    Generate disease management recommendations.

    Takes detection results and environmental conditions to produce
    prioritized, actionable recommendations.
    """
    try:
        response = engine.generate_recommendations(request)
        return response

    except Exception as e:
        logger.error(f"Failed to generate recommendations: {e}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "RECOMMENDATION_ERROR",
                "message": str(e),
            },
        )


@router.get("/quick")
async def quick_recommendations(
    plantation_id: str,
    disease: Optional[str] = Query(None, description="Detected disease type"),
    severity: Optional[str] = Query(None, description="Severity level"),
    temperature: Optional[float] = Query(None),
    humidity: Optional[float] = Query(None),
    engine: RulesEngine = Depends(get_rules_engine),
):
    """
    Get quick recommendations based on simple parameters.

    Useful for rapid assessment without full detection results.
    """
    detection_summary = None
    if disease or severity:
        disease_class = DiseaseClass(disease) if disease else None
        severity_level = SeverityLevel(severity) if severity else SeverityLevel.MODERATE

        detection_summary = DetectionSummary(
            total_leaves_detected=10,
            healthy_count=5 if disease_class != DiseaseClass.HEALTHY else 10,
            red_rust_count=5 if disease_class == DiseaseClass.RED_RUST else 0,
            blister_blight_count=5 if disease_class == DiseaseClass.BLISTER_BLIGHT else 0,
            overall_health_score=50.0 if disease else 100.0,
            dominant_disease=disease_class if disease_class != DiseaseClass.HEALTHY else None,
            severity_level=severity_level,
            requires_immediate_action=severity_level in [SeverityLevel.HIGH, SeverityLevel.CRITICAL],
        )

    environmental = None
    if temperature is not None or humidity is not None:
        environmental = EnvironmentalConditions(
            plantation_id=plantation_id,
            timestamp=datetime.now(timezone.utc),
            temperature_avg=temperature,
            humidity_avg=humidity,
            disease_risk_factors={},
        )

    request = RecommendationRequest(
        plantation_id=plantation_id,
        detection_summary=detection_summary,
        environmental_conditions=environmental,
        include_preventive=True,
        max_recommendations=5,
    )

    return engine.generate_recommendations(request)


@router.get("/treatment/{disease}")
async def get_treatment_protocol(
    disease: str,
    severity: str = Query("moderate", description="Severity level"),
    temperature: Optional[float] = Query(None),
    humidity: Optional[float] = Query(None),
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """
    Get detailed treatment protocol for a specific disease.

    Returns fungicide recommendations, application schedules,
    and cultural practices.
    """
    try:
        disease_class = DiseaseClass(disease)
        severity_level = SeverityLevel(severity)
    except ValueError as e:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "INVALID_PARAMETER",
                "message": str(e),
            },
        )

    environmental_factors = {}
    if temperature is not None:
        environmental_factors["temperature"] = temperature
    if humidity is not None:
        environmental_factors["humidity"] = humidity

    protocol = advisor.get_treatment_protocol(
        disease=disease_class,
        severity=severity_level,
        environmental_factors=environmental_factors if environmental_factors else None,
    )

    return protocol


@router.get("/fungicides")
async def list_fungicides(
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """List all available fungicides with details."""
    return {
        "fungicides": [f.to_dict() for f in advisor.FUNGICIDES.values()],
    }


@router.get("/rotation-schedule")
async def get_fungicide_rotation(
    disease: str,
    weeks: int = Query(8, ge=4, le=16),
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """
    Get fungicide rotation schedule to prevent resistance.
    """
    try:
        disease_class = DiseaseClass(disease)
    except ValueError:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "INVALID_DISEASE",
                "message": f"Invalid disease: {disease}",
            },
        )

    schedule = advisor.get_fungicide_rotation_schedule(disease_class, weeks)

    return {
        "disease": disease,
        "duration_weeks": weeks,
        "schedule": schedule,
    }


@router.get("/cost-estimate")
async def estimate_treatment_cost(
    disease: str,
    severity: str,
    area_hectares: float = Query(..., gt=0),
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """
    Estimate treatment cost for a given area.

    Returns cost breakdown in LKR (Sri Lankan Rupees).
    """
    try:
        disease_class = DiseaseClass(disease)
        severity_level = SeverityLevel(severity)
    except ValueError as e:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "INVALID_PARAMETER",
                "message": str(e),
            },
        )

    estimate = advisor.calculate_treatment_cost(
        area_hectares=area_hectares,
        disease=disease_class,
        severity=severity_level,
    )

    return estimate


@router.post("/record-treatment")
async def record_treatment_application(
    plantation_id: str,
    treatment_details: dict,
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """Record a treatment application for tracking."""
    record_id = advisor.record_treatment(plantation_id, treatment_details)

    return {
        "success": True,
        "record_id": record_id,
        "message": "Treatment recorded successfully",
    }


@router.get("/treatment-history/{plantation_id}")
async def get_treatment_history(
    plantation_id: str,
    limit: int = Query(10, ge=1, le=100),
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """Get treatment history for a plantation."""
    history = advisor.get_treatment_history(plantation_id, limit)

    return {
        "plantation_id": plantation_id,
        "treatments": history,
    }


@router.get("/cultural-practices/{disease}")
async def get_cultural_practices(
    disease: str,
    advisor: TreatmentAdvisor = Depends(get_treatment_advisor),
):
    """Get recommended cultural practices for disease management."""
    if disease not in ["red_rust", "blister_blight"]:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "INVALID_DISEASE",
                "message": f"Cultural practices available for: red_rust, blister_blight",
            },
        )

    practices = advisor.CULTURAL_PRACTICES.get(disease, [])

    return {
        "disease": disease,
        "practices": practices,
    }
