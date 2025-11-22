#!/usr/bin/env bash
set -euo pipefail

# Usage: ./upload-pass-to-vault.sh /absolute/path/to/pass.csv [--encrypt]
# Requires: VAULT_ADDR and VAULT_TOKEN exported
# Store path: smarteros/specs/pass (KV v2)
# If --encrypt is passed, uses transit key 'smarteros-secrets' to encrypt content before storing

if [[ ${1:-} == "" ]]; then
  echo "Error: provide path to CSV file" >&2
  echo "Usage: $0 /path/pass.csv [--encrypt]" >&2
  exit 1
fi

if [[ -z "${VAULT_ADDR:-}" || -z "${VAULT_TOKEN:-}" ]]; then
  echo "Error: VAULT_ADDR and VAULT_TOKEN must be set in env" >&2
  exit 1
fi

FILE_PATH="$1"
SHIFT_ENC=0
if [[ ${2:-} == "--encrypt" ]]; then
  SHIFT_ENC=1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: file not found: $FILE_PATH" >&2
  exit 1
fi

FILENAME="$(basename "$FILE_PATH")"
UPLOADED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Base64 encode file content to safely transport/store as JSON
BASE64_DATA=$(base64 -i "$FILE_PATH" | tr -d '\n')

DATA_KEY="data"
DATA_VALUE="$BASE64_DATA"

if [[ $SHIFT_ENC -eq 1 ]]; then
  # Encrypt using transit engine
  # Ensure transit is enabled and key exists: transit/keys/smarteros-secrets
  # API: POST transit/encrypt/<key> with {plaintext: base64}
  CIPHERTEXT=$(curl -sS \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$VAULT_ADDR/v1/transit/encrypt/smarteros-secrets" \
    -d "{\"plaintext\": \"$BASE64_DATA\"}" | jq -r '.data.ciphertext')

  if [[ -z "$CIPHERTEXT" || "$CIPHERTEXT" == "null" ]]; then
    echo "Error: transit encryption failed" >&2
    exit 1
  fi

  DATA_KEY="ciphertext"
  DATA_VALUE="$CIPHERTEXT"
fi

# Put into KV v2 path smarteros/specs/pass
vault kv put smarteros/specs/pass \
  filename="$FILENAME" \
  uploaded_at="$UPLOADED_AT" \
  "$DATA_KEY"="$DATA_VALUE"

echo "✅ Uploaded $FILENAME to Vault at smarteros/specs/pass ($UPLOADED_AT)"
if [[ $SHIFT_ENC -eq 1 ]]; then
  echo "ℹ️  Content stored as transit ciphertext. Decrypt via transit/decrypt/smarteros-secrets."
else
  echo "⚠️  Content stored base64-encoded under 'data'. Consider using --encrypt for extra security."
fi
