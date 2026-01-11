"""
Inference API routes for disease detection.
"""

from datetime import datetime
from typing import Optional
import uuid

from fastapi import APIRouter, File, UploadFile, Form, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import ValidationError, ImageQualityError, InferenceError
from src.api.schemas import (
    InferenceRequest,
    InferenceResponse,
    BatchInferenceRequest,
    BatchInferenceResponse,
    ExplainabilityRequest,
    ExplainabilityResponse,
    ModelInfoResponse,
    ErrorResponse,
)
from src.services.inference import TeaLeafDetector, ImageProcessor
from src.services.explainability import YOLOv8GradCAM
from src.services.sync import LocalStorageManager

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/inference", tags=["Inference"])

detector: Optional[TeaLeafDetector] = None
gradcam: Optional[YOLOv8GradCAM] = None
storage: Optional[LocalStorageManager] = None


def get_detector() -> TeaLeafDetector:
    """Dependency to get detector instance."""
    global detector
    if detector is None:
        detector = TeaLeafDetector()
    return detector


def get_gradcam() -> YOLOv8GradCAM:
    """Dependency to get Grad-CAM instance."""
    global gradcam
    if gradcam is None:
        gradcam = YOLOv8GradCAM()
    return gradcam


def get_storage() -> LocalStorageManager:
    """Dependency to get storage instance."""
    global storage
    if storage is None:
        storage = LocalStorageManager()
    return storage


@router.post(
    "/detect",
    response_model=InferenceResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Image quality error"},
        422: {"model": ErrorResponse, "description": "Validation error"},
        500: {"model": ErrorResponse, "description": "Inference error"},
    },
)
async def detect_diseases(
    image: UploadFile = File(..., description="Tea leaf image to analyze"),
    plantation_id: Optional[str] = Form(None),
    location_lat: Optional[float] = Form(None),
    location_lng: Optional[float] = Form(None),
    request_explainability: bool = Form(False),
    skip_quality_check: bool = Form(False),
    background_tasks: BackgroundTasks = None,
    detector_instance: TeaLeafDetector = Depends(get_detector),
    storage_instance: LocalStorageManager = Depends(get_storage),
):
    """
    Perform disease detection on a tea leaf image.

    This endpoint accepts an image and returns detected diseases with
    bounding boxes, confidence scores, and severity assessment.
    """
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "INVALID_CONTENT_TYPE",
                "message": f"Expected image file, got {image.content_type}",
            },
        )

    try:
        image_bytes = await image.read()
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail={
                "error": True,
                "error_code": "READ_ERROR",
                "message": f"Failed to read image: {str(e)}",
            },
        )

    image_id = str(uuid.uuid4())

    try:
        storage_instance.store_image(
            image_bytes,
            image_id=image_id,
            metadata={
                "plantation_id": plantation_id,
                "location_lat": location_lat,
                "location_lng": location_lng,
                "original_filename": image.filename,
            },
        )
    except Exception as e:
        logger.warning(f"Failed to store image locally: {e}")

    try:
        result = detector_instance.detect(
            image_bytes,
            image_id=image_id,
            skip_quality_check=skip_quality_check,
        )
    except ImageQualityError as e:
        raise HTTPException(
            status_code=400,
            detail=e.to_dict(),
        )
    except InferenceError as e:
        raise HTTPException(
            status_code=500,
            detail=e.to_dict(),
        )

    if request_explainability and background_tasks:
        explainability_task_id = str(uuid.uuid4())
        background_tasks.add_task(
            _generate_explainability,
            image_bytes=image_bytes,
            image_id=image_id,
            detections=[d.model_dump() for d in result.detections],
            task_id=explainability_task_id,
        )
        result.explainability_task_id = explainability_task_id

    try:
        storage_instance.store_detection_result(
            result.model_dump(),
            image_id=image_id,
        )
    except Exception as e:
        logger.warning(f"Failed to store detection result: {e}")

    return result


