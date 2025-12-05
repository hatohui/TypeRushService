from __future__ import annotations

import random
import time
import uuid
from typing import Any, Dict, List

import boto3
from boto3.dynamodb.conditions import Attr

CACHE_TTL_SECONDS = 300


class TextService:
    """Implements the original Lambda logic directly inside the FastAPI service."""

    def __init__(
        self,
        aws_region: str = "ap-southeast-1",
        dynamodb_table_name: str = "wordsntexts",
        bedrock_agent_id: str | None = None,
        bedrock_agent_alias: str | None = None,
    ):
        self.aws_region = aws_region
        self.table = boto3.resource("dynamodb", region_name=aws_region).Table(
            dynamodb_table_name
        )
        self.bedrock_agent_id = bedrock_agent_id
        self.bedrock_agent_alias = bedrock_agent_alias
        self.bedrock_client = (
            boto3.client("bedrock-agent-runtime", region_name=aws_region)
            if bedrock_agent_id and bedrock_agent_alias
            else None
        )

        self.cache: Dict[str, Any] = {
            "words": {"data": None, "timestamp": 0},
            "paragraphs": {},
        }

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def get_random_words(self, count: int) -> List[str]:
        safe_count = max(1, count)

        words = self._get_words_cache()
        if not words:
            raise RuntimeError("No words found in DynamoDB table")

        sample_size = min(safe_count, len(words))
        selected_words = random.sample(words, sample_size)
        return [item["content"] for item in selected_words]

    def get_structured_sentence(self, length: int) -> List[str]:
        safe_length = max(1, min(length, 3))
        paragraph = self._get_paragraph_cache(safe_length)
        if not paragraph:
            raise RuntimeError("No paragraph found for requested length")

        selected = random.choice(paragraph)
        return selected["content"].split()

    def get_bedrock_paragraphs(self, _: int) -> Dict[str, Any]:
        if not self.bedrock_client:
            raise RuntimeError("Bedrock agent not configured")

        session_id = str(uuid.uuid4())
        response = self.bedrock_client.invoke_agent(
            agentId=self.bedrock_agent_id,
            agentAliasId=self.bedrock_agent_alias,
            sessionId=session_id,
            inputText="trigger",
        )

        result = ""
        if "completion" in response:
            for event in response["completion"]:
                chunk = event.get("chunk")
                if chunk and "bytes" in chunk:
                    result += chunk["bytes"].decode("utf-8")

        parts = [part for part in result.split("\n\n") if part]

        return {
            "sessionId": session_id,
            "para1": parts[0] if len(parts) > 0 else "",
            "para2": parts[1] if len(parts) > 1 else "",
            "para3": parts[2] if len(parts) > 2 else "",
        }

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _is_cache_valid(self, timestamp: float) -> bool:
        return (time.time() - timestamp) < CACHE_TTL_SECONDS

    def _get_words_cache(self) -> List[Dict[str, Any]]:
        cache_entry = self.cache["words"]
        if cache_entry["data"] and self._is_cache_valid(cache_entry["timestamp"]):
            return cache_entry["data"]

        words = self._fetch_words_from_db()
        cache_entry["data"] = words
        cache_entry["timestamp"] = time.time()
        return words

    def _fetch_words_from_db(self) -> List[Dict[str, Any]]:
        words: List[Dict[str, Any]] = []
        response = self.table.scan(
            FilterExpression=Attr("type").eq("1"),
            ProjectionExpression="content",
        )
        words.extend(response.get("Items", []))

        while "LastEvaluatedKey" in response:
            response = self.table.scan(
                FilterExpression=Attr("type").eq("1"),
                ProjectionExpression="content",
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            words.extend(response.get("Items", []))

        return words

    def _get_paragraph_cache(self, length: int) -> List[Dict[str, Any]]:
        paragraph_cache = self.cache["paragraphs"].setdefault(
            length, {"data": None, "timestamp": 0}
        )

        if paragraph_cache["data"] and self._is_cache_valid(
            paragraph_cache["timestamp"]
        ):
            return paragraph_cache["data"]

        data = self._fetch_paragraph_from_db(length)
        paragraph_cache["data"] = data
        paragraph_cache["timestamp"] = time.time()
        return data

    def _fetch_paragraph_from_db(self, length: int) -> List[Dict[str, Any]]:
        paragraphs: List[Dict[str, Any]] = []
        response = self.table.scan(
            FilterExpression=Attr("type").eq("2") & Attr("length").eq(length),
            ProjectionExpression="content, #len",
            ExpressionAttributeNames={"#len": "length"},
        )
        paragraphs.extend(response.get("Items", []))

        while "LastEvaluatedKey" in response:
            response = self.table.scan(
                FilterExpression=Attr("type").eq("2") & Attr("length").eq(length),
                ProjectionExpression="content, #len",
                ExpressionAttributeNames={"#len": "length"},
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            paragraphs.extend(response.get("Items", []))

        return paragraphs
