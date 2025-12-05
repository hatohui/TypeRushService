"""
Lambda handler for Text Service
Uses Mangum to wrap FastAPI for AWS Lambda
"""
from mangum import Mangum
from main import app

# Create the Lambda handler
handler = Mangum(app, lifespan="off")
