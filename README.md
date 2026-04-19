# Cumulus

A multi-computer home backup solution.

## Requirements

- Python 3.9+
- Dependencies:

```bash
pip install -r requirements.txt
```

## Setup

Generate the gRPC code from the proto files:

```bash
bash scripts/generate_proto.sh
```

## Running

**gRPC Server** (run from repo root):

```bash
python -m server.main
```

**Client** (run from repo root, server must be running):

```bash
python -m client.main
```

**Admin Web Interface** (runs independently on port 8000):

```bash
python -m uvicorn admin.main:app --reload --port 8000
```

Then open http://localhost:8000 in your browser.

## Configuration

Create a `.env` file in the repo root to override defaults:

```bash
SERVER_PORT=50051
SERVER_IP=127.0.0.1
```

## Running Tests

```bash
python -m pytest tests/
```
