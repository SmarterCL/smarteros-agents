#!/usr/bin/env bash
set -euo pipefail

# Configure Chatwoot branding, WhatsApp inbox, autoresponder, and webhook → n8n
# Requirements: CHATWOOT_BASE_URL, CHATWOOT_API_TOKEN, ACCOUNT_ID, N8N_WEBHOOK_URL

REQ=(CHATWOOT_BASE_URL CHATWOOT_API_TOKEN ACCOUNT_ID N8N_WEBHOOK_URL)
for v in "${REQ[@]}"; do
  if [[ -z "${!v:-}" ]]; then echo "Missing env: $v" >&2; exit 1; fi
done

hdr() { echo -H "api_access_token: $CHATWOOT_API_TOKEN" -H "Content-Type: application/json"; }

base="$CHATWOOT_BASE_URL/api/v1/accounts/$ACCOUNT_ID"

echo "🔧 Updating account branding (name: SmarterBOT)..."
curl -sS -X PUT $(hdr) \
  -d '{"name":"SmarterBOT","locale":"es"}' \
  "$base"
echo

echo "📦 Creating WhatsApp inbox (placeholder provider)…"
# NOTE: Requires Chatwoot WhatsApp provider credentials (e.g., 360dialog/Twilio)
# Replace payload fields with your provider configuration
curl -sS -X POST $(hdr) \
  -d '{
    "name": "WhatsApp Inbox",
    "channel": {"type": "api"}
  }' \
  "$base/inboxes" | jq '.'

echo "🤖 Creating automation rule: autoresponder (outside business hours)…"
curl -sS -X POST $(hdr) \
  -d '{
    "name": "Autoresponder fuera de horario",
    "description": "Respuesta automática fuera de horario",
    "event_name": "conversation_created",
    "conditions": [{"attribute_key": "business_hours","filter_operator": "equal_to","values": [false]}],
    "actions": [{"action_name": "send_message","action_params": {"message": "Hola 👋, gracias por escribir a SmarterBOT. Te responderemos a la brevedad."}}]
  }' \
  "$base/automation_rules" | jq '.'

echo "🔗 Creating webhook to n8n…"
curl -sS -X POST $(hdr) \
  -d "{\"url\": \"$N8N_WEBHOOK_URL\", \"subscriptions\": [\"conversation_created\", \"message_created\"]}" \
  "$base/webhooks" | jq '.'

echo "✅ Chatwoot setup complete"
