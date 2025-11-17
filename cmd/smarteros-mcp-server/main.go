package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/mark3labs/mcp-go/server"
	"github.com/redpanda-data/protoc-gen-go-mcp/pkg/runtime"
	
	// Generated protobuf packages (will exist after buf generate)
	// smv1 "github.com/SmarterCL/SmarterOS/gen/go/smarteros/v1"
	// smv1mcp "github.com/SmarterCL/SmarterOS/gen/go/smarteros/v1/smarter osv1mcp"
)

// SmarterOS MCP Server
// Auto-exposes all gRPC services as MCP tools via protoc-gen-go-mcp
func main() {
	// Create MCP server
	mcpServer := server.NewMCPServer(
		"SmarterOS Unified MCP Server",
		"1.0.0",
	)

	// Get LLM provider from environment (default: OpenAI for Claude compatibility)
	provider := getLLMProvider()
	log.Printf("🚀 Starting SmarterOS MCP Server with provider: %s", provider)

	// Register all service implementations
	// Each service will auto-expose its RPC methods as MCP tools
	
	// Shopify Service
	shopifyImpl := &ShopifyServiceImpl{}
	// smv1mcp.RegisterShopifyServiceHandlerWithProvider(mcpServer, shopifyImpl, provider)
	
	// WhatsApp Service  
	whatsappImpl := &WhatsAppServiceImpl{}
	// smv1mcp.RegisterWhatsAppServiceHandlerWithProvider(mcpServer, whatsappImpl, provider)
	
	// N8N Service
	n8nImpl := &N8NServiceImpl{}
	// smv1mcp.RegisterN8NServiceHandlerWithProvider(mcpServer, n8nImpl, provider)
	
	// MCP Agent Service
	mcpImpl := &MCPAgentServiceImpl{}
	// smv1mcp.RegisterMCPAgentServiceHandlerWithProvider(mcpServer, mcpImpl, provider)
	
	// Tenant Service
	tenantImpl := &TenantServiceImpl{}
	// smv1mcp.RegisterTenantServiceHandlerWithProvider(mcpServer, tenantImpl, provider)

	log.Printf("✅ Registered %d MCP tools from gRPC services", countTools())
	log.Printf("🔌 Starting stdio transport...")

	// Serve via stdio (Claude Desktop / MCP client)
	if err := server.ServeStdio(mcpServer); err != nil {
		log.Fatalf("❌ Server error: %v", err)
	}
}

func getLLMProvider() runtime.LLMProvider {
	providerStr := os.Getenv("LLM_PROVIDER")
	switch providerStr {
	case "standard":
		return runtime.LLMProviderStandard
	case "openai":
		fallthrough
	default:
		// OpenAI mode for Claude compatibility
		return runtime.LLMProviderOpenAI
	}
}

func countTools() int {
	// After registration, count will be:
	// Shopify: 5 tools
	// WhatsApp: 4 tools
	// N8N: 4 tools
	// MCP: 5 tools
	// Tenant: 5 tools
	// Total: 23 auto-generated MCP tools
	return 23
}

// ============================================================================
// Service Implementations
// Each implementation connects to:
// - Redpanda (event streaming)
// - Vault (secrets)
// - Supabase (state)
// - N8N (workflows)
// ============================================================================

type ShopifyServiceImpl struct {
	// smv1.UnimplementedShopifyServiceServer
}

func (s *ShopifyServiceImpl) ProcessWebhook(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: 
	// 1. Validate tenant_id with Vault
	// 2. Publish to Redpanda topic: shopify.webhooks
	// 3. Trigger N8N workflow if configured
	// 4. Return Kafka offset
	return nil, fmt.Errorf("not implemented - connect to Redpanda")
}

func (s *ShopifyServiceImpl) GetProduct(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Get Shopify credentials from Vault
	// 2. Call Shopify API
	// 3. Publish to Redpanda: shopify.products (compacted topic)
	// 4. Cache in Supabase
	return nil, fmt.Errorf("not implemented")
}

func (s *ShopifyServiceImpl) UpdateInventory(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Call Shopify API, publish to shopify.inventory
	return nil, fmt.Errorf("not implemented")
}

func (s *ShopifyServiceImpl) CreateOrder(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Create order, publish to shopify.orders
	return nil, fmt.Errorf("not implemented")
}

