import time

from fastapi import APIRouter, HTTPException

from models.schemas import RequestText, ResponseText

router = APIRouter()


# Text generation endpoint for typing practice
@router.post("/generate-text", response_model=ResponseText)
async def generate_text(post: RequestText):
    """
    Generate typing content backed by DynamoDB (types 1 & 2) and Bedrock (type 3).

    Types:
    - 1: Random words from DynamoDB cache
    - 2: Random sentence with the requested length (1-3 words)
    - 3: Bedrock-generated paragraphs returned by the agent runtime
    """
    from main import text_service

    if not text_service:
        raise HTTPException(status_code=500, detail="Text service not initialized")

    start_time = time.perf_counter()

    match post.type:
        case 1:
            words = text_service.get_random_words(post.count)
            text_result = " ".join(words)
        case 2:
            words = text_service.get_structured_sentence(post.count)
            text_result = " ".join(words)
        case 3:
            bedrock_payload = text_service.get_bedrock_paragraphs(post.count)
            paragraphs = [
                bedrock_payload.get("para1"),
                bedrock_payload.get("para2"),
                bedrock_payload.get("para3"),
            ]
            text_result = "\n\n".join(filter(None, paragraphs)) or ""
        case _:
            raise HTTPException(
                status_code=400,
                detail="Invalid type. Use 1 (words), 2 (sentences), or 3 (Bedrock paragraphs).",
            )

    execution_time = time.perf_counter() - start_time

    return ResponseText(
        type=post.type,
        count=post.count,
        text=text_result,
        taken=round(execution_time * 1000, 2),  # Convert to milliseconds
    )
