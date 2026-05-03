"""
iTeaBot — Context-Aware Tea Plantation AI Assistant
Supports 5 domains: soil, leaf, climate, yield, powder
"""

from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any, AsyncIterator
from datetime import datetime
import httpx
import logging
import random
import json

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/chatbot", tags=["Chatbot"])

OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "llama3.2:latest"

# ─── System Prompts ────────────────────────────────────────────────────────────

_BASE_PROMPT = """You are iTeaBot, an intelligent AI assistant for the iTeaGrow smart tea plantation management platform. You have deep expertise in:

- Tea plant varieties (Camellia sinensis) and biology
- Tea diseases (Red Rust, Blister Blight, Brown Blight, Algal Leaf Spot) — symptoms, causes, treatment, prevention
- Optimal growing conditions: soil, climate, elevation, rainfall
- Tea harvesting techniques, flush cycles, and timing
- Tea processing methods (black, green, white, oolong)
- Sustainable and organic farming practices
- Fertilization, irrigation, and pest management
- IoT sensor data interpretation for precision agriculture
- Yield prediction, optimization, and block-level readiness
- Tea powder grading and quality assessment
- Market trends and economics for tea farmers in Sri Lanka

Provide clear, practical, actionable advice. Keep responses concise (2-3 paragraphs) unless more detail is requested. Use simple language farmers can understand. When real sensor/farm data is provided in the context, reference it specifically in your answer."""

_DOMAIN_ADDITIONS = {
    "soil": """
CURRENT DOMAIN: Soil Health & Monitoring
Focus on: soil pH (ideal 4.5–5.5), nutrient levels (N/P/K), moisture content, drainage, organic matter, and amendment recommendations. When soil sensor data is provided, interpret the readings and give specific action points.""",

    "leaf": """
CURRENT DOMAIN: Leaf & Disease Analysis
Focus on: disease identification from visual symptoms or detection results, severity assessment, treatment protocols (fungicide schedules, organic alternatives), prevention strategies, and leaf maturity stages for harvest readiness.""",

    "climate": """
CURRENT DOMAIN: Climate & Weather Insights
Focus on: temperature (ideal 20–30°C), humidity (50–70%), rainfall patterns, UV/light exposure, frost risk, and how current weather conditions affect tea growth, disease risk, and harvest timing.""",

    "yield": """
CURRENT DOMAIN: Yield Prediction & Harvest Planning
Focus on: production estimates, block-level harvest readiness, flush cycle tracking (P+1 through P+3 stages), optimization strategies, labor planning, and factors affecting output. When yield data is provided, interpret trends and give recommendations.""",

    "powder": """
CURRENT DOMAIN: Tea Powder Grading & Quality
Focus on: grading standards (BOPF, BOP, OP, Pekoe, Dust), quality indicators (color, aroma, particle size, moisture), processing consistency, factory-grade expectations, and how field conditions affect final powder quality.""",
}


def _build_system_prompt(context_type: Optional[str], context_data: Optional[Dict]) -> str:
    prompt = _BASE_PROMPT
    if context_type and context_type in _DOMAIN_ADDITIONS:
        prompt += _DOMAIN_ADDITIONS[context_type]
    if context_data:
        prompt += f"\n\nLIVE FARM DATA PROVIDED:\n{_format_context_data(context_data)}"
    return prompt


def _format_context_data(data: Dict) -> str:
    lines = []
    for key, value in data.items():
        if isinstance(value, dict):
            lines.append(f"  {key}:")
            for k, v in value.items():
                lines.append(f"    - {k}: {v}")
        elif isinstance(value, list):
            lines.append(f"  {key}: {', '.join(str(v) for v in value[:5])}")
        else:
            lines.append(f"  {key}: {value}")
    return "\n".join(lines)


# ─── Models ───────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    conversation_history: Optional[List[Dict[str, str]]] = None
    session_id: Optional[str] = None
    context_type: Optional[str] = None   # soil | leaf | climate | yield | powder
    context_data: Optional[Dict[str, Any]] = None  # live sensor/prediction data


