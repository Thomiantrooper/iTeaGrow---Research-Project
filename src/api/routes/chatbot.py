"""
Tea Plantation Chatbot API Endpoints
Powered by Ollama LLM for expert tea knowledge
"""

from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime
import logging

from src.services.chatbot import OllamaChatbot
from configs.settings import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/chatbot", tags=["Chatbot"])

# Ollama chatbot instance (singleton)
_chatbot: Optional[OllamaChatbot] = None


def get_chatbot() -> OllamaChatbot:
    """Get or create chatbot instance."""
    global _chatbot
    if _chatbot is None:
        _chatbot = OllamaChatbot(
            base_url=settings.ollama.url,
            model=settings.ollama.model
        )
    return _chatbot


# === Pydantic Models ===


class Message(BaseModel):
    """Chat message."""

    role: str = Field(..., description="Message role: user or assistant")
    content: str = Field(..., description="Message content")
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)


class ChatRequest(BaseModel):
    """Chat request payload."""

    message: str = Field(..., min_length=1, max_length=1000, description="User question")
    conversation_history: Optional[List[Dict[str, str]]] = Field(
        default=None,
        description="Previous messages for context",
    )
    session_id: Optional[str] = Field(default=None, description="Session identifier")


class ChatResponse(BaseModel):
    """Chat response."""

    response: str = Field(..., description="AI response")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    model: str = Field(..., description="Model used")
    session_id: Optional[str] = None


class TeaFactResponse(BaseModel):
    """Tea fact response."""

    fact: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


# === API Endpoints ===


@router.post("/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    chatbot: OllamaChatbot = Depends(get_chatbot),
):
    """
    Send message to TeaBot and get response.

    **Example Request**:
    ```json
    {
      "message": "What causes Red Rust disease in tea?",
      "conversation_history": [
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi! I'm TeaBot..."}
      ]
    }
    ```

    **Example Response**:
    ```json
    {
      "response": "Red Rust is caused by the fungus...",
      "timestamp": "2026-02-01T10:30:00Z",
      "model": "llama3.2:3b"
    }
    ```
    """
    try:
        logger.info(f"Chat request: {request.message[:50]}...")

        # Get response from Ollama
        response = await chatbot.chat(
            user_message=request.message,
            conversation_history=request.conversation_history,
        )

        return ChatResponse(
            response=response,
            model=chatbot.model,
            session_id=request.session_id,
        )

    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get chatbot response: {str(e)}",
        )


@router.post("/chat/stream")
async def chat_stream(
    request: ChatRequest,
    chatbot: OllamaChatbot = Depends(get_chatbot),
):
    """
    Stream chat response for real-time typing effect.

    Returns Server-Sent Events (SSE) stream.
    """

    async def generate():
        try:
            async for chunk in chatbot.stream_chat(
                user_message=request.message,
                conversation_history=request.conversation_history,
            ):
                yield f"data: {chunk}\n\n"
        except Exception as e:
            logger.error(f"Stream error: {e}")
            yield f"data: Error: {str(e)}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
    )


@router.get("/fact", response_model=TeaFactResponse)
async def get_tea_fact(chatbot: OllamaChatbot = Depends(get_chatbot)):
    """
    Get a random interesting tea fact.

    Perfect for "Did you know?" feature in the app.
    """
    fact = await chatbot.get_tea_fact()
    return TeaFactResponse(fact=fact)


@router.get("/health")
async def health_check(chatbot: OllamaChatbot = Depends(get_chatbot)):
    """
    Check if Ollama is available and responding.

    Returns connection status and model info.
    """
    try:
        # Try to get a fact to test connection
        fact = await chatbot.get_tea_fact()
        return {
            "status": "healthy",
            "ollama_available": True,
            "model": chatbot.model,
            "base_url": chatbot.base_url,
            "message": "Chatbot is ready!",
        }
    except Exception as e:
        return {
            "status": "degraded",
            "ollama_available": False,
            "model": chatbot.model,
            "base_url": chatbot.base_url,
            "message": "Ollama not available, using fallback mode",
            "error": str(e),
        }


@router.post("/suggestions")
async def get_suggestions():
    """
    Get suggested questions for users.

    Returns common questions users can ask.
    """
    suggestions = [
        "What are the symptoms of Red Rust disease?",
        "How do I improve tea leaf quality?",
        "What's the best time to harvest tea?",
        "How to prevent Blister Blight?",
        "What soil pH is ideal for tea?",
        "How often should I fertilize tea plants?",
        "What causes yellowing of tea leaves?",
        "How to manage pests organically?",
    ]

    return {"suggestions": suggestions}
