#!/bin/bash
# Disaster Recovery Testing - Automated Monthly Tests
# Verifica backups y capacidad de restore

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/smarteros/dr-tests"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/dr-test-$DATE.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Test 1: Verify backup files exist
test_backups_exist() {
  log "TEST 1: Verificando existencia de backups..."
  
  BACKUP_DIR="/backups"
  LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.tar.gz 2>/dev/null | head -1)
  
  if [ -z "$LATEST_BACKUP" ]; then
    error "No se encontraron backups en $BACKUP_DIR"
    return 1
  fi
  
  BACKUP_AGE=$(( ($(date +%s) - $(stat -f %m "$LATEST_BACKUP")) / 3600 ))
  
  if [ $BACKUP_AGE -gt 48 ]; then
    warn "Último backup tiene $BACKUP_AGE horas de antigüedad (>48h)"
  else
    log "✅ Último backup: $(basename $LATEST_BACKUP) ($BACKUP_AGE horas)"
  fi
  
  return 0
}

# Test 2: Verify backup integrity
test_backup_integrity() {
  log "TEST 2: Verificando integridad de backups..."
  
  BACKUP_DIR="/backups"
  LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.tar.gz 2>/dev/null | head -1)
  
  if tar tzf "$LATEST_BACKUP" > /dev/null 2>&1; then
    log "✅ Backup íntegro y válido"
    return 0
  else
    error "Backup corrupto: $LATEST_BACKUP"
    return 1
  fi
}

# Test 3: Test PostgreSQL backup restore (dry-run)
test_postgres_restore() {
  log "TEST 3: Probando restore de PostgreSQL (dry-run)..."
  
  # Create temporary test database
  docker exec smarter-postgres psql -U smarter -c "DROP DATABASE IF EXISTS test_restore;" 2>/dev/null || true
  docker exec smarter-postgres psql -U smarter -c "CREATE DATABASE test_restore;" || {
    error "No se pudo crear base de datos de prueba"
    return 1
  }
  
  # Find latest SQL backup
  BACKUP_DIR="/backups"
  LATEST_SQL=$(ls -t $BACKUP_DIR/postgres-*.sql.gz 2>/dev/null | head -1)
  
  if [ -z "$LATEST_SQL" ]; then
    warn "No se encontró backup SQL de PostgreSQL"
    return 1
  fi
  
  # Test restore
  gunzip -c "$LATEST_SQL" | docker exec -i smarter-postgres psql -U smarter -d test_restore > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    log "✅ Restore de PostgreSQL exitoso"
    # Count tables restored
    TABLE_COUNT=$(docker exec smarter-postgres psql -U smarter -d test_restore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    log "   Tablas restauradas: $TABLE_COUNT"
  else
    error "Fallo en restore de PostgreSQL"
    return 1
  fi
  
  # Cleanup
  docker exec smarter-postgres psql -U smarter -c "DROP DATABASE test_restore;" 2>/dev/null
  
  return 0
}

# Test 4: Test Docker volume restore (dry-run)
test_volume_restore() {
  log "TEST 4: Probando restore de volúmenes Docker..."
  
  BACKUP_DIR="/backups"
  LATEST_VOLUME=$(ls -t $BACKUP_DIR/volumes-*.tar.gz 2>/dev/null | head -1)
  
  if [ -z "$LATEST_VOLUME" ]; then
    warn "No se encontró backup de volúmenes"
    return 1
  fi
  
  # Create test volume
  docker volume create test_restore_volume > /dev/null 2>&1
  
  # Test extract
  docker run --rm -v test_restore_volume:/restore -v $BACKUP_DIR:/backup alpine \
    tar xzf /backup/$(basename $LATEST_VOLUME) -C /restore > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    log "✅ Restore de volúmenes exitoso"
  else
    error "Fallo en restore de volúmenes"
    docker volume rm test_restore_volume 2>/dev/null
    return 1
  fi
  
  # Cleanup
  docker volume rm test_restore_volume > /dev/null 2>&1
  
  return 0
}

# Test 5: Verify services health after simulated restart
test_services_health() {
  log "TEST 5: Verificando salud de servicios..."
  
  SERVICES=("smarter-postgres" "smarter-redis" "smarter-n8n" "smarter-odoo")
  FAILED=0
  
  for service in "${SERVICES[@]}"; do
    if docker ps | grep -q "$service"; then
      HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "unknown")
      if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "unknown" ]; then
        log "   ✅ $service: healthy"
      else
        error "   ❌ $service: $HEALTH"
        FAILED=$((FAILED + 1))
      fi
    else
      error "   ❌ $service: no está corriendo"
      FAILED=$((FAILED + 1))
    fi
  done
  
  if [ $FAILED -eq 0 ]; then
    log "✅ Todos los servicios están saludables"
    return 0
  else
    error "$FAILED servicios no están saludables"
    return 1
  fi
}

# Test 6: Verify Vault unsealed and accessible
test_vault_status() {
  log "TEST 6: Verificando estado de Vault..."
  
  if ! command -v vault &> /dev/null; then
    warn "Vault CLI no encontrado"
    return 1
  fi
  
  VAULT_STATUS=$(vault status -format=json 2>/dev/null || echo '{}')
  SEALED=$(echo "$VAULT_STATUS" | jq -r '.sealed // true')
  
  if [ "$SEALED" = "false" ]; then
    log "✅ Vault está unsealed y accesible"
    return 0
  else
    error "Vault está sealed o inaccesible"
    return 1
  fi
}

# Test 7: Calculate RTO (Recovery Time Objective)
test_rto_estimation() {
  log "TEST 7: Estimando RTO (Recovery Time Objective)..."
  
  # Simulate restore time based on backup size
  BACKUP_DIR="/backups"
  LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.tar.gz 2>/dev/null | head -1)
  
  if [ -z "$LATEST_BACKUP" ]; then
    warn "No se puede estimar RTO sin backup"
    return 1
  fi
  
  BACKUP_SIZE=$(stat -f %z "$LATEST_BACKUP" 2>/dev/null || stat -c %s "$LATEST_BACKUP")
  BACKUP_SIZE_MB=$((BACKUP_SIZE / 1024 / 1024))
  
  # Rough estimate: 100MB/min for restore + 10min overhead
  ESTIMATED_RTO=$(( (BACKUP_SIZE_MB / 100) + 10 ))
  
  log "   Tamaño backup: ${BACKUP_SIZE_MB}MB"
  log "   RTO estimado: ${ESTIMATED_RTO} minutos"
  
  if [ $ESTIMATED_RTO -gt 240 ]; then
    warn "RTO excede objetivo de 4 horas"
  else
    log "✅ RTO dentro del objetivo (<4 horas)"
  fi
  
  return 0
}

# Test 8: Verify backup retention policy
test_retention_policy() {
  log "TEST 8: Verificando política de retención de backups..."
  
  BACKUP_DIR="/backups"
  BACKUP_COUNT=$(ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null | wc -l)
  OLD_BACKUPS=$(find $BACKUP_DIR -name "*.tar.gz" -mtime +7 2>/dev/null | wc -l)
  
  log "   Backups totales: $BACKUP_COUNT"
  log "   Backups >7 días: $OLD_BACKUPS"
  
  if [ $OLD_BACKUPS -gt 0 ]; then
    warn "Hay $OLD_BACKUPS backups antiguos (>7 días) que deben limpiarse"
  else
    log "✅ Política de retención cumplida (7 días)"
  fi
  
  return 0
}

# Main execution
main() {
  log "=========================================="
  log "Disaster Recovery Test - $DATE"
  log "=========================================="
  
  PASSED=0
  FAILED=0
  WARNED=0
  
  # Run all tests
  TESTS=(
    "test_backups_exist"
    "test_backup_integrity"
    "test_postgres_restore"
    "test_volume_restore"
    "test_services_health"
    "test_vault_status"
    "test_rto_estimation"
    "test_retention_policy"
  )
  
  for test in "${TESTS[@]}"; do
    if $test; then
      PASSED=$((PASSED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
    echo "" | tee -a "$LOG_FILE"
  done
  
  # Summary
  log "=========================================="
  log "RESUMEN DE TESTS"
  log "=========================================="
  log "Total tests: ${#TESTS[@]}"
  log "Passed: $PASSED"
  log "Failed: $FAILED"
  log "Log: $LOG_FILE"
  log "=========================================="
  
  # Send notification to Slack
  if command -v curl &> /dev/null && [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"DR Test completed: $PASSED passed, $FAILED failed. Log: $LOG_FILE\"}" \
      2>/dev/null || true
  fi
  
  # Exit with error if any test failed
  if [ $FAILED -gt 0 ]; then
    exit 1
  fi
  
  exit 0
}

# Run main function
main
