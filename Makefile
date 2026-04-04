.PHONY: help build build-gateway build-agent publish \
       test-example clean sync-token

IMAGE_PREFIX := ghcr.io/sayreblades
GATEWAY_IMAGE := $(IMAGE_PREFIX)/truman-gateway
AGENT_IMAGE := $(IMAGE_PREFIX)/truman-agent
VERSION := latest

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Image Build ──────────────────────────────────────────────────

build: build-gateway build-agent ## Build all container images

build-gateway: ## Build gateway image
	docker build -t $(GATEWAY_IMAGE):$(VERSION) images/gateway/

build-agent: ## Build agent image
	docker build -t $(AGENT_IMAGE):$(VERSION) images/agent/

# ── Publish ──────────────────────────────────────────────────────

publish: build ## Build and push images to ghcr.io
	docker push $(GATEWAY_IMAGE):$(VERSION)
	docker push $(AGENT_IMAGE):$(VERSION)

# ── Example Testing ──────────────────────────────────────────────

test-example: build ## Build images, then devcontainer up on example
	@echo "Testing temperature-converter example..."
	@cd examples/temperature-converter && \
		devcontainer up --workspace-folder . 2>&1 | tail -5
	@echo ""
	@echo "✅ Example container started. To interact:"
	@echo "   docker exec -it $$(docker ps -qf 'name=temperature.*agent') bash"
	@echo ""
	@echo "   To tear down:"
	@echo "   make clean-example"

clean-example: ## Stop example containers
	@cd examples/temperature-converter && \
		docker compose -f .devcontainer/docker-compose.yml down -v 2>/dev/null || true

# ── Utilities ────────────────────────────────────────────────────

sync-token: ## Sync Anthropic OAuth refresh token from host pi
	@AUTH_FILE="$$HOME/.pi/agent/auth.json"; \
	if [ ! -f "$$AUTH_FILE" ]; then \
		echo "Error: $$AUTH_FILE not found. Run 'pi' and '/login' first." >&2; exit 1; \
	fi; \
	REFRESH=$$(python3 -c "import json; print(json.load(open('$$AUTH_FILE'))['anthropic']['refresh'])" 2>/dev/null); \
	if [ -z "$$REFRESH" ]; then \
		echo "Error: No Anthropic OAuth credentials in $$AUTH_FILE." >&2; exit 1; \
	fi; \
	echo "Token: $${REFRESH:0:20}..."; \
	echo ""; \
	echo "To use in a project, run from the project directory:"; \
	echo "  .devcontainer/sync-token.sh"

clean: ## Remove locally-built truman images
	docker rmi $(GATEWAY_IMAGE):$(VERSION) 2>/dev/null || true
	docker rmi $(AGENT_IMAGE):$(VERSION) 2>/dev/null || true
	@echo "✅ Cleaned truman images"