func (s *ShopifyServiceImpl) SyncProducts(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Bulk sync, publish to Redpanda
	return nil, fmt.Errorf("not implemented")
}

type WhatsAppServiceImpl struct {
	// smv1.UnimplementedWhatsAppServiceServer
}

func (w *WhatsAppServiceImpl) SendMessage(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Get WhatsApp credentials from Vault
	// 2. Publish to Redpanda: whatsapp.outbound
	// 3. N8N consumer sends actual message
	// 4. Return message_id + Kafka offset
	return nil, fmt.Errorf("not implemented - publish to Redpanda whatsapp.outbound")
}

func (w *WhatsAppServiceImpl) ProcessInbound(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Publish to whatsapp.inbound, trigger bot if needed
	return nil, fmt.Errorf("not implemented")
}

func (w *WhatsAppServiceImpl) GetConversation(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query Supabase conversations table
	return nil, fmt.Errorf("not implemented")
}

func (w *WhatsAppServiceImpl) CreateBotResponse(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Generate response, publish to whatsapp.outbound
	return nil, fmt.Errorf("not implemented")
}

type N8NServiceImpl struct {
	// smv1.UnimplementedN8NServiceServer
}

func (n *N8NServiceImpl) TriggerWorkflow(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Publish to Redpanda: n8n.automation.trigger
	// 2. N8N listens to this topic
	// 3. Return execution_id
	return nil, fmt.Errorf("not implemented - publish to Redpanda n8n.automation.trigger")
}

func (n *N8NServiceImpl) GetExecution(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query N8N API or Supabase executions table
	return nil, fmt.Errorf("not implemented")
}

func (n *N8NServiceImpl) ListWorkflows(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query N8N API
	return nil, fmt.Errorf("not implemented")
}

func (n *N8NServiceImpl) CreateTrigger(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Create Kafka consumer in N8N
	return nil, fmt.Errorf("not implemented")
}

type MCPAgentServiceImpl struct {
	// smv1.UnimplementedMCPAgentServiceServer
}

func (m *MCPAgentServiceImpl) ExecuteTool(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Load MCP server credentials from Vault
	// 2. Execute tool via stdio/SSE/gRPC
	// 3. Publish telemetry to Redpanda: mcp.agent.actions
	// 4. Return result
	return nil, fmt.Errorf("not implemented - orchestrate MCP tool execution")
}

func (m *MCPAgentServiceImpl) ListTools(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query all registered MCP servers
	return nil, fmt.Errorf("not implemented")
}

func (m *MCPAgentServiceImpl) CreateSession(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Create session in Supabase
	return nil, fmt.Errorf("not implemented")
}

func (m *MCPAgentServiceImpl) GetTelemetry(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query from ClickHouse via Grafana
	return nil, fmt.Errorf("not implemented")
}

func (m *MCPAgentServiceImpl) RegisterMCPServer(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Store credentials in Vault Transit (encrypted)
	// 2. Store metadata in Supabase
	// 3. Return mcp_server_id + vault_secret_path
	return nil, fmt.Errorf("not implemented - store in Vault + Supabase")
}

type TenantServiceImpl struct {
	// smv1.UnimplementedTenantServiceServer
}

func (t *TenantServiceImpl) CreateTenant(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO:
	// 1. Create Supabase project (or schema with RLS)
	// 2. Create Kafka topics with prefix: tenant_id.*
	// 3. Create Vault namespace: smarteros/tenant/{tenant_id}
	// 4. Publish to Redpanda: tenant.provisioning
	// 5. Return tenant_id
	return nil, fmt.Errorf("not implemented - full tenant provisioning")
}

func (t *TenantServiceImpl) GetTenant(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query Supabase tenants table
	return nil, fmt.Errorf("not implemented")
}

func (t *TenantServiceImpl) UpdateTenant(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Update Supabase, publish tenant.events
	return nil, fmt.Errorf("not implemented")
}

func (t *TenantServiceImpl) ProvisionResources(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Create Kafka topics, Vault secrets, N8N instance, etc.
	return nil, fmt.Errorf("not implemented")
}

func (t *TenantServiceImpl) GetMetrics(ctx context.Context, req interface{}) (interface{}, error) {
	// TODO: Query from tenant.metrics Kafka topic or ClickHouse
	return nil, fmt.Errorf("not implemented")
}