class ChatResponse(BaseModel):
    response: str
    timestamp: datetime
    model: str
    session_id: Optional[str] = None
    context_type: Optional[str] = None


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Send a message to iTeaBot with optional domain context."""
    system_prompt = _build_system_prompt(request.context_type, request.context_data)

    try:
        messages = [{"role": "system", "content": system_prompt}]
        if request.conversation_history:
            messages.extend(request.conversation_history[-6:])
        messages.append({"role": "user", "content": request.message})

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{OLLAMA_URL}/api/chat",
                json={"model": OLLAMA_MODEL, "messages": messages, "stream": False},
            )

            if response.status_code == 200:
                data = response.json()
                return ChatResponse(
                    response=data["message"]["content"],
                    timestamp=datetime.utcnow(),
                    model=OLLAMA_MODEL,
                    session_id=request.session_id,
                    context_type=request.context_type,
                )
            else:
                return ChatResponse(
                    response=_fallback_response(request.message, request.context_type, request.context_data),
                    timestamp=datetime.utcnow(),
                    model="fallback",
                    session_id=request.session_id,
                    context_type=request.context_type,
                )

    except httpx.ConnectError:
        return ChatResponse(
            response=_fallback_response(request.message, request.context_type, request.context_data),
            timestamp=datetime.utcnow(),
            model="fallback",
            session_id=request.session_id,
            context_type=request.context_type,
        )
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return ChatResponse(
            response=_fallback_response(request.message, request.context_type, request.context_data),
            timestamp=datetime.utcnow(),
            model="fallback",
            session_id=request.session_id,
            context_type=request.context_type,
        )


@router.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """Stream iTeaBot response token-by-token via Server-Sent Events."""
    system_prompt = _build_system_prompt(request.context_type, request.context_data)
    messages = [{"role": "system", "content": system_prompt}]
    if request.conversation_history:
        messages.extend(request.conversation_history[-6:])
    messages.append({"role": "user", "content": request.message})

    async def token_stream() -> AsyncIterator[str]:
        try:
            async with httpx.AsyncClient(timeout=60) as client:
                async with client.stream(
                    "POST",
                    f"{OLLAMA_URL}/api/chat",
                    json={"model": OLLAMA_MODEL, "messages": messages, "stream": True},
                ) as response:
                    if response.status_code != 200:
                        fallback = _fallback_response(
                            request.message, request.context_type, request.context_data
                        )
                        yield f"data: {json.dumps({'token': fallback})}\n\n"
                        yield f"data: {json.dumps({'done': True})}\n\n"
                        return

                    async for line in response.aiter_lines():
                        if not line:
                            continue
                        try:
                            chunk = json.loads(line)
                        except json.JSONDecodeError:
                            continue
                        token = chunk.get("message", {}).get("content", "")
                        if token:
                            yield f"data: {json.dumps({'token': token})}\n\n"
                        if chunk.get("done"):
                            yield f"data: {json.dumps({'done': True})}\n\n"
                            return

        except httpx.ConnectError:
            fallback = _fallback_response(
                request.message, request.context_type, request.context_data
            )
            yield f"data: {json.dumps({'token': fallback})}\n\n"
            yield f"data: {json.dumps({'done': True})}\n\n"
        except Exception as e:
            logger.error(f"Stream error: {e}")
            yield f"data: {json.dumps({'token': 'Sorry, something went wrong. Please try again.'})}\n\n"
            yield f"data: {json.dumps({'done': True})}\n\n"

    return StreamingResponse(
        token_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/suggestions")
async def get_suggestions(context_type: Optional[str] = None):
    """Return domain-specific quick suggestions."""
    domain_suggestions = {
        "soil": [
            "What does a soil pH of 4.2 mean for my tea?",
            "How do I improve soil nitrogen levels?",
            "Why is my soil moisture too high?",
            "Best organic fertilizers for tea plants?",
            "How often should I test soil?",
            "Signs of potassium deficiency in tea?",
        ],
        "leaf": [
            "What are early signs of Blister Blight?",
            "How do I treat Red Rust disease?",
            "What's the best fungicide schedule?",
            "How to tell if a leaf is ready for harvest?",
            "Difference between P+1 and P+2 flush?",
            "Organic alternatives to copper fungicides?",
        ],
        "climate": [
            "How does humidity affect disease risk?",
            "Best temperature range for fast flush growth?",
            "How to protect tea from frost?",
            "Does rainfall timing affect harvest quality?",
            "How to manage drought stress in tea?",
            "UV index and sunburn on tea leaves?",
        ],
        "yield": [
            "Which blocks are ready for harvest?",
            "How do I improve kg per hectare output?",
            "What affects flush cycle length?",
            "How to plan labor for harvest week?",
            "Expected yield for this season?",
            "How to read yield prediction confidence?",
        ],
        "powder": [
            "What makes BOPF grade tea powder?",
            "How does withering time affect grade?",
            "Why is my powder coming out too dusty?",
            "How to improve color and brightness?",
            "Temperature during firing and its effect?",
            "How field disease affects factory grade?",
        ],
    }
    suggestions = domain_suggestions.get(
        context_type or "",
        [
            "What are the symptoms of Red Rust disease?",
            "How do I improve tea leaf quality?",
            "What's the best time to harvest tea?",
            "How to prevent Blister Blight?",
            "What soil pH is ideal for tea?",
            "How often should I fertilize tea plants?",
            "What causes yellowing of tea leaves?",
            "How to manage pests organically?",
        ],
    )
    return {"suggestions": suggestions, "context_type": context_type}


@router.get("/fact")
async def get_tea_fact():
    """Return a random tea fact."""
    facts = [
        "All types of tea (black, green, white, oolong) come from the same plant: Camellia sinensis!",
        "Tea is the second most consumed beverage in the world after water.",
        "Ceylon tea from Sri Lanka is world-renowned for its quality and distinctive flavour.",
        "A single tea plant can live and produce leaves for over 100 years!",
        "The best time to harvest tea is during the 'flush' period when new growth appears.",
        "Tea contains L-theanine, an amino acid that promotes calm focus without drowsiness.",
        "Blister Blight spreads fastest in humid, misty conditions above 1,000m elevation.",
        "Two leaves and a bud — the golden standard for fine plucking quality.",
        "Sri Lanka produces about 300 million kg of tea per year, mostly for export.",
        "Red Rust (Cephaleuros virescens) is actually an algal parasite, not a fungus!",
    ]
    return {"fact": random.choice(facts)}


@router.get("/health")
async def chatbot_health():
    """Health check for iTeaBot service."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{OLLAMA_URL}/api/tags")
            ollama_available = response.status_code == 200
    except Exception:
        ollama_available = False

    return {
        "status": "healthy",
        "ollama_available": ollama_available,
        "model": OLLAMA_MODEL,
        "bot_name": "iTeaBot",
        "supported_domains": ["soil", "leaf", "climate", "yield", "powder"],
        "message": "iTeaBot is ready!" if ollama_available else "Running with built-in knowledge base",
    }


