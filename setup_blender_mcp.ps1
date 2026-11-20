# ==============================================================================
# Auto-Setup Blender MCP untuk Windows + Antigravity IDE
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "=== [1/4] Memeriksa instalasi uv (uvx) ===" -ForegroundColor Cyan
$env:Path = "$env:USERPROFILE\.local\bin;$env:USERPROFILE\.cargo\bin;$env:Path"

if (-not (Get-Command "uvx" -ErrorAction SilentlyContinue)) {
    Write-Host "uv belum terinstal. Menginstal uv..." -ForegroundColor Yellow
    try {
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    } catch {
        winget install --id=astral-sh.uv -e --accept-source-agreements --accept-package-agreements
    }
    $env:Path = "$env:USERPROFILE\.local\bin;$env:USERPROFILE\.cargo\bin;$env:Path"
} else {
    Write-Host "uvx sudah terinstal: $((Get-Command uvx).Source)" -ForegroundColor Green
}

Write-Host "`n=== [2/4] Mengunduh & Menyalin addon.py (Auto-Start) ke folder Blender Add-ons ===" -ForegroundColor Cyan
$ScriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $env:TEMP }
$AddonSource = Join-Path $ScriptDir "blender_mcp_addon.py"

Write-Host "Mengunduh addon.py Auto-Start dari GitHub..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/PisangBatu/Short-/main/addon.py" -UseBasicParsing -OutFile $AddonSource
Write-Host "Berhasil mengunduh addon ke: $AddonSource" -ForegroundColor Green

$BlenderBase = Join-Path $env:APPDATA "Blender Foundation\Blender"
$InstalledCount = 0

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
        $InstalledCount++
    }
}

if ($InstalledCount -eq 0) {
    Write-Host "Info: Folder konfigurasi versi Blender di AppData belum ditemukan. Addon sudah tersimpan di: $AddonSource" -ForegroundColor Yellow
}

Write-Host "`n=== [3/4] Menjalankan setup otomatis mcp-for-blender (mengaktifkan addon & client) ===" -ForegroundColor Cyan
try {
    & uvx mcp-for-blender setup
} catch {
    Write-Host "Info: Setup otomatis selesai dengan catatan: $_" -ForegroundColor Yellow
}

# Timpa kembali blender_mcp.py dengan versi modifikasi Auto-Start kita (agar perubahan UI panel kita tetap ada)
if (Test-Path $BlenderBase) {
    $VersionDirs = Get-ChildItem -Path $BlenderBase -Directory | Where-Object { $_.Name -match '^\d+\.\d+$' }
    foreach ($vDir in $VersionDirs) {
        $DestFile = Join-Path $vDir.FullName "scripts\addons\blender_mcp.py"
        if (Test-Path (Split-Path -Parent $DestFile)) {
            Copy-Item -Path $AddonSource -Destination $DestFile -Force
        }
    }
}

Write-Host "`n=== [4/4] Mengonfigurasi MCP Server di Antigravity IDE ===" -ForegroundColor Cyan
$AntigravityDirs = @(
    "$env:USERPROFILE\.gemini\config",
    "$env:USERPROFILE\.gemini\antigravity",
    "$env:APPDATA\Antigravity\User"
)

$UvxCmd = if (Get-Command "uvx" -ErrorAction SilentlyContinue) { (Get-Command "uvx").Source } else { "$env:USERPROFILE\.local\bin\uvx.exe" }

foreach ($ConfigDir in $AntigravityDirs) {
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    $ConfigFileName = if ($ConfigDir -like "*\Antigravity\User") { "mcp.json" } else { "mcp_config.json" }
    $ConfigPath = Join-Path $ConfigDir $ConfigFileName

    $ConfigObj = @{ mcpServers = @{} }
    if (Test-Path $ConfigPath) {
        Copy-Item -Path $ConfigPath -Destination "$ConfigPath.bak" -Force
        try {
            $Existing = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            if ($Existing -and $Existing.mcpServers) {
                foreach ($prop in $Existing.mcpServers.PSObject.Properties) {
                    $ConfigObj.mcpServers[$prop.Name] = $prop.Value
                }
            }
        } catch {
            Write-Host "Info: Membuat file konfigurasi baru di $ConfigPath" -ForegroundColor Yellow
        }
    }

    $ConfigObj.mcpServers["blender"] = @{
        command = "cmd"
        args = @("/c", $UvxCmd, "mcp-for-blender")
        env = @{
            BLENDER_HOST = "localhost"
            BLENDER_PORT = "9876"
        }
    }

    $JsonOutput = $ConfigObj | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($ConfigPath, $JsonOutput, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Konfigurasi MCP berhasil disimpan ke: $ConfigPath" -ForegroundColor Green
}

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "SELESAI! Langkah terakhir:" -ForegroundColor Green
Write-Host "1. Buka aplikasi Blender (Server otomatis aktif di localhost:9876)" -ForegroundColor White
Write-Host "   - Cek di Blender: Tekan tombol 'N' -> tab 'MCP for Blender'" -ForegroundColor White
Write-Host "2. Restart aplikasi Antigravity IDE Anda." -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Green
