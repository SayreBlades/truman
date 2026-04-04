# Temperature Converter

Example project demonstrating Truman's **single-container** devcontainer setup (same structure as `template/`).

A simple temperature conversion tool used as a sandbox for the pi coding agent.

## Setup

```bash
# From the truman repo root, build images locally:
make build

# Set up credentials:
cd examples/temperature-converter
cp .devcontainer/.env.example .devcontainer/.env
# Edit .devcontainer/.env with your real API keys
# Or (recommended):
.devcontainer/sync-token.sh
```

## VS Code

1. Open `examples/temperature-converter` in VS Code
2. **Cmd+Shift+P** → **Dev Containers: Reopen in Container**

The devcontainer will run the sandboxed `agent` service (all network egress goes through the `gateway`).

## Devcontainer CLI

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . pi
```

## Teardown

```bash
docker compose -p temperature-converter_devcontainer -f .devcontainer/docker-compose.yml down
# Or wipe volumes:
docker compose -p temperature-converter_devcontainer -f .devcontainer/docker-compose.yml down -v
```

## Usage

```bash
uv run src/app.py 100 C F      # 100°C → 212.0°F
uv run src/app.py 72  F C      # 72°F  → 22.22°C
uv run src/app.py 300 K C      # 300K  → 26.85°C
```