# ─── Fallback Responses ────────────────────────────────────────────────────────

def _fallback_response(message: str, context_type: Optional[str], context_data: Optional[Dict]) -> str:
    msg = message.lower()

    # Domain-specific fallbacks first
    if context_type == "soil":
        return _soil_fallback(msg, context_data)
    if context_type == "leaf":
        return _leaf_fallback(msg, context_data)
    if context_type == "climate":
        return _climate_fallback(msg, context_data)
    if context_type == "yield":
        return _yield_fallback(msg, context_data)
    if context_type == "powder":
        return _powder_fallback(msg, context_data)

    # General keyword fallback
    if any(w in msg for w in ["disease", "rust", "blight", "sick", "spot"]):
        return _leaf_fallback(msg, None)
    if any(w in msg for w in ["soil", "ph", "nutrient", "nitrogen", "potassium"]):
        return _soil_fallback(msg, None)
    if any(w in msg for w in ["weather", "rain", "temperature", "humidity", "climate"]):
        return _climate_fallback(msg, None)
    if any(w in msg for w in ["harvest", "yield", "flush", "pluck", "pick", "block"]):
        return _yield_fallback(msg, None)
    if any(w in msg for w in ["powder", "grade", "bopf", "bop", "dust", "factory"]):
        return _powder_fallback(msg, None)

    return """**Hi! I'm iTeaBot — your intelligent tea plantation assistant.**

I can help you across 5 key areas:

🌱 **Soil** — pH, nutrients, moisture, amendments
📸 **Leaf** — disease detection, treatment, harvest readiness
🌧️ **Climate** — temperature, humidity, rainfall insights
📊 **Yield** — production estimates and block planning
☕ **Powder** — grading, quality, and factory standards

Select a domain above or ask me anything about your plantation!"""


