.PHONY: help generate build install clean lint test docker

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)SmarterOS - MCP + Protobuf + Redpanda Stack$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

install-tools: ## Install required tools (buf, protoc-gen-go-mcp)
	@echo "$(BLUE)📦 Installing buf...$(NC)"
	@go install github.com/bufbuild/buf/cmd/buf@latest
	@echo "$(BLUE)📦 Installing protoc-gen-go-mcp...$(NC)"
	@go install github.com/redpanda-data/protoc-gen-go-mcp/cmd/protoc-gen-go-mcp@latest
	@echo "$(BLUE)📦 Installing protoc plugins...$(NC)"
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
	@echo "$(GREEN)✅ All tools installed$(NC)"

generate: ## Generate code from protobuf definitions
	@echo "$(BLUE)🔄 Generating protobuf code...$(NC)"
	@buf dep update
	@buf generate
	@echo "$(GREEN)✅ Generated:$(NC)"
	@echo "  - gen/go/smarteros/v1/*.pb.go (protobuf)"
	@echo "  - gen/go/smarteros/v1/*_grpc.pb.go (gRPC)"
	@echo "  - gen/go/smarteros/v1/smarterosv1mcp/*.pb.mcp.go (MCP servers)"
	@echo "  - gen/go/smarteros/v1/*connect.go (Connect-RPC)"
	@echo "  - gen/ts/** (TypeScript)"
	@echo "  - gen/python/** (Python)"

lint: ## Lint protobuf definitions
	@echo "$(BLUE)🔍 Linting protobuf files...$(NC)"
	@buf lint
	@echo "$(GREEN)✅ Lint passed$(NC)"

format: ## Format protobuf definitions
	@echo "$(BLUE)📝 Formatting protobuf files...$(NC)"
	@buf format -w
	@echo "$(GREEN)✅ Formatted$(NC)"

breaking: ## Check for breaking changes
	@echo "$(BLUE)⚠️  Checking for breaking changes...$(NC)"
	@buf breaking --against '.git#branch=main'

build: generate ## Build the SmarterOS MCP server
	@echo "$(BLUE)🔨 Building smarteros-mcp-server...$(NC)"
	@cd cmd/smarteros-mcp-server && go build -o ../../bin/smarteros-mcp-server
	@chmod +x bin/smarteros-mcp-server
	@echo "$(GREEN)✅ Built: bin/smarteros-mcp-server$(NC)"

install: build ## Install binary to $GOPATH/bin
	@echo "$(BLUE)📦 Installing smarteros-mcp-server...$(NC)"
	@cp bin/smarteros-mcp-server $(GOPATH)/bin/
	@echo "$(GREEN)✅ Installed to $(GOPATH)/bin/smarteros-mcp-server$(NC)"

run: build ## Run the MCP server
	@echo "$(BLUE)🚀 Starting SmarterOS MCP Server...$(NC)"
	@LLM_PROVIDER=openai ./bin/smarteros-mcp-server

test: ## Run tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@go test ./... -v

clean: ## Clean generated files
	@echo "$(YELLOW)🧹 Cleaning generated files...$(NC)"
	@rm -rf gen/
	@rm -rf bin/
	@echo "$(GREEN)✅ Cleaned$(NC)"

docker-build: ## Build Docker image
	@echo "$(BLUE)🐳 Building Docker image...$(NC)"
	@docker build -t smarteros-mcp-server:latest -f Dockerfile .
	@echo "$(GREEN)✅ Built: smarteros-mcp-server:latest$(NC)"

docker-run: docker-build ## Run Docker container
	@echo "$(BLUE)🚀 Starting Docker container...$(NC)"
	@docker run --rm \
		-e LLM_PROVIDER=openai \
		-e VAULT_ADDR=http://vault.smarterbot.cl:8200 \
		-e REDPANDA_BROKERS=kafka.smarterbot.cl:19092 \
		smarteros-mcp-server:latest

# Integration targets
redpanda-topics: ## Create all Redpanda topics
	@echo "$(BLUE)📊 Creating Redpanda topics...$(NC)"
	@docker exec smarter-redpanda /bin/bash -c "rpk topic create \
		smarteros.events \
		shopify.webhooks \
		shopify.orders \
		shopify.products \
		shopify.inventory \
		whatsapp.inbound \
		whatsapp.outbound \
		whatsapp.delivery \
		n8n.automation.trigger \
		n8n.automation.result \
		n8n.automation.error \
		mcp.agent.actions \
		mcp.agent.responses \
		mcp.agent.telemetry \
		odoo.business.events \
		clerk.auth.events \
		analytics.events \
		tenant.provisioning \
		tenant.events \
		--brokers redpanda:9092"
	@echo "$(GREEN)✅ Topics created$(NC)"

deploy-vps: build ## Deploy to VPS via SSH
	@echo "$(BLUE)🚀 Deploying to VPS...$(NC)"
	@scp bin/smarteros-mcp-server root@smarterbot.cl:/usr/local/bin/
	@ssh root@smarterbot.cl "systemctl restart smarteros-mcp-server"
	@echo "$(GREEN)✅ Deployed$(NC)"

claude-config: ## Generate Claude Desktop MCP config
	@echo "$(BLUE)📝 Generating Claude Desktop config...$(NC)"
	@echo '{' > claude-mcp-config.json
	@echo '  "mcpServers": {' >> claude-mcp-config.json
	@echo '    "smarteros": {' >> claude-mcp-config.json
	@echo '      "command": "$(PWD)/bin/smarteros-mcp-server",' >> claude-mcp-config.json
	@echo '      "args": [],' >> claude-mcp-config.json
	@echo '      "env": {' >> claude-mcp-config.json
	@echo '        "LLM_PROVIDER": "openai",' >> claude-mcp-config.json
	@echo '        "VAULT_ADDR": "http://vault.smarterbot.cl:8200",' >> claude-mcp-config.json
	@echo '        "REDPANDA_BROKERS": "kafka.smarterbot.cl:19092"' >> claude-mcp-config.json
	@echo '      }' >> claude-mcp-config.json
	@echo '    }' >> claude-mcp-config.json
	@echo '  }' >> claude-mcp-config.json
	@echo '}' >> claude-mcp-config.json
	@echo "$(GREEN)✅ Config generated: claude-mcp-config.json$(NC)"
	@echo "$(YELLOW)💡 Add this to your Claude Desktop config$(NC)"

all: clean install-tools generate build ## Full rebuild from scratch

.DEFAULT_GOAL := help
