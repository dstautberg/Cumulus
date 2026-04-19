#!/bin/bash
cd "$(dirname "$0")/.." || exit 1

python -m grpc_tools.protoc \
  -I./proto \
  --python_out=. \
  --grpc_python_out=. \
  ./proto/helloworld.proto
  