# ==============================================================================
# Auto-Setup Blender MCP untuk Windows + Antigravity IDE
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "=== [1/4] Memeriksa instalasi uv (uvx) ===" -ForegroundColor Cyan
if (-not (Get-Command "uvx" -ErrorAction SilentlyContinue)) {
    Write-Host "uv belum terinstal. Menginstal uv via winget..." -ForegroundColor Yellow
    try {
        winget install --id=astral-sh.uv -e --accept-source-agreements --accept-package-agreements
    } catch {
        Write-Host "Winget gagal, menginstal uv menggunakan installer resmi Astral..." -ForegroundColor Yellow
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    }
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
} else {
    Write-Host "uvx sudah terinstal: $((Get-Command uvx).Source)" -ForegroundColor Green
}

Write-Host "`n=== [2/4] Menyalin addon.py (Auto-Start) ke folder Blender Add-ons ===" -ForegroundColor Cyan
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AddonSource = Join-Path $ScriptDir "addon.py"

if (-not (Test-Path $AddonSource)) {
    Write-Host "Mengunduh addon.py terbaru..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py" -OutFile $AddonSource
}

$BlenderBase = Join-Path $env:APPDATA "Blender Foundation\Blender"
if (Test-Path $BlenderBase) {
    $VersionDirs = Get-ChildItem -Path $BlenderBase -Directory | Where-Object { $_.Name -match '^\d+\.\d+$' }
    foreach ($vDir in $VersionDirs) {
        $AddonsDir = Join-Path $vDir.FullName "scripts\addons"
        if (-not (Test-Path $AddonsDir)) {
            New-Item -ItemType Directory -Path $AddonsDir -Force | Out-Null
        }
        $DestFile = Join-Path $AddonsDir "blender_mcp.py"
        Copy-Item -Path $AddonSource -Destination $DestFile -Force
        Write-Host "Berhasil memasang addon Auto-Start ke Blender $($vDir.Name): $DestFile" -ForegroundColor Green
    }
} else {
    Write-Host "Folder AppData Blender belum ditemukan. Anda bisa install manual addon.py via Blender -> Edit -> Preferences -> Add-ons -> Install..." -ForegroundColor Yellow
}

Write-Host "`n=== [3/4] Mengaktifkan Addon secara otomatis di Blender (jika Blender ditemukan) ===" -ForegroundColor Cyan
try {
    & uvx mcp-for-blender setup
} catch {
    Write-Host "Info: Jalankan Blender dan centang 'Interface: MCP for Blender' di Edit -> Preferences -> Add-ons." -ForegroundColor Yellow
}

Write-Host "`n=== [4/4] Mengonfigurasi MCP Server di Antigravity IDE ===" -ForegroundColor Cyan
$AntigravityMcpPaths = @(
    "$env:USERPROFILE\.gemini\antigravity\mcp_config.json",
    "$env:APPDATA\Antigravity\User\mcp.json"
)

foreach ($ConfigPath in $AntigravityMcpPaths) {
    $ConfigDir = Split-Path -Parent $ConfigPath
    if (Test-Path $ConfigDir) {
        if (Test-Path $ConfigPath) {
            Copy-Item -Path $ConfigPath -Destination "$ConfigPath.bak" -Force
            Write-Host "Backup config lama dibuat: $ConfigPath.bak" -ForegroundColor DarkGray
        }
        $McpJson = @{
            mcpServers = @{
                "blender-mcp" = @{
                    command = "cmd"
                    args = @("/c", "uvx", "mcp-for-blender")
                    env = @{
                        BLENDER_HOST = "localhost"
                        BLENDER_PORT = "9876"
                    }
                }
            }
        } | ConvertTo-Json -Depth 5
        Set-Content -Path $ConfigPath -Value $McpJson -Encoding UTF8
        Write-Host "Konfigurasi MCP berhasil ditulis ke: $ConfigPath" -ForegroundColor Green
    }
}

Write-Host "`nSelesai! Silakan buka Blender (Server MCP akan otomatis menyala di port 9876) dan restart Antigravity IDE." -ForegroundColor Green