async def _generate_explainability(
    image_bytes: bytes,
    image_id: str,
    detections: list[dict],
    task_id: str,
):
    """Background task to generate Grad-CAM explainability."""
    try:
        gradcam_instance = get_gradcam()
        processor = ImageProcessor()
        image = processor.load_image(image_bytes)

        result = gradcam_instance.explain_image(
            image=image,
            detections=detections,
            image_id=image_id,
        )

        storage_instance = get_storage()
        storage_instance.store_detection_result(
            {"task_id": task_id, "explainability": result.model_dump()},
            image_id=f"explain_{image_id}",
        )

        logger.info(f"Generated explainability for task {task_id}")

    except Exception as e:
        logger.error(f"Explainability generation failed: {e}")


@router.post(
    "/batch",
    response_model=BatchInferenceResponse,
)
async def batch_detect(
    images: list[UploadFile] = File(...),
    plantation_id: Optional[str] = Form(None),
    detector_instance: TeaLeafDetector = Depends(get_detector),
    storage_instance: LocalStorageManager = Depends(get_storage),
):
    """
    Perform batch disease detection on multiple images.

    Limited to 50 images per batch request.
    """
    if len(images) > 50:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "BATCH_TOO_LARGE",
                "message": "Maximum 50 images per batch",
            },
        )

    batch_id = str(uuid.uuid4())
    results = []
    errors = []

    for i, image in enumerate(images):
        try:
            image_bytes = await image.read()
            image_id = f"{batch_id}_{i}"

            result = detector_instance.detect(
                image_bytes,
                image_id=image_id,
                skip_quality_check=True,
            )
            results.append(result)

        except Exception as e:
            errors.append({
                "index": i,
                "filename": image.filename,
                "error": str(e),
            })

    return BatchInferenceResponse(
        batch_id=batch_id,
        status="completed",
        total_images=len(images),
        processed=len(results),
        failed=len(errors),
        results=results,
        errors=errors,
    )


@router.post(
    "/explain",
    response_model=ExplainabilityResponse,
)
async def explain_detection(
    image: UploadFile = File(...),
    image_id: str = Form(...),
    detection_ids: Optional[str] = Form(None),
    gradcam_instance: YOLOv8GradCAM = Depends(get_gradcam),
):
    """
    Generate Grad-CAM explainability heatmaps for detections.

    Returns visual explanations showing which regions the model
    focused on for each detection.
    """
    try:
        image_bytes = await image.read()
        processor = ImageProcessor()
        image_array = processor.load_image(image_bytes)

        detection_id_list = None
        if detection_ids:
            detection_id_list = [d.strip() for d in detection_ids.split(",")]

        result = gradcam_instance.explain_image(
            image=image_array,
            detections=[],
            image_id=image_id,
            target_classes=None,
        )

        return result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "EXPLAINABILITY_ERROR",
                "message": str(e),
            },
        )


@router.get(
    "/model-info",
    response_model=ModelInfoResponse,
)
async def get_model_info(
    detector_instance: TeaLeafDetector = Depends(get_detector),
):
    """Get information about the loaded detection model."""
    info = detector_instance.get_model_info()

    return ModelInfoResponse(
        model_name=info["model_name"],
        model_version=info["model_version"],
        model_type=info["model_type"],
        input_size=info["input_size"],
        classes=info["classes"],
        device=info["device"],
        quantization=info.get("quantization"),
        loaded_at=info["loaded_at"] or datetime.now(),
        total_inferences=info["total_inferences"],
        average_inference_time_ms=info["average_inference_time_ms"],
    )


@router.post("/export-onnx")
async def export_model_to_onnx(
    detector_instance: TeaLeafDetector = Depends(get_detector),
):
    """Export the PyTorch model to ONNX format."""
    try:
        output_path = detector_instance.export_to_onnx()
        return {
            "success": True,
            "message": "Model exported to ONNX format",
            "output_path": output_path,
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "EXPORT_ERROR",
                "message": str(e),
            },
        )
