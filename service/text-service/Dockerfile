FROM python:3.12.11-alpine3.21

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["fastapi", "run", "./lambda_handler.py"]