# 🤖 Hostinger Automation Examples for Codex

Este documento contiene ejemplos prácticos de automatización que el agente **executor-codex** puede ejecutar usando el Hostinger API MCP.

---

## 📋 Tabla de Contenidos

1. [VPS Lifecycle Management](#vps-lifecycle-management)
2. [SSH Keys Automation](#ssh-keys-automation)
3. [Backup & Recovery](#backup--recovery)
4. [Firewall Management](#firewall-management)
5. [Domain Operations](#domain-operations)
6. [Docker Projects](#docker-projects)
7. [Monitoring & Alerts](#monitoring--alerts)
8. [Multi-Tenant Scenarios](#multi-tenant-scenarios)

---

## 🔄 VPS Lifecycle Management

### Scenario: Restart VPS after deployment

```typescript
// Codex workflow: Deploy → Backup → Restart

async function deployAndRestart(vpsId: number) {
  // 1. Create backup before restart
  const backup = await hostinger.VPS_createBackupV1({
    virtualMachineId: vpsId
  });
  
  console.log(`Backup created: ${backup.id}`);
  
  // 2. Reboot VPS
  await hostinger.VPS_rebootVirtualMachineV1({
    virtualMachineId: vpsId
  });
  
  console.log(`VPS ${vpsId} rebooting...`);
  
  // 3. Wait and verify
  await sleep(30000); // 30s
  
  const status = await hostinger.VPS_getVirtualMachineDetailsV1({
    virtualMachineId: vpsId
  });
  
  if (status.data.state === 'running') {
    console.log('✓ VPS is back online');
  } else {
    throw new Error(`VPS still in state: ${status.data.state}`);
  }
}
```

**When to use**: After code deployments requiring service restarts.

---

### Scenario: Scheduled maintenance window

```typescript
// Codex automation: Stop → Backup → Update → Start

async function maintenanceWindow(vpsId: number) {
  // 1. Notify via Slack
  await slack.postMessage({
    channel: '#ops',
    text: `🔧 Starting maintenance on VPS ${vpsId}`
  });
  
  // 2. Stop VPS gracefully
  await hostinger.VPS_stopVirtualMachineV1({
    virtualMachineId: vpsId
  });
  
  await waitForState(vpsId, 'stopped', 60);
  
  // 3. Create snapshot
  const backup = await hostinger.VPS_createBackupV1({
    virtualMachineId: vpsId
  });
  
  // 4. Start VPS
  await hostinger.VPS_startVirtualMachineV1({
    virtualMachineId: vpsId
  });
  
  await waitForState(vpsId, 'running', 120);
  
  // 5. Notify completion
  await slack.postMessage({
    channel: '#ops',
    text: `✅ Maintenance completed. Backup: ${backup.id}`
  });
}
```

**Trigger**: `tri-agent-scheduled.yml` every Sunday 3am

---

## 🔐 SSH Keys Automation

### Scenario: Rotate SSH keys monthly

```typescript
// Codex automation: Generate → Upload → Attach → Remove old

async function rotateSSHKey(vpsId: number) {
  // 1. Generate new SSH key locally (ed25519)
  const { publicKey, privateKey } = await generateEd25519Key();
  
  // 2. Upload new key to Hostinger
  const newKey = await hostinger.VPS_createPublicKeyV1({
    name: `deploy-key-${Date.now()}`,
    key: publicKey
  });
  
  console.log(`New key created: ${newKey.data.id}`);
  
  // 3. Attach to VPS
  await hostinger.VPS_attachPublicKeyV1({
    virtualMachineId: vpsId,
    ids: [newKey.data.id]
  });
  
  // 4. Update Vault with new private key
  await vault.kv.put('smarteros/ssh/deploy', {
    private_key: privateKey,
    public_key: publicKey,
    host: '89.116.23.167',
    user: 'smarteros',
    rotated_at: new Date().toISOString()
  });
  
  console.log('✓ New SSH key activated and stored in Vault');
  
  // 5. Test new key
  const testResult = await exec(`ssh -i <new_key> smarteros@89.116.23.167 'echo ok'`);
  
  if (testResult !== 'ok') {
    throw new Error('New SSH key test failed!');
  }
  
  // 6. Remove old keys (keep last 2)
  const allKeys = await hostinger.VPS_getAttachedPublicKeysV1({
    virtualMachineId: vpsId
  });
  
  const oldKeys = allKeys.data
    .sort((a, b) => b.created_at - a.created_at)
    .slice(2); // Keep 2 most recent
  
  for (const oldKey of oldKeys) {
    await hostinger.VPS_deletePublicKeyV1({
      publicKeyId: oldKey.id
    });
    console.log(`Removed old key: ${oldKey.id}`);
  }
}
```

**Trigger**: `tri-agent-scheduled.yml` first Sunday of each month

---

## 💾 Backup & Recovery

### Scenario: Daily automated backups

```typescript
// Codex automation: Backup → Verify → Cleanup old

async function dailyBackup(vpsId: number) {
  const timestamp = new Date().toISOString().split('T')[0];
  
  // 1. Create backup
  const backup = await hostinger.VPS_createBackupV1({
    virtualMachineId: vpsId,
    note: `daily-backup-${timestamp}`
  });
  
  console.log(`Backup created: ${backup.data.id}`);
  
  // 2. Wait for completion
  await waitForBackupComplete(backup.data.id, 600); // 10min timeout
  
  // 3. Store backup metadata in Vault
  await vault.kv.put(`smarteros/backups/${timestamp}`, {
    backup_id: backup.data.id,
    vps_id: vpsId,
    created_at: timestamp,
    size: backup.data.size,
    status: 'completed'
  });
  
  // 4. Cleanup backups older than 7 days
  const allBackups = await hostinger.VPS_getBackupsV1({
    virtualMachineId: vpsId
  });
  
  const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
  
  for (const oldBackup of allBackups.data) {
    if (new Date(oldBackup.created_at).getTime() < sevenDaysAgo) {
      console.log(`Deleting old backup: ${oldBackup.id}`);
      // Note: Delete API not in current spec, may need manual cleanup
    }
  }
  
  // 5. Send success notification
  await slack.postMessage({
    channel: '#ops',
    text: `✅ Daily backup completed\nBackup ID: ${backup.data.id}\nSize: ${backup.data.size}`
  });
}
```

**Trigger**: `tri-agent-scheduled.yml` daily 2am

---

### Scenario: Disaster recovery - Restore from backup

```typescript
// Codex emergency procedure: Restore → Verify → Alert

async function emergencyRestore(vpsId: number, backupId: number) {
  // 1. Alert team
  await slack.postMessage({
    channel: '#ops',
    text: `🚨 EMERGENCY: Initiating restore from backup ${backupId}`
  });
  
  // 2. Get backup details
  const backup = await hostinger.VPS_getBackupsV1({
    virtualMachineId: vpsId
  });
  
  const targetBackup = backup.data.find(b => b.id === backupId);
  
  if (!targetBackup) {
    throw new Error(`Backup ${backupId} not found`);
  }
  
  console.log(`Restoring from: ${targetBackup.created_at}`);
  
  // 3. Restore
  await hostinger.VPS_restoreBackupV1({
    virtualMachineId: vpsId,
    backupId: backupId
  });
  
  console.log('Restore initiated, waiting for completion...');
  
  // 4. Wait for VPS to be running
  await waitForState(vpsId, 'running', 600); // 10min
  
  // 5. Verify services
  const healthChecks = [
    { name: 'Vault', url: 'http://89.116.23.167:8200/v1/sys/health' },
    { name: 'Caddy', url: 'http://89.116.23.167:80' },
    { name: 'App', url: 'http://89.116.23.167:3000' }
  ];
  
  for (const check of healthChecks) {
    const result = await fetch(check.url);
    console.log(`${check.name}: ${result.status === 200 ? '✓' : '✗'}`);
  }
  
  // 6. Final notification
  await slack.postMessage({
    channel: '#ops',
    text: `✅ Restore completed from backup ${backupId}\nVPS is back online`
  });
}
```

**Trigger**: Manual via Slack command `/restore-vps <backup_id>`

---

## 🔥 Firewall Management

### Scenario: Apply security firewall rules

```typescript
// Codex automation: List firewalls → Activate production

async function activateProductionFirewall(vpsId: number) {
  // 1. List available firewalls
  const firewalls = await hostinger.VPS_listFirewallsV1();
  
  const prodFirewall = firewalls.data.find(f => f.name === 'production');
  
  if (!prodFirewall) {
    throw new Error('Production firewall not found');
  }
  
  // 2. Activate firewall
  await hostinger.VPS_activateFirewallV1({
    firewallId: prodFirewall.id,
    virtualMachineId: vpsId
  });
  
  console.log(`✓ Production firewall activated (${prodFirewall.id})`);
  
  // 3. Verify rules are active
  const vpsDetails = await hostinger.VPS_getVirtualMachineDetailsV1({
    virtualMachineId: vpsId
  });
  
  if (vpsDetails.data.active_firewall_id === prodFirewall.id) {
    await slack.postMessage({
      channel: '#security',
      text: `🔒 Production firewall activated on VPS ${vpsId}`
    });
  }
}
```

**Trigger**: After VPS setup or security updates

---

## 🌐 Domain Operations

### Scenario: Check domain availability for new tenant

```typescript
// Codex workflow: Check → Reserve → Configure

async function setupNewTenantDomain(tenantSlug: string) {
  const desiredDomain = `${tenantSlug}.smarterbot.cl`;
  
  // 1. Check availability
  const availability = await hostinger.domains_checkDomainAvailabilityV1({
    domain: tenantSlug,
    tlds: ['cl', 'com'],
    with_alternatives: false
  });
  
  console.log(`Domain availability:`, availability.data);
  
  // 2. If not using Hostinger for domains, just log
  // (Assuming smarterbot.cl is managed elsewhere)
  
  // 3. Enable WHOIS privacy (if applicable)
  if (availability.data.cl.available === false) {
    // Domain already registered, enable privacy
    await hostinger.domains_enablePrivacyProtectionV1({
      domain: desiredDomain
    });
  }
  
  // 4. Store domain config in Vault
  await vault.kv.put(`smarteros/tenants/${tenantSlug}/domain`, {
    domain: desiredDomain,
    configured_at: new Date().toISOString(),
    dns_status: 'pending'
  });
  
  console.log(`✓ Domain ${desiredDomain} configured for tenant`);
}
```

**Trigger**: New tenant onboarding workflow

---

## 🐳 Docker Projects

### Scenario: Update n8n Docker project

```typescript
// Codex automation: Get projects → Update n8n → Verify

async function updateN8nProject(vpsId: number) {
  // 1. List Docker projects
  const projects = await hostinger.VPS_getProjectsV1({
    virtualMachineId: vpsId
  });
  
  const n8nProject = projects.data.find(p => p.name === 'n8n');
  
  if (!n8nProject) {
    throw new Error('n8n Docker project not found');
  }
  
  console.log(`Found n8n project: ${n8nProject.id}`);
  
  // 2. Update project (pulls latest images)
  await hostinger.VPS_updateProjectV1({
    virtualMachineId: vpsId,
    projectName: 'n8n'
  });
  
  console.log('n8n project updated, containers restarting...');
  
  // 3. Wait and verify
  await sleep(30000); // 30s
  
  const healthCheck = await fetch('http://89.116.23.167:5678/healthz');
  
  if (healthCheck.ok) {
    console.log('✓ n8n is healthy after update');
    
    await slack.postMessage({
      channel: '#ops',
      text: '✅ n8n Docker project updated successfully'
    });
  } else {
    throw new Error('n8n health check failed after update');
  }
}
```

**Trigger**: `tri-agent-scheduled.yml` weekly Sunday 4am

---

## 📊 Monitoring & Alerts

### Scenario: Check VPS health and alert if issues

```typescript
// Codex monitoring: Get details → Check thresholds → Alert

async function monitorVPSHealth(vpsId: number) {
  // 1. Get VPS details
  const vps = await hostinger.VPS_getVirtualMachineDetailsV1({
    virtualMachineId: vpsId
  });
  
  const { state, cpu_usage, memory_usage, disk_usage } = vps.data;
  
  console.log(`VPS Status: ${state}`);
  console.log(`CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%`);
  
  // 2. Check thresholds
  const alerts = [];
  
  if (state !== 'running') {
    alerts.push(`⚠️ VPS is ${state} (expected: running)`);
  }
  
  if (cpu_usage > 80) {
    alerts.push(`⚠️ High CPU usage: ${cpu_usage}%`);
  }
  
  if (memory_usage > 85) {
    alerts.push(`⚠️ High memory usage: ${memory_usage}%`);
  }
  
  if (disk_usage > 90) {
    alerts.push(`🚨 CRITICAL: Disk usage ${disk_usage}% - cleanup needed!`);
  }
  
  // 3. Send alerts if any
  if (alerts.length > 0) {
    await slack.postMessage({
      channel: '#ops-alerts',
      text: `VPS Health Check Alert (ID: ${vpsId})\n\n${alerts.join('\n')}`
    });
    
    // If critical disk space, trigger cleanup
    if (disk_usage > 90) {
      await triggerDiskCleanup(vpsId);
    }
  } else {
    console.log('✓ VPS health check passed');
  }
  
  // 4. Store metrics in Vault for historical analysis
  await vault.kv.put(`smarteros/metrics/vps/${Date.now()}`, {
    vps_id: vpsId,
    timestamp: new Date().toISOString(),
    state,
    cpu_usage,
    memory_usage,
    disk_usage
  });
}
```

**Trigger**: `tri-agent-scheduled.yml` every 15 minutes

---

## 🏢 Multi-Tenant Scenarios

### Scenario: Spin up new VPS for enterprise tenant

```typescript
// Codex orchestration: Purchase → Setup → Configure → Deploy

async function provisionEnterpriseTenant(tenantData: {
  slug: string;
  plan: 'vps-1' | 'vps-2' | 'vps-4';
  region: 'eu' | 'us' | 'asia';
}) {
  const { slug, plan, region } = tenantData;
  
  // 1. Get template ID for Ubuntu 24.04
  const templates = await hostinger.VPS_getTemplatesV1();
  const ubuntu = templates.data.find(t => t.name.includes('Ubuntu 24.04'));
  
  // 2. Get data center ID
  const dataCenters = await hostinger.VPS_getDataCenterListV1();
  const dc = dataCenters.data.find(d => d.region === region);
  
  // 3. Purchase VPS (requires payment method)
  const purchase = await hostinger.VPS_purchaseNewVirtualMachineV1({
    item_id: plan,
    setup: {
      template_id: ubuntu.id,
      data_center_id: dc.id,
      hostname: `${slug}.smarterbot.cl`,
      install_monarx: true, // Malware scanner
      enable_backups: true
    }
  });
  
  const vpsId = purchase.data.virtual_machine_id;
  
  console.log(`VPS purchased: ${vpsId}, waiting for setup...`);
  
  // 4. Wait for initial state
  await waitForState(vpsId, 'initial', 300);
  
  // 5. Setup VPS
  await hostinger.VPS_setupPurchasedVirtualMachineV1({
    virtualMachineId: vpsId,
    template_id: ubuntu.id,
    data_center_id: dc.id,
    password: generateSecurePassword(),
    hostname: `${slug}.smarterbot.cl`,
    enable_backups: true
  });
  
  console.log('VPS setup initiated, waiting for running state...');
  
  await waitForState(vpsId, 'running', 600);
  
  // 6. Get VPS details (IP address)
  const vpsDetails = await hostinger.VPS_getVirtualMachineDetailsV1({
    virtualMachineId: vpsId
  });
  
  const { ip } = vpsDetails.data;
  
  // 7. Create SSH key for this tenant
  const { publicKey, privateKey } = await generateEd25519Key();
  
  const sshKey = await hostinger.VPS_createPublicKeyV1({
    name: `${slug}-deploy-key`,
    key: publicKey
  });
  
  await hostinger.VPS_attachPublicKeyV1({
    virtualMachineId: vpsId,
    ids: [sshKey.data.id]
  });
  
  // 8. Store tenant config in Vault
  await vault.kv.put(`smarteros/tenants/${slug}`, {
    vps_id: vpsId,
    ip,
    hostname: `${slug}.smarterbot.cl`,
    region,
    plan,
    ssh_key_id: sshKey.data.id,
    created_at: new Date().toISOString(),
    status: 'provisioned'
  });
  
  await vault.kv.put(`smarteros/tenants/${slug}/ssh`, {
    private_key: privateKey,
    public_key: publicKey,
    host: ip,
    user: 'root'
  });
  
  // 9. Activate production firewall
  await activateProductionFirewall(vpsId);
  
  // 10. Notify team
  await slack.postMessage({
    channel: '#ops',
    text: `✅ New enterprise VPS provisioned\n` +
          `Tenant: ${slug}\n` +
          `VPS ID: ${vpsId}\n` +
          `IP: ${ip}\n` +
          `Region: ${region}\n` +
          `Plan: ${plan}`
  });
  
  return { vpsId, ip };
}
```

**Trigger**: Manual via API call or Slack command `/provision-tenant <slug> <plan> <region>`

---

## 🎯 Helper Functions

```typescript
// Wait for VPS to reach target state
async function waitForState(
  vpsId: number, 
  targetState: string, 
  timeoutSeconds: number
): Promise<void> {
  const startTime = Date.now();
  const timeout = timeoutSeconds * 1000;
  
  while (Date.now() - startTime < timeout) {
    const vps = await hostinger.VPS_getVirtualMachineDetailsV1({
      virtualMachineId: vpsId
    });
    
    if (vps.data.state === targetState) {
      console.log(`✓ VPS reached state: ${targetState}`);
      return;
    }
    
    console.log(`Waiting for ${targetState}... (current: ${vps.data.state})`);
    await sleep(5000); // Check every 5s
  }
  
  throw new Error(`Timeout waiting for VPS to reach state: ${targetState}`);
}

// Wait for backup completion
async function waitForBackupComplete(
  backupId: number,
  timeoutSeconds: number
): Promise<void> {
  // Implementation depends on backup status API
  // May need to poll VPS_getBackupsV1 and check status
}

// Generate secure random password
function generateSecurePassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

// Generate ED25519 SSH key pair
async function generateEd25519Key(): Promise<{publicKey: string, privateKey: string}> {
  // Use node-forge or ssh-keygen via child_process
  // Return base64 encoded keys
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

## 📝 Notes

**Security Best Practices:**
- ✅ Always create backup before destructive operations
- ✅ Use Vault for all sensitive credentials
- ✅ Rotate SSH keys monthly
- ✅ Enable WHOIS privacy for all domains
- ✅ Activate firewall on all VPS instances
- ✅ Monitor disk/memory/cpu usage regularly

**Rate Limits:**
- Hostinger API rate limits not documented in official repo
- Implement exponential backoff on 429 responses
- Use queues for bulk operations

**Error Handling:**
- All API calls should have try/catch with Slack alerts
- Log all errors to `smarteros/logs/codex/errors`
- Implement retry logic with backoff

**Monitoring:**
- Store all metrics in Vault for historical analysis
- Set up alerts for critical thresholds (disk > 90%, memory > 85%)
- Weekly reports sent to #ops channel

---

**Last updated**: 2025-11-16  
**Agent**: executor-codex  
**MCP Provider**: hostinger-api-mcp v1.0
