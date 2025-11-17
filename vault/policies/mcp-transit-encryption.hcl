# 🔐 Vault Transit Encryption Policy
# Permite a los agentes encriptar/desencriptar secretos usando Vault Transit

path "transit/encrypt/smarteros-secrets" {
  capabilities = ["update"]
}

path "transit/decrypt/smarteros-secrets" {
  capabilities = ["update"]
}

path "transit/datakey/plaintext/smarteros-secrets" {
  capabilities = ["update"]
}

path "transit/datakey/wrapped/smarteros-secrets" {
  capabilities = ["update"]
}

path "transit/rewrap/smarteros-secrets" {
  capabilities = ["update"]
}
