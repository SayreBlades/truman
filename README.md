# Truman

**Sandboxed [pi](https://github.com/badlogic/pi-mono) agent runtime with credential injection.**

Truman provides a set of containers that give any project a secure, sandboxed AI coding agent. It complies with the [devcontainer specification](https://containers.dev), so it works with VS Code, the `devcontainer` CLI, GitHub Codespaces, and any other devcontainer-compatible tool.

- 🔒 **Agent never sees real API keys** — gateway injects credentials transparently
- 🌐 **Network isolation** — agent cannot access internet directly, only through MITM proxy
- 🔄 **Auto-refreshing tokens** — OAuth tokens refresh automatically
- 📁 **Works on any project** — drop `.devcontainer/` into your repo and go

## Quick Start

### Add truman to your project

```bash
# 1. Copy the template into your project
cp -r template/.devcontainer/ /path/to/your-project/.devcontainer/

# 2. Sync your Anthropic credentials
cd /path/to/your-project
.devcontainer/sync-token.sh

# 3. Add to .gitignore
echo '.devcontainer/.env' >> .gitignore

# 4. Open in VS Code → "Reopen in Container"
#    Or: devcontainer up --workspace-folder .
```

### Prerequisites

- Docker Desktop
- [pi](https://github.com/badlogic/pi-mono) installed on the host (for OAuth login)

## Architecture

```mermaid
flowchart TB
    subgraph Docker["🐳 Docker Environment"]
        subgraph SandboxNet["🔒 sandbox network (internal only)"]
            Agent["🤖 Agent Container<br/>• pi + gh CLI + tools<br/>• HTTPS_PROXY=gateway:8080<br/>• Only dummy API keys<br/>• Trusts gateway CA cert"]
        end
        
        subgraph EgressNet["🌐 egress network"]
            Gateway["🛡️ Gateway Container<br/>• Python MITM proxy<br/>• Intercepts configured hosts<br/>• Injects real credentials from .env"]
        end
        
        Agent -->|":8080<br/>All HTTPS traffic"| Gateway
    end
    
    subgraph APIs["🌍 Internet APIs"]
        Anthropic["🧠 Anthropic API"]
        Brave["🔍 Brave Search"]
        GitHub["🐙 GitHub API"]
        Other["🌐 Other APIs"]
    end
    
    Gateway -->|"Real OAuth tokens"| Anthropic
    Gateway -->|"Real API key"| Brave
    Gateway -->|"Real PAT"| GitHub
    Gateway -->|"Blind TCP tunnel"| Other
```

### How It Works

1. **Agent** sends all HTTPS requests with dummy API keys through `HTTPS_PROXY` to the gateway
2. **Gateway** intercepts HTTPS traffic for configured hosts (Anthropic, Brave, GitHub) via MITM
3. Gateway strips dummy credentials and injects real ones from `.env` before forwarding
4. For non-configured hosts, gateway performs blind TCP tunneling (no credential injection)
5. Agent runs on internal-only network — all traffic must go through gateway
6. Gateway automatically refreshes OAuth tokens proactively and reactively on 401 responses

### Credential Flow

| Service        | Agent sees              | Gateway injects            |
|----------------|-------------------------|----------------------------|
| Anthropic API  | `sk-ant-oat01-DUMMY...` | Auto-refreshed OAuth token |
| Brave Search   | `BSAdummy...`           | Real `BRAVE_API_KEY`       |
| GitHub API/git | `ghp_DUMMY...`          | Real `GH_TOKEN`            |

## Project Structure

```
truman/
├── images/
│   ├── gateway/          # MITM credential-injection proxy
│   │   ├── Dockerfile
│   │   ├── gateway.py
│   │   └── requirements.txt
│   └── agent/            # Pi coding agent container
│       ├── Dockerfile
│       └── entrypoint.sh
├── template/             # Copy into your project
│   └── .devcontainer/
│       ├── devcontainer.json
│       ├── docker-compose.yml
│       ├── .env.example
│       ├── .env.agent
│       ├── setup.sh
│       └── sync-token.sh
├── examples/
│   └── temperature-converter/
└── docs/
```

## Container Images

Published to GitHub Container Registry:

| Image                                | Purpose                              |
|--------------------------------------|--------------------------------------|
| `ghcr.io/sayreblades/truman-gateway` | MITM proxy with credential injection |
| `ghcr.io/sayreblades/truman-agent`   | Pi coding agent with tools           |

## Skills & Prompts

Three ways to provide pi skills and prompts to the agent:

### (a) Baked into an extended image

```dockerfile
FROM ghcr.io/sayreblades/truman-agent:latest
COPY my-skills/ /opt/pi-staging/skills/my-skills/
COPY my-prompts/ /opt/pi-staging/prompts/
```

### (b) Mounted at runtime

In `docker-compose.yml`:

```yaml
agent:
  volumes:
    - ~/.pi/agent/skills:/opt/pi-custom/skills:ro
    - ~/.pi/agent/prompts:/opt/pi-custom/prompts:ro
```

The template includes this by default — if pi is installed on the host, its skills are automatically available.

### (c) Both

Baked skills load first, then mounted skills overlay on top. Same-name skills from the mount take priority.

## Devcontainer Compliance

Truman uses the [docker-compose variant](https://containers.dev/implementors/json_reference/) of the devcontainer spec:

- `devcontainer.json` → `"dockerComposeFile"` + `"service": "agent"`
- Works with VS Code Dev Containers extension
- Works with `devcontainer` CLI (`devcontainer up`, `devcontainer exec`)
- Works with GitHub Codespaces
- Works with DevPod

## Adding New Services

To add credential injection for a new API:

1. Add hostname + header rules to `INTERCEPT_RULES` in `images/gateway/gateway.py`
2. Add real credential to `.devcontainer/.env`
3. Add dummy value to `.devcontainer/.env.agent`

## CLI Usage (without IDE)

```bash
# Interactive pi session
docker compose -f .devcontainer/docker-compose.yml run --rm agent

# Single prompt
docker compose -f .devcontainer/docker-compose.yml run --rm agent pi -p "tell me a joke"

# Shell into agent
docker compose -f .devcontainer/docker-compose.yml run --rm agent bash
```

## Development (building truman itself)

```bash
make build          # Build gateway + agent images locally
make test-example   # Test with the temperature-converter example
make publish        # Push images to ghcr.io
make clean          # Remove locally-built images
```

## Design Documents

- [Architecture plan](docs/plan.md)
- [Phase 1: Docker container](docs/plan-phase-1.md)
- [Phase 2: Secret gateway + network isolation](docs/plan-phase-2.md)
