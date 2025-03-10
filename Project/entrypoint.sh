#!/bin/sh
set -e  # Stop script on error

echo "Checking if GCP credentials exist in Kestra KV Store..."
if ! /app/kestra/bin/kestra kv get secret/gcp/credentials > /dev/null 2>&1; then
  echo "Storing Google credentials in Kestra KV Store..."
  /app/kestra/bin/kestra kv set secret/gcp/credentials --file /workspace/essencial_data/fair-canto-447119-p5-9091e1a7224d.json
fi

echo "Starting Kestra server..."
exec /app/kestra/bin/kestra server standalone
