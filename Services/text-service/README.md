# Typing Practice Text Service (AWS Native)

FastAPI microservice that talks directly to DynamoDB and Bedrock to deliver random words, short sentences, and AI paragraphs for the typing practice web app. The former Lambda logic now lives inside the service, so there is no intermediate function to maintain.

## ✨ Features

- **Direct AWS integration** – FastAPI queries DynamoDB and Bedrock itself (no Lambda hop)
- **Multiple text types** – Random words, structured sentences (length 1-3), and Bedrock-generated paragraphs
- **In-memory caching** – Short-lived caches cut DynamoDB scans for repeated word/paragraph requests
- **Performance telemetry** – Every response includes execution time in milliseconds
- **Ready for Docker/Kubernetes** – Works locally or in containers with the same configuration

## 🧱 Architecture

```
Client  ->  FastAPI (this repo)  ->  DynamoDB (words / sentences)
								 ->  Bedrock Agent (paragraphs)
```

## ✅ Prerequisites

- Python 3.10+
- AWS credentials with permission to read the DynamoDB table and invoke the Bedrock agent
- (Optional) Docker if you prefer containerized dev

## ⚙️ Configuration

Create a `.env` file (or set real environment variables):

```
PORT=8000
AWS_REGION=us-east-1
DYNAMODB_TABLE_NAME=wordsntexts
BEDROCK_AGENT_ID=your-agent-id          # optional, only needed for type 3
BEDROCK_AGENT_ALIAS=your-agent-alias    # optional, only needed for type 3
```

> The DynamoDB table must contain the same schema as the original Lambda (`type` attribute for queries). Bedrock settings are optional unless you plan to request paragraphs (type 3).

## 🏃‍♀️ Run Locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

Open http://localhost:8000/docs for Swagger UI.

## 🧪 Quick Testing

With the server running:

```bash
./quick_test.sh          # bash script with curl + jq

python test_api.py       # interactive Python test suite
```

## 📡 Request Types

| Type | Description | Backing behavior |
|------|-------------|------------------|
| 1 | Random words | Scans DynamoDB cache and returns unique words |
| 2 | Random sentence | Selects a DynamoDB paragraph matching requested length (1‑3) and returns as word list |
| 3 | Bedrock paragraphs | Invokes the configured Bedrock agent (`para1`–`para3`) |

## 🧰 Useful Commands

```bash
uvicorn main:app --reload                     # Start dev server
python test_api.py                            # Full test suite
./quick_test.sh                               # Manual spot checks
aws dynamodb scan --table-name <name>         # Inspect source data quickly
aws bedrock-agent get-agent --agent-id <id>   # Check Bedrock agent status
```

## 🤔 Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Text service not initialized` | Ensure FastAPI started without errors and `.env` has region/table configured |
| 500 error fetching words/sentences | Verify DynamoDB table name + IAM perms, and that `type` items exist |
| Bedrock request fails | Confirm `BEDROCK_AGENT_ID`/`BEDROCK_AGENT_ALIAS` are set and the agent is active |
| AWS auth errors | Confirm `aws sts get-caller-identity` works and credentials have DynamoDB/Bedrock permissions |

## 📄 License

Add your preferred license information here.

## 🙋 Need help?

- Review `TESTING.md` for end-to-end test flows
- Check `/docs` for live API schema
- Use `test.py` for a minimal standalone FastAPI example
