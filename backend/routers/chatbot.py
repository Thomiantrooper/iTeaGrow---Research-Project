"""
Chatbot API Routes - Ollama-powered Tea Expert
"""

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime
import httpx
import logging
import random

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/chatbot", tags=["Chatbot"])

# Ollama settings
OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "llama3.2:latest"

# Tea expert system prompt
SYSTEM_PROMPT = """You are TeaBot, an expert AI assistant specializing in tea plantation management, tea production, and tea cultivation. You have deep knowledge about:

- Tea plant varieties (Camellia sinensis)
- Tea diseases (Red Rust, Blister Blight, etc.) and treatments
- Optimal growing conditions (soil, climate, elevation)
- Tea harvesting techniques and timing
- Tea processing methods (black, green, white, oolong, pu-erh)
- Sustainable tea farming practices
- Organic pest management
- Fertilization schedules
- Irrigation management
- Post-harvest processing
- Tea quality assessment
- Market trends and economics

Provide clear, practical, and actionable advice for tea farmers. Keep responses concise (2-3 paragraphs) unless more detail is requested. Use simple language that farmers can understand.

When discussing diseases, provide:
1. Symptoms to look for
2. Causes and conditions
3. Treatment recommendations
4. Prevention strategies
"""


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    conversation_history: Optional[List[Dict[str, str]]] = None
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    timestamp: datetime
    model: str
    session_id: Optional[str] = None


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Send a message to the tea expert chatbot."""
    try:
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]

        if request.conversation_history:
            messages.extend(request.conversation_history[-5:])

        messages.append({"role": "user", "content": request.message})

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{OLLAMA_URL}/api/chat",
                json={
                    "model": OLLAMA_MODEL,
                    "messages": messages,
                    "stream": False,
                },
            )

            if response.status_code == 200:
                data = response.json()
                return ChatResponse(
                    response=data["message"]["content"],
                    timestamp=datetime.utcnow(),
                    model=OLLAMA_MODEL,
                    session_id=request.session_id,
                )
            else:
                return ChatResponse(
                    response=_fallback_response(request.message),
                    timestamp=datetime.utcnow(),
                    model="fallback",
                    session_id=request.session_id,
                )

    except httpx.ConnectError:
        return ChatResponse(
            response=_offline_fallback(),
            timestamp=datetime.utcnow(),
            model="offline",
            session_id=request.session_id,
        )
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return ChatResponse(
            response=_fallback_response(request.message),
            timestamp=datetime.utcnow(),
            model="fallback",
            session_id=request.session_id,
        )


@router.post("/suggestions")
async def get_suggestions():
    """Get suggested questions for the chatbot."""
    return {
        "suggestions": [
            "What are the symptoms of Red Rust disease?",
            "How do I improve tea leaf quality?",
            "What's the best time to harvest tea?",
            "How to prevent Blister Blight?",
            "What soil pH is ideal for tea?",
            "How often should I fertilize tea plants?",
            "What causes yellowing of tea leaves?",
            "How to manage pests organically?",
        ]
    }


@router.get("/fact")
async def get_tea_fact():
    """Get a random interesting tea fact."""
    facts = [
        "Did you know? All types of tea (black, green, white, oolong) come from the same plant: Camellia sinensis!",
        "Tea is the second most consumed beverage in the world after water.",
        "Ceylon tea from Sri Lanka is world-renowned for its quality and distinctive flavor.",
        "A single tea plant can live and produce for over 100 years!",
        "The best time to harvest tea is during the 'flush' period when new growth appears.",
        "Tea contains L-theanine, an amino acid that promotes relaxation without drowsiness.",
    ]
    return {"fact": random.choice(facts)}


@router.get("/health")
async def chatbot_health():
    """Check if chatbot service is healthy."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{OLLAMA_URL}/api/tags")
            ollama_available = response.status_code == 200
    except:
        ollama_available = False

    return {
        "status": "healthy",
        "ollama_available": ollama_available,
        "model": OLLAMA_MODEL,
        "base_url": OLLAMA_URL,
        "message": "Chatbot is ready!" if ollama_available else "Ollama offline, using fallback"
    }


def _fallback_response(user_message: str) -> str:
    """Provide fallback response when Ollama unavailable."""
    msg_lower = user_message.lower()

    if any(word in msg_lower for word in ["disease", "rust", "blight", "sick"]):
        return """Common tea diseases include:

**Red Rust**: Orange-red powdery spots on leaves. Treat with copper-based fungicides and improve air circulation.

**Blister Blight**: Water-soaked lesions that turn brown. Remove infected leaves and apply fungicide.

For accurate detection, use our AI disease scanner! Take a photo of the affected leaf."""

    elif any(word in msg_lower for word in ["grow", "plant", "soil", "climate", "elevation"]):
        return """Optimal tea growing conditions:

- **Climate**: 20-30C (68-86F) with 50-70% humidity
- **Rainfall**: 1,500-2,500mm annually, well-distributed
- **Soil**: Acidic (pH 4.5-5.5), well-drained, rich in organic matter
- **Elevation**: 600-2,000m for quality tea
- **Sunlight**: Partial shade ideal

Sri Lanka's hill country provides excellent conditions!"""

    elif any(word in msg_lower for word in ["harvest", "pluck", "pick"]):
        return """Tea harvesting tips:

**Plucking Standard**: Two leaves and a bud (fine plucking)

**Timing**:
- Flush cycle: Every 7-14 days during growing season
- Best time: Morning after dew evaporates
- Quality peak: During cooler months

**Technique**: Use clean, sharp plucking shears for tender leaves."""

    else:
        return """I'm TeaBot, your tea plantation expert! I can help with:

- Tea cultivation and growing conditions
- Disease identification and treatment
- Harvesting techniques
- Tea processing methods
- Irrigation and fertilization
- Pest management

What would you like to know about tea farming?"""


def _offline_fallback() -> str:
    """Response when Ollama is not running."""
    return """**AI Assistant Offline**

I'm currently unable to connect to the AI server. However, you can still:

- Use the **Disease Scanner** to detect leaf diseases
- View your **Detection History**
- Check **IoT Sensor Data**
- Browse your **Plantation Dashboard**

Please ensure Ollama is running or check your internet connection."""
