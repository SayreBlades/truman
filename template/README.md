# Truman Devcontainer Template

Copy the `.devcontainer/` directory into your project to get a sandboxed pi agent runtime.

## Quick Start

```bash
# 1. Copy .devcontainer/ into your project
cp -r .devcontainer/ /path/to/your-project/.devcontainer/

# 2. Sync your Anthropic credentials
cd /path/to/your-project
.devcontainer/sync-token.sh

# 3. (Optional) Add Brave/GitHub keys
#    Edit .devcontainer/.env

# 4. Open in VS Code → "Reopen in Container"
#    Or: devcontainer up --workspace-folder .
```

## What's Included

| File | Purpose | Git status |
|------|---------|------------|
| `devcontainer.json` | VS Code / devcontainer CLI config | Commit |
| `docker-compose.yml` | Gateway + agent container setup | Commit |
| `.env.agent` | Dummy API keys (safe) | Commit |
| `.env.example` | Template for real credentials | Commit |
| `.env` | Your real API keys | **Gitignore** |
| `setup.sh` | Pre-flight credential check | Commit |
| `sync-token.sh` | Extract token from host pi | Commit |

Add `.devcontainer/.env` to your project's `.gitignore`.

## Customization

### Adding project-specific tools

Create `.devcontainer/Dockerfile`:

```dockerfile
FROM ghcr.io/sayreblades/truman-agent:latest

# Example: add your project's dependencies
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
```

Then update `docker-compose.yml`:

```yaml
agent:
  # Replace this:
  # image: ghcr.io/sayreblades/truman-agent:latest
  # With this:
  build:
    context: .
    dockerfile: Dockerfile
```

### Baking in custom skills

```dockerfile
FROM ghcr.io/sayreblades/truman-agent:latest
COPY my-skills/ /opt/pi-staging/skills/my-skills/
```

### Without host pi installation

If pi is not installed on the host, remove the skill/prompt volume mounts from `docker-compose.yml`:

```yaml
# Remove these lines:
# - ~/.pi/agent/skills:/opt/pi-custom/skills:ro
# - ~/.pi/agent/prompts:/opt/pi-custom/prompts:ro
```

## CLI Usage (no IDE)

```bash
# Interactive pi session
docker compose -f .devcontainer/docker-compose.yml run --rm agent

# Single prompt
docker compose -f .devcontainer/docker-compose.yml run --rm agent pi -p "hello"

# Shell into agent
docker compose -f .devcontainer/docker-compose.yml run --rm agent bash
```
