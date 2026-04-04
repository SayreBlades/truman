# Temperature Converter

Example project demonstrating truman devcontainer usage.

A simple temperature conversion tool used as a sandbox for the pi coding agent.

## Setup

```bash
# From the truman repo root, build images locally:
make build

# Set up credentials:
cd examples/temperature-converter
cp .devcontainer/.env.example .devcontainer/.env
# Edit .devcontainer/.env with your real API keys

# Open in VS Code → "Reopen in Container"
# Or:
devcontainer up --workspace-folder .
```

## Usage

```bash
uv run src/app.py 100 C F      # 100°C → 212.0°F
uv run src/app.py 72  F C      # 72°F  → 22.22°C
uv run src/app.py 300 K C      # 300K  → 26.85°C
```
