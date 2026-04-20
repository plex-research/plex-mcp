# Plex Search MCP — Windows installer (PowerShell)
# Writes MCP server config for Claude Code
#
# Usage:
#   irm https://raw.githubusercontent.com/plex-research/plex-mcp/main/hooks/install.ps1 | iex
#   .\hooks\install.ps1
#   .\hooks\install.ps1 -Cell merck-kgaa -Auth apikey -Key YOUR_KEY

param(
    [string]$Cell = "",
    [string]$Auth = "",
    [string]$Key = ""
)

$ErrorActionPreference = "Stop"

if (-not $Cell) {
    Write-Host "Plex Search MCP Setup" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    $Cell = Read-Host "Customer cell name (press Enter for default production)"
}

if ($Cell) {
    $McpUrl = "https://$Cell.plexsearch.com/mcp"
    $ServerName = "plex-$Cell"
} else {
    $McpUrl = "https://plexsearch.com/mcp"
    $ServerName = "plex"
}

if (-not $Auth) {
    Write-Host ""
    Write-Host "Authentication method:"
    Write-Host "  1) API key (x-api-key header)"
    Write-Host "  2) OAuth (no key needed)"
    $choice = Read-Host "Choose [1/2]"
    switch ($choice) {
        "1" { $Auth = "apikey" }
        "2" { $Auth = "oauth" }
        default { Write-Error "Invalid choice"; exit 1 }
    }
}

if ($Auth -eq "apikey" -and -not $Key) {
    $Key = Read-Host "API key"
    if (-not $Key) { Write-Error "API key required"; exit 1 }
}

Write-Host ""
Write-Host "Server: $ServerName"
Write-Host "URL:    $McpUrl"
Write-Host "Auth:   $Auth"
Write-Host ""

$mcpEntry = @{ type = "http"; url = $McpUrl }
if ($Auth -eq "apikey") {
    $mcpEntry.headers = @{ "x-api-key" = $Key }
}

$configPath = Join-Path $env:USERPROFILE ".claude.json"

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    if (-not $config.mcpServers) {
        $config | Add-Member -NotePropertyName mcpServers -NotePropertyValue @{}
    }
} else {
    $config = @{ mcpServers = @{} }
}

$config.mcpServers.$ServerName = $mcpEntry
$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8

Write-Host "  Updated $configPath" -ForegroundColor Green
Write-Host ""
Write-Host "Done. Restart Claude Code, then test with:"
Write-Host '  Use the plex resolve tool to look up "aspirin"'
Write-Host ""
Write-Host "For other tools (ChatGPT, Gemini, etc.), add this MCP server manually:"
Write-Host "  URL:  $McpUrl"
Write-Host "  Type: HTTP"
if ($Auth -eq "apikey") {
    Write-Host "  Header: x-api-key: $Key"
}