"""
Ollama LLM Integration for Tea Plantation Chatbot
Provides expert tea knowledge using local Ollama models
"""

import httpx
import logging
from typing import List, Dict, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class OllamaChatbot:
    """Tea plantation expert chatbot powered by Ollama."""

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "llama3.2:3b",  # Lightweight model
        timeout: int = 60,
    ):
        """
        Initialize Ollama chatbot.

        Args:
            base_url: Ollama API endpoint
            model: Model name (llama3.2:3b, mistral, etc.)
            timeout: Request timeout in seconds
        """
        self.base_url = base_url
        self.model = model
        self.timeout = timeout
        self.client = httpx.AsyncClient(timeout=timeout)

        # System prompt with tea expertise
        self.system_prompt = """You are TeaBot, an expert AI assistant specializing in tea plantation management, tea production, and tea cultivation. You have deep knowledge about:

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

    async def chat(
        self,
        user_message: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        Send message to Ollama and get response.

        Args:
            user_message: User's question
            conversation_history: Previous messages [{role, content}, ...]

        Returns:
            AI response string
        """
        try:
            # Build messages array
            messages = [{"role": "system", "content": self.system_prompt}]

            # Add conversation history
            if conversation_history:
                messages.extend(conversation_history[-5:])  # Last 5 messages for context

            # Add current user message
            messages.append({"role": "user", "content": user_message})

            # Call Ollama API
            response = await self.client.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": messages,
                    "stream": False,
                },
            )

            if response.status_code == 200:
                data = response.json()
                return data["message"]["content"]
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return self._fallback_response(user_message)

        except httpx.ConnectError:
            logger.warning("Ollama not available, using fallback")
            return self._offline_fallback()
        except Exception as e:
            logger.error(f"Chat error: {e}")
            return self._fallback_response(user_message)

    async def stream_chat(
        self,
        user_message: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ):
        """
        Stream response from Ollama (for real-time typing effect).

        Yields:
            Chunks of the response as they arrive
        """
        try:
            messages = [{"role": "system", "content": self.system_prompt}]
            if conversation_history:
                messages.extend(conversation_history[-5:])
            messages.append({"role": "user", "content": user_message})

            async with self.client.stream(
                "POST",
                f"{self.base_url}/api/chat",
                json={"model": self.model, "messages": messages, "stream": True},
            ) as response:
                async for line in response.aiter_lines():
                    if line:
                        import json

                        data = json.loads(line)
                        if "message" in data:
                            yield data["message"]["content"]

        except Exception as e:
            logger.error(f"Stream error: {e}")
            yield self._fallback_response(user_message)

    def _fallback_response(self, user_message: str) -> str:
        """Provide fallback response when Ollama unavailable."""
        msg_lower = user_message.lower()

        # Disease-related queries
        if any(word in msg_lower for word in ["disease", "rust", "blight", "sick"]):
            return """Common tea diseases include:

**Red Rust**: Orange-red powdery spots on leaves. Treat with copper-based fungicides and improve air circulation.

**Blister Blight**: Water-soaked lesions that turn brown. Remove infected leaves and apply fungicide.

For accurate detection, use our AI disease scanner! Take a photo of the affected leaf."""

        # Growing conditions
        elif any(
            word in msg_lower
            for word in ["grow", "plant", "soil", "climate", "elevation"]
        ):
            return """Optimal tea growing conditions:

• **Climate**: 20-30°C (68-86°F) with 50-70% humidity
• **Rainfall**: 1,500-2,500mm annually, well-distributed
• **Soil**: Acidic (pH 4.5-5.5), well-drained, rich in organic matter
• **Elevation**: 600-2,000m for quality tea
• **Sunlight**: Partial shade ideal

Sri Lanka's hill country provides excellent conditions!"""

        # Harvesting
        elif any(word in msg_lower for word in ["harvest", "pluck", "pick"]):
            return """Tea harvesting tips:

**Plucking Standard**: Two leaves and a bud (fine plucking)

**Timing**:
• Flush cycle: Every 7-14 days during growing season
• Best time: Morning after dew evaporates
• Quality peak: During cooler months

**Technique**: Use clean, sharp plucking shears for tender leaves."""

        # General
        else:
            return """I'm TeaBot, your tea plantation expert! I can help with:

🌱 Tea cultivation and growing conditions
🦠 Disease identification and treatment
🌿 Harvesting techniques
☕ Tea processing methods
💧 Irrigation and fertilization
🛡️ Pest management

What would you like to know about tea farming?"""

    def _offline_fallback(self) -> str:
        """Response when Ollama is not running."""
        return """⚠️ **AI Assistant Offline**

I'm currently unable to connect to the AI server. However, you can still:

• Use the **Disease Scanner** to detect leaf diseases
• View your **Detection History**
• Check **IoT Sensor Data**
• Browse your **Plantation Dashboard**

Please ensure Ollama is running or check your internet connection. You can start Ollama with:
```
ollama serve
ollama run llama3.2:3b
```"""

    async def get_tea_fact(self) -> str:
        """Get a random interesting tea fact."""
        facts = [
            "Did you know? All types of tea (black, green, white, oolong) come from the same plant: Camellia sinensis!",
            "Tea is the second most consumed beverage in the world after water.",
            "Ceylon tea from Sri Lanka is world-renowned for its quality and distinctive flavor.",
            "A single tea plant can live and produce for over 100 years!",
            "The best time to harvest tea is during the 'flush' period when new growth appears.",
            "Tea contains L-theanine, an amino acid that promotes relaxation without drowsiness.",
        ]
        import random

        return random.choice(facts)

    async def close(self):
        """Close HTTP client."""
        await self.client.aclose()
