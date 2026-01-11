"""
Demo version of Tea Grading API for testing in Postman
(Without TensorFlow dependency - uses mock predictions)
"""
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn
import random
import json
from pathlib import Path

# Initialize FastAPI app
app = FastAPI(
    title="Tea Grading API (Demo)",
    description="AI-powered tea grading with density-based quality control",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

CLASS_NAMES = ["BOP", "BOPF", "Dust", "Dust1", "Fanning1", "Pekoe"]

# Load model accuracy metrics if available
def load_model_metrics():
    """Load model accuracy from metrics file"""
    metrics_file = Path("model_metrics.json")
    if metrics_file.exists():
        with open(metrics_file, 'r') as f:
            return json.load(f)
    return None

MODEL_METRICS = load_model_metrics()

# Standard Density Table (grams per liter for each grade)
STANDARD_DENSITY = {
    "BOP": {"min": 280, "max": 320, "optimal": 300},
    "BOPF": {"min": 260, "max": 300, "optimal": 280},
    "Dust": {"min": 400, "max": 450, "optimal": 425},
    "Dust1": {"min": 380, "max": 430, "optimal": 405},
    "Fanning1": {"min": 320, "max": 370, "optimal": 345},
    "Pekoe": {"min": 250, "max": 290, "optimal": 270}
}

# Pricing Structure (base price per kg)
BASE_PRICES = {
    "BOP": 1200,
    "BOPF": 1100,
    "Dust": 800,
    "Dust1": 850,
    "Fanning1": 950,
    "Pekoe": 1300
}

# Response Models
class GradingResponse(BaseModel):
    grade: str
    confidence: float
    model_accuracy: float
    density_status: str
    entered_weight: float
    standard_density_range: dict
    within_tolerance: bool
    price_category: str
    price_per_kg: float
    quality_score: float
    recommendations: str

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool

# Helper Functions
def check_density(grade: str, weight: float, volume: float = 1.0) -> dict:
    """Check if weight-volume ratio matches standard density."""
    density = weight / volume
    standard = STANDARD_DENSITY[grade]
    
    tolerance = 0.05
    min_acceptable = standard["min"] * (1 - tolerance)
    max_acceptable = standard["max"] * (1 + tolerance)
    
    within_tolerance = min_acceptable <= density <= max_acceptable
    optimal_density = standard["optimal"]
    deviation_percentage = abs((density - optimal_density) / optimal_density) * 100
    
    if within_tolerance:
        if abs(density - optimal_density) / optimal_density <= 0.02:
            status = "Excellent"
        elif abs(density - optimal_density) / optimal_density <= 0.05:
            status = "Good"
        else:
            status = "Acceptable"
    else:
        if density < min_acceptable:
            status = "Below Standard (Low Density)"
        else:
            status = "Below Standard (High Density)"
    
    return {
        "actual_density": round(density, 2),
        "standard_range": standard,
        "within_tolerance": within_tolerance,
        "status": status,
        "deviation_percentage": round(deviation_percentage, 2)
    }

def calculate_price(grade: str, density_check: dict) -> dict:
    """Calculate price based on grade and density compliance."""
    base_price = BASE_PRICES[grade]
    
    if density_check["within_tolerance"]:
        if density_check["status"] == "Excellent":
            multiplier = 1.15
            category = "Premium"
        elif density_check["status"] == "Good":
            multiplier = 1.08
            category = "Premium"
        else:
            multiplier = 1.0
            category = "Standard"
    else:
        multiplier = 0.85
        category = "Below Standard"
    
    final_price = round(base_price * multiplier, 2)
    
    return {
        "base_price": base_price,
        "multiplier": multiplier,
        "final_price": final_price,
        "category": category
    }

def generate_recommendations(grade: str, density_check: dict) -> str:
    """Generate quality recommendations."""
    if density_check["within_tolerance"]:
        if density_check["status"] == "Excellent":
            return f"Excellent quality {grade}! Density is optimal. Suitable for premium markets."
        elif density_check["status"] == "Good":
            return f"Good quality {grade}. Density is within acceptable range."
        else:
            return f"Acceptable quality {grade}. Minor density variation detected."
    else:
        if "Low Density" in density_check["status"]:
            return f"⚠️ Quality concern: Density is {density_check['deviation_percentage']}% below standard."
        else:
            return f"⚠️ Quality concern: Density is {density_check['deviation_percentage']}% above standard."

def calculate_quality_score(confidence: float, density_check: dict) -> float:
    """Calculate overall quality score (0-100)."""
    confidence_score = confidence * 50
    
    if density_check["within_tolerance"]:
        if density_check["status"] == "Excellent":
            density_score = 50
        elif density_check["status"] == "Good":
            density_score = 45
        else:
            density_score = 40
    else:
        deviation = min(density_check["deviation_percentage"], 50)
        density_score = max(0, 40 - deviation)
    
    return round(confidence_score + density_score, 2)

# API Endpoints
@app.get("/", response_model=HealthResponse)
async def root():
    """Health check endpoint."""
    return {"status": "healthy", "model_loaded": True}

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Detailed health check."""
    return {"status": "healthy", "model_loaded": True}

@app.get("/grades")
async def get_grades():
    """Get all available tea grades with their density standards."""
    return {
        "grades": CLASS_NAMES,
        "density_standards": STANDARD_DENSITY,
        "base_prices": BASE_PRICES
    }

@app.get("/metrics")
async def get_model_metrics():
    """Get model performance metrics including accuracy."""
    if MODEL_METRICS:
        return MODEL_METRICS
    else:
        return {
            "message": "Metrics not available. Run evaluate_model.py to generate metrics.",
            "demo_accuracy": 92.5,
            "note": "Using demo mode with simulated predictions"
        }

@app.post("/predict", response_model=GradingResponse)
async def predict_tea_grade(
    image: UploadFile = File(..., description="Tea image for classification"),
    weight: float = Form(..., description="Weight in grams", gt=0),
    volume: Optional[float] = Form(1.0, description="Volume in liters", gt=0)
):
    """
    Predict tea grade and calculate price based on image and weight-volume ratio.
    NOTE: This demo version uses random predictions for testing purposes.
    """
    try:
        # DEMO: Random prediction (replace with actual model in production)
        predicted_grade = random.choice(CLASS_NAMES)
        confidence = random.uniform(0.85, 0.99)
        
        # Check density
        density_check = check_density(predicted_grade, weight, volume)
        
        # Calculate price
        pricing = calculate_price(predicted_grade, density_check)
        
        # Generate recommendations
        recommendations = generate_recommendations(predicted_grade, density_check)
        
        # Calculate quality score
        quality_score = calculate_quality_score(confidence, density_check)
        
        # Get model accuracy
        if MODEL_METRICS:
            model_accuracy = MODEL_METRICS.get("overall_accuracy", 92.5)
        else:
            model_accuracy = 92.5  # Demo default
        
        return GradingResponse(
            grade=predicted_grade,
            confidence=round(confidence * 100, 2),
            model_accuracy=model_accuracy,
            density_status=density_check["status"],
            entered_weight=weight,
            standard_density_range={
                "min": density_check["standard_range"]["min"],
                "max": density_check["standard_range"]["max"],
                "optimal": density_check["standard_range"]["optimal"],
                "actual": density_check["actual_density"]
            },
            within_tolerance=density_check["within_tolerance"],
            price_category=pricing["category"],
            price_per_kg=pricing["final_price"],
            quality_score=quality_score,
            recommendations=recommendations
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing request: {str(e)}")

@app.post("/check-density")
async def check_density_only(
    grade: str = Form(..., description="Tea grade"),
    weight: float = Form(..., description="Weight in grams", gt=0),
    volume: Optional[float] = Form(1.0, description="Volume in liters", gt=0)
):
    """Check density for a known grade without image classification."""
    if grade not in CLASS_NAMES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid grade. Must be one of: {', '.join(CLASS_NAMES)}"
        )
    
    density_check = check_density(grade, weight, volume)
    pricing = calculate_price(grade, density_check)
    
    return {
        "grade": grade,
        "density_analysis": density_check,
        "pricing": pricing
    }

if __name__ == "__main__":
    print("\n" + "="*60)
    print("🍵 TEA GRADING API - DEMO MODE")
    print("="*60)
    print("Server starting at: http://localhost:8000")
    print("API Docs: http://localhost:8000/docs")
    print("="*60 + "\n")
    
    uvicorn.run(
        "app_demo:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