def _soil_fallback(msg: str, data: Optional[Dict]) -> str:
    data_section = ""
    if data:
        ph = data.get("ph") or data.get("soil_ph")
        moisture = data.get("moisture") or data.get("soil_moisture")
        nitrogen = data.get("nitrogen") or data.get("n_level")
        if ph:
            status = "✅ optimal" if 4.5 <= float(ph) <= 5.5 else ("⚠️ too low — risk of nutrient lockout" if float(ph) < 4.5 else "⚠️ too high — leach with sulfur")
            data_section += f"\n**Your current pH: {ph}** — {status}"
        if moisture:
            data_section += f"\n**Moisture: {moisture}%** — {'✅ good' if 40 <= float(moisture) <= 70 else '⚠️ check irrigation'}"
        if nitrogen:
            data_section += f"\n**Nitrogen: {nitrogen}** — {'✅ sufficient' if float(nitrogen) > 20 else '⚠️ apply urea or organic compost'}"

    return f"""**Soil Health for Tea Plantations**{data_section}

**Ideal conditions:**
- pH: **4.5–5.5** (acidic) — use sulfur to lower, lime to raise gradually
- Moisture: **40–70%** — well-drained but consistently moist
- Nitrogen: Apply 100–150 kg/ha/year split across 4 applications
- Organic matter: **> 2%** — mulch with pruned bush material

**Quick actions:**
1. Test soil every 6 months with a digital pH meter
2. Apply compost or cow dung between pruning cycles
3. Avoid waterlogging — install contour drains on slopes
4. Use green manure (Tithonia, Crotalaria) to naturally fix nitrogen"""


def _leaf_fallback(msg: str, data: Optional[Dict]) -> str:
    data_section = ""
    if data:
        disease = data.get("detected_disease") or data.get("disease_class")
        confidence = data.get("confidence")
        severity = data.get("severity")
        if disease and disease != "healthy":
            data_section += f"\n**Detected: {disease}**"
            if confidence:
                data_section += f" ({float(confidence)*100:.0f}% confidence)"
            if severity:
                data_section += f" — Severity: {severity}"

    return f"""**Leaf & Disease Analysis**{data_section}

**Common diseases in Sri Lankan tea:**

🔴 **Red Rust** *(Cephaleuros virescens)*
Symptoms: Orange-red powdery patches on upper leaf surface
Treatment: Copper oxychloride (3g/L) every 14 days × 3 applications
Prevention: Improve shade, reduce humidity, prune dense canopy

🟤 **Blister Blight** *(Exobasidium vexans)*
Symptoms: Pale water-soaked spots → blisters → white powdery underside
Treatment: Copper fungicide or Hexaconazole immediately; remove infected flushes
Prevention: Spray schedule every 7–10 days during wet season

**Harvest readiness:** Two leaves and a bud with no visible blight = harvest-ready
Use the **Disease Scanner** for real-time AI detection from a photo."""


