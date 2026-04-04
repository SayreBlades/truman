# Temperature Converter

Example project demonstrating Truman's sandboxed devcontainer setup.

A simple temperature conversion tool used as a sandbox for the pi coding
agent. The `.devcontainer/` directory is a copy of `template/.devcontainer/`
with credentials already configured.

## Setup

```bash
# Set up credentials (interactive wizard):
cd examples/temperature-converter
.devcontainer/truman.sh init
```

## Running

```bash
# Start the devcontainer:
.devcontainer/truman.sh start

# Run pi inside the container:
.devcontainer/truman.sh run-pi

# Run pi with a single prompt:
.devcontainer/truman.sh run-pi -p "explain this codebase"
```

## VS Code

1. Open `examples/temperature-converter` in VS Code
2. **Cmd+Shift+P** → **Dev Containers: Reopen in Container**

The devcontainer starts both `gateway` and `agent` services. The agent is
network-isolated — all HTTPS traffic goes through the gateway, which
injects real credentials transparently.

## Teardown

```bash
# Stop containers (preserves pi session data):
.devcontainer/truman.sh stop

# Stop and wipe all volumes (clean slate):
.devcontainer/truman.sh stop -v
```

## Check Status

```bash
.devcontainer/truman.sh status
```

## Usage

```bash
uv run src/app.py 100 C F      # 100°C → 212.0°F
uv run src/app.py 72  F C      # 72°F  → 22.22°C
uv run src/app.py 300 K C      # 300K  → 26.85°C
```
