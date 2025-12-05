from pydantic import BaseModel, Field


class RequestText(BaseModel):
    """Request schema for generating text for typing practice"""

    type: int = Field(
        ...,
        description="Type of text generation: 1=words, 2=sentences, 3=Bedrock paragraphs",
    )
    count: int = Field(
        ...,
        description="Number of words (type 1), desired sentence length (type 2), or placeholder for Bedrock (type 3)",
    )


class ResponseText(RequestText):
    """Response schema with generated text and performance metrics"""

    text: str = Field(..., description="Generated text content for typing practice")
    taken: float = Field(default=0.0, description="Execution time in milliseconds")