def _climate_fallback(msg: str, data: Optional[Dict]) -> str:
    data_section = ""
    if data:
        temp = data.get("temperature")
        humidity = data.get("humidity")
        rainfall = data.get("rainfall") or data.get("rain")
        if temp:
            status = "✅ optimal" if 20 <= float(temp) <= 30 else ("⚠️ too cold — slow growth" if float(temp) < 20 else "⚠️ heat stress risk")
            data_section += f"\n**Temperature: {temp}°C** — {status}"
        if humidity:
            blight_risk = float(humidity) > 80
            data_section += f"\n**Humidity: {humidity}%** — {'🚨 high Blister Blight risk' if blight_risk else '✅ acceptable'}"
        if rainfall:
            data_section += f"\n**Recent rainfall: {rainfall}mm**"

    return f"""**Climate & Weather Insights**{data_section}

**Optimal conditions for tea growth:**
- Temperature: **20–30°C** (Uva highlands: 15–25°C for quality)
- Humidity: **50–70%** (above 80% → high Blister Blight risk)
- Annual rainfall: **1,500–2,500mm**, well distributed
- Elevation: 600–2,000m for premium Ceylon tea

**Weather-based action guide:**
- 🌧️ Heavy rain forecast → delay harvest, spray preventive fungicide
- ☀️ Dry spell > 2 weeks → activate drip irrigation, check moisture sensors
- 🌫️ Misty mornings + high humidity → increase fungicide frequency
- 🌡️ Temperature drop below 15°C → expect slower flush cycle (7 → 14+ days)"""


def _yield_fallback(msg: str, data: Optional[Dict]) -> str:
    data_section = ""
    if data:
        predicted = data.get("predicted_yield") or data.get("yield_kg")
        blocks_ready = data.get("blocks_ready") or data.get("ready_blocks")
        season = data.get("season")
        if predicted:
            data_section += f"\n**Predicted yield: {predicted} kg/ha**"
        if blocks_ready:
            data_section += f"\n**Blocks ready for harvest: {blocks_ready}**"
        if season:
            data_section += f"\n**Season: {season}**"

    return f"""**Yield Prediction & Harvest Planning**{data_section}

**Flush cycle guide:**
- **P+1**: 1 leaf + bud — too early, wait 3–5 days
- **P+2**: 2 leaves + bud — **optimal harvest point**
- **P+3**: 3 leaves + bud — slightly coarse, lower quality
- **P+4+**: Over-flush — significant quality loss, harvest immediately

**Yield optimization tips:**
1. Harvest every **7–10 days** during growing season
2. Early morning plucking (after dew) preserves leaf quality
3. Apply foliar urea (1%) to boost flush initiation after pruning
4. Monitor block-level sensor data for soil moisture trends
5. Target **2,000–4,000 kg/ha/year** for mid-elevation plantations

Use **Yield Prediction** in the dashboard for block-specific forecasts."""


def _powder_fallback(msg: str, data: Optional[Dict]) -> str:
    data_section = ""
    if data:
        grade = data.get("predicted_grade") or data.get("grade")
        quality_score = data.get("quality_score")
        if grade:
            data_section += f"\n**Predicted grade: {grade}**"
        if quality_score:
            data_section += f" (Quality score: {quality_score})"

    return f"""**Tea Powder Grading & Quality**{data_section}

**Sri Lanka export grade hierarchy:**
- **SFTGFOP** → Special Finest Tippy Golden Flowery Orange Pekoe (premium)
- **BOPF** → Broken Orange Pekoe Fannings (most common export grade)
- **BOP** → Broken Orange Pekoe (medium quality)
- **OP / Pekoe** → Whole leaf grades
- **Dust 1/2** → Finest particles, used in tea bags

**Field-to-factory quality factors:**
1. 🌱 Leaf quality: two-leaf-and-bud harvest → higher grade
2. ⏱️ Withering: 14–18 hours at 30°C → proper moisture reduction
3. 🌀 Rolling: cell rupture for oxidation — affects particle size
4. 🌡️ Firing: 90–95°C for 20 min → locks in colour and aroma
5. Disease-affected leaves lower grade — keep field infection below 5%

Use the **Powder Grading** feature for AI-based real-time classification."""
