#!/bin/bash
# Change to repo root regardless of where the script is called from
cd "$(dirname "$0")/.." || exit 1

python -m grpc_tools.protoc \
  -I./proto \
  --python_out=. \
  --grpc_python_out=. \
  ./proto/helloworld.proto \
  ./proto/cumulus.proto
