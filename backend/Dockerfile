FROM cgr.dev/chainguard/python:latest-dev AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM cgr.dev/chainguard/python:latest

WORKDIR /app
COPY --from=builder /home/nonroot/.local /home/nonroot/.local
ENV PATH=/home/nonroot/.local/bin:$PATH
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
