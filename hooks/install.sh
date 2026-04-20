#!/bin/bash
# Plex Search MCP — universal installer
# Writes MCP server config for Claude Code, ChatGPT desktop, or any tool using ~/.claude.json
#
# Usage:
#   bash <(curl -s https://raw.githubusercontent.com/plex-research/plex-mcp/main/hooks/install.sh)
#   bash hooks/install.sh
#   bash hooks/install.sh --cell merck-kgaa --auth apikey --key YOUR_KEY
set -e

CELL=""
AUTH=""
API_KEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cell)   CELL="$2"; shift 2 ;;
    --auth)   AUTH="$2"; shift 2 ;;
    --key)    API_KEY="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: install.sh [--cell CELL] [--auth apikey|oauth] [--key API_KEY]"
      echo ""
      echo "  --cell   Customer cell name (e.g. merck-kgaa). Omit for default production."
      echo "  --auth   Authentication method: apikey or oauth"
      echo "  --key    API key value (required if --auth apikey)"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Interactive prompts if not provided via flags
if [ -z "$CELL" ]; then
  echo "Plex Search MCP Setup"
  echo "====================="
  echo ""
  read -rp "Customer cell name (press Enter for default production): " CELL
fi

if [ -n "$CELL" ]; then
  MCP_URL="https://${CELL}.plexsearch.com/mcp"
  SERVER_NAME="plex-${CELL}"
else
  MCP_URL="https://plexsearch.com/mcp"
  SERVER_NAME="plex"
fi

if [ -z "$AUTH" ]; then
  echo ""
  echo "Authentication method:"
  echo "  1) API key (x-api-key header)"
  echo "  2) OAuth (no key needed)"
  read -rp "Choose [1/2]: " AUTH_CHOICE
  case "$AUTH_CHOICE" in
    1) AUTH="apikey" ;;
    2) AUTH="oauth" ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
fi

if [ "$AUTH" = "apikey" ] && [ -z "$API_KEY" ]; then
  read -rp "API key: " API_KEY
  if [ -z "$API_KEY" ]; then
    echo "API key required for apikey auth"
    exit 1
  fi
fi

# Require node for safe JSON merging
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: 'node' is required to safely merge config into settings files."
  echo "       Install Node.js from https://nodejs.org and re-run."
  exit 1
fi

echo ""
echo "Server: $SERVER_NAME"
echo "URL:    $MCP_URL"
echo "Auth:   $AUTH"
echo ""

# Build MCP server entry as JSON
if [ "$AUTH" = "apikey" ]; then
  MCP_ENTRY=$(node -e "
    console.log(JSON.stringify({
      type: 'http',
      url: '$MCP_URL',
      headers: { 'x-api-key': '$API_KEY' }
    }))
  ")
else
  MCP_ENTRY=$(node -e "
    console.log(JSON.stringify({
      type: 'http',
      url: '$MCP_URL'
    }))
  ")
fi

# Write to Claude Code config (~/.claude.json)
write_claude_config() {
  local CONFIG="$HOME/.claude.json"
  if [ -f "$CONFIG" ]; then
    node -e "
      const fs = require('fs');
      const config = JSON.parse(fs.readFileSync('$CONFIG', 'utf8'));
      config.mcpServers = config.mcpServers || {};
      config.mcpServers['$SERVER_NAME'] = $MCP_ENTRY;
      fs.writeFileSync('$CONFIG', JSON.stringify(config, null, 2) + '\n');
    "
    echo "  Updated $CONFIG"
  else
    node -e "
      const fs = require('fs');
      const config = { mcpServers: { '$SERVER_NAME': $MCP_ENTRY } };
      fs.writeFileSync('$CONFIG', JSON.stringify(config, null, 2) + '\n');
    "
    echo "  Created $CONFIG"
  fi
}

write_claude_config

echo ""
echo "Done. Restart Claude Code, then test with:"
echo "  Use the plex resolve tool to look up \"aspirin\""
echo ""
echo "For other tools (ChatGPT, Gemini, etc.), add this MCP server manually:"
echo "  URL:  $MCP_URL"
echo "  Type: HTTP"
if [ "$AUTH" = "apikey" ]; then
  echo "  Header: x-api-key: $API_KEY"
fi