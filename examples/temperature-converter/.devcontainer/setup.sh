#!/bin/bash
# initializeCommand — runs on HOST before containers start.
# Validates that credentials are configured.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

echo "🔍 Truman pre-flight check..."

# Check .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "❌ Missing .devcontainer/.env"
    echo ""
    echo "   Create it from the template:"
    echo "     cp .devcontainer/.env.example .devcontainer/.env"
    echo ""
    echo "   Then add your Anthropic credentials. Easiest way:"
    echo "     .devcontainer/sync-token.sh"
    echo ""
    exit 1
fi

# Check for at least one Anthropic credential
if ! grep -qE '^ANTHROPIC_(REFRESH_TOKEN|OAUTH_TOKEN|API_KEY)=.+' "$ENV_FILE" 2>/dev/null; then
    echo ""
    echo "❌ No Anthropic credentials found in .devcontainer/.env"
    echo ""
    echo "   Add at least one of:"
    echo "     ANTHROPIC_REFRESH_TOKEN=sk-ant-ort01-..."
    echo "     ANTHROPIC_OAUTH_TOKEN=sk-ant-oat01-..."
    echo "     ANTHROPIC_API_KEY=sk-ant-api03-..."
    echo ""
    echo "   Easiest: .devcontainer/sync-token.sh"
    echo ""
    exit 1
fi

# Check that placeholder values have been replaced
if grep -qE '^ANTHROPIC_REFRESH_TOKEN=sk-ant-ort01-\.\.\.' "$ENV_FILE" 2>/dev/null; then
    echo ""
    echo "❌ .devcontainer/.env still has placeholder values"
    echo ""
    echo "   Replace the '...' values with real credentials."
    echo "   Easiest: .devcontainer/sync-token.sh"
    echo ""
    exit 1
fi

echo "✅ Credentials configured"
