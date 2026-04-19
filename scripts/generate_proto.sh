#!/bin/bash
cd "$(dirname "$0")/.." || exit 1

echo "Generating helloworld.proto..."
python -m grpc_tools.protoc \
  -I./proto \
  --python_out=. \
  --grpc_python_out=. \
  ./proto/helloworld.proto

echo "Generating cumulus.proto..."
python -m grpc_tools.protoc \
  -I./proto \
  --python_out=. \
  --grpc_python_out=. \
  ./proto/cumulus.proto

echo "Done."
