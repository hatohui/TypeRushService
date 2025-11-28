"""
Test script for Typing Practice Text Service API
Run this after starting the server to test all endpoints
"""

import time

import requests

BASE_URL = "http://localhost:8000"


def print_test_header(test_name: str):
    """Print a formatted test header"""
    print("\n" + "=" * 60)
    print(f"🧪 TEST: {test_name}")
    print("=" * 60)


def print_result(response: requests.Response, start_time: float):
    """Print formatted test results"""
    elapsed = (time.time() - start_time) * 1000
    print(f"\n📊 Status Code: {response.status_code}")
    print(f"⏱️  Request Time: {elapsed:.2f}ms")

    try:
        data = response.json()
        print("📦 Response:")
        for key, value in data.items():
            if key == "text":
                # Truncate long text for display
                display_text = value[:100] + "..." if len(value) > 100 else value
                print(f"   {key}: {display_text}")
            else:
                print(f"   {key}: {value}")
    except Exception as e:
        print(f"❌ Error parsing response: {e}")
        print(f"   Raw response: {response.text}")


def test_health_check():
    """Test the root health check endpoint"""
    print_test_header("Health Check")
    start = time.time()

    try:
        response = requests.get(f"{BASE_URL}/")
        print_result(response, start)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


def test_generate_text(text_type: int, count: int, description: str):
    """Test text generation endpoint"""
    print_test_header(description)

    payload = {"type": text_type, "count": count}

    print(f"📤 Request: {payload}")
    start = time.time()

    try:
        response = requests.post(f"{BASE_URL}/api/generate-text", json=payload)
        print_result(response, start)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


def test_invalid_type():
    """Test with invalid type"""
    print_test_header("Invalid Type (Should Fail)")

    payload = {"type": 99, "count": 5}
    print(f"📤 Request: {payload}")
    start = time.time()

    try:
        response = requests.post(f"{BASE_URL}/api/generate-text", json=payload)
        print_result(response, start)
        return response.status_code == 400
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


def run_all_tests():
    """Run all API tests"""
    print("\n" + "🚀 Starting API Tests".center(60, "="))
    print(f"Base URL: {BASE_URL}")

    results = []

    # Test 1: Health Check
    results.append(("Health Check", test_health_check()))

    # Test 2: Type 1 - Words from Lambda (DynamoDB)
    results.append(
        (
            "Type 1: Words (10 words)",
            test_generate_text(1, 10, "Generate 10 Words via Lambda"),
        )
    )

    # Test 3: Type 2 - Sentence with specific length
    results.append(
        (
            "Type 2: Sentence (15 words)",
            test_generate_text(2, 15, "Generate Sentence with 15 Words via Lambda"),
        )
    )

    # Test 4: Type 3 - Bedrock paragraphs
    results.append(
        (
            "Type 3: Bedrock paragraphs",
            test_generate_text(3, 1, "Generate paragraphs from Bedrock via Lambda"),
        )
    )

    # Test 5: Invalid Type
    results.append(("Invalid Type Test", test_invalid_type()))

    # Print Summary
    print("\n" + "📋 TEST SUMMARY".center(60, "="))
    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")

    print("\n" + f"Results: {passed}/{total} tests passed".center(60, "="))

    return passed == total


if __name__ == "__main__":
    print("\n⚡ Typing Practice Text Service - API Test Suite")
    print("Make sure the server is running on http://localhost:8000")
    print("\nPress Enter to start testing...")
    input()

    success = run_all_tests()

    if success:
        print("\n🎉 All tests passed!")
    else:
        print("\n⚠️  Some tests failed. Check the output above.")
