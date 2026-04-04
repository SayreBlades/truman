#!/bin/bash
# Sync Anthropic OAuth refresh token from host pi into .devcontainer/.env
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
AUTH_FILE="$HOME/.pi/agent/auth.json"

if [ ! -f "$AUTH_FILE" ]; then
    echo "❌ $AUTH_FILE not found."
    echo "   Run 'pi' and '/login' → Anthropic first."
    exit 1
fi

REFRESH=$(python3 -c "import json; print(json.load(open('$AUTH_FILE'))['anthropic']['refresh'])" 2>/dev/null)
if [ -z "$REFRESH" ]; then
    echo "❌ No Anthropic OAuth credentials in $AUTH_FILE."
    echo "   Run 'pi' and '/login' → Anthropic first."
    exit 1
fi

# Create .env from template if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
        echo "📄 Created .devcontainer/.env from template"
    else
        touch "$ENV_FILE"
    fi
fi

# Update or append the token
if grep -q '^ANTHROPIC_REFRESH_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    sed -i.bak "s|^ANTHROPIC_REFRESH_TOKEN=.*|ANTHROPIC_REFRESH_TOKEN=$REFRESH|" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
else
    echo "ANTHROPIC_REFRESH_TOKEN=$REFRESH" >> "$ENV_FILE"
fi

echo "✅ Synced ANTHROPIC_REFRESH_TOKEN into .devcontainer/.env"
