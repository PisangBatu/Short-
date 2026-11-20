# Panduan Auto-Connect Blender MCP di Windows (Antigravity IDE)

Repositori ini berisi file addon Blender MCP yang sudah mendukung **Auto-Start Server** saat Blender dibuka, konfigurasi MCP untuk **Antigravity IDE** di Windows, serta script installer otomatis.

## Daftar File
- [`addon.py`](file:///home/antigravity/PisangBatu/Short-/addon.py) — Addon **MCP for Blender** dengan fitur **Auto-Start Server on Launch** (aktif secara default di port `9876`, dilengkapi kontrol checkbox di panel sidebar 3D View `N` dan di Add-on Preferences).
- [`mcp_config.json`](file:///home/antigravity/PisangBatu/Short-/mcp_config.json) — Konfigurasi MCP server untuk Antigravity IDE di Windows (menggunakan wrapper `cmd /c uvx mcp-for-blender` agar tidak terkena error `spawn uvx ENOENT`).
- [`setup_blender_mcp.ps1`](file:///home/antigravity/PisangBatu/Short-/setup_blender_mcp.ps1) — Script PowerShell untuk menginstal `uv`, memasang `addon.py` ke seluruh versi Blender di Windows secara otomatis, dan mengonfigurasi Antigravity IDE.

---

## Cara 1: Setup Otomatis (PowerShell)

Buka **PowerShell** di komputer Windows Anda pada folder project ini, lalu jalankan:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_blender_mcp.ps1
```

Atau jika ingin menjalankan one-liner resmi dari `mcp-for-blender` terlebih dahulu:

```powershell
irm https://www.mcp-for-blender.com/install.ps1 | iex
```
Kemudian timpa addon dengan [`addon.py`](file:///home/antigravity/PisangBatu/Short-/addon.py) dari repo ini agar toggle **Auto-Start Server on Launch** muncul langsung di panel sidebar Blender.

---

## Cara 2: Setup Manual Langkah demi Langkah

### 1. Install `uv` (Jika Belum Ada)
Buka PowerShell atau Command Prompt di Windows dan jalankan:
```powershell
winget install --id=astral-sh.uv -e
```

### 2. Pasang `addon.py` (Auto-Start) di Blender
1. Buka **Blender** di komputer Windows Anda.
2. Masuk ke menu **Edit → Preferences → Add-ons**.
3. Klik tombol dropdown di pojok kanan atas (atau tombol **Install from Disk...** / **Install...**) lalu pilih file [`addon.py`](file:///home/antigravity/PisangBatu/Short-/addon.py) dari repositori ini.
4. Pastikan kotak centang **Interface: MCP for Blender** sudah aktif (dicentang).
5. Klik ikon menu di pojok kiri bawah jendela Preferences lalu pilih **Save Preferences** agar addon selalu aktif setiap kali Blender dibuka.
6. Di viewport 3D Blender, tekan tombol **`N`** di keyboard untuk membuka sidebar kanan, lalu buka tab **MCP for Blender**:
   - Anda akan melihat status **`Connected on localhost:9876`** secara otomatis tanpa perlu klik tombol *Connect* lagi!
   - Checkbox **`Auto-Start Server on Launch`** sudah otomatis tercentang.

### 3. Tambahkan Konfigurasi MCP di Antigravity IDE (Windows)
1. Buka **Antigravity IDE** di komputer lokal Anda.
2. Buka pengaturan MCP Server (**MCP Settings** / file `mcp_config.json`).
3. Masukkan konfigurasi dari [`mcp_config.json`](file:///home/antigravity/PisangBatu/Short-/mcp_config.json) berikut:

```json
{
  "mcpServers": {
    "blender-mcp": {
      "command": "cmd",
      "args": [
        "/c",
        "uvx",
        "mcp-for-blender"
      ],
      "env": {
        "BLENDER_HOST": "localhost",
        "BLENDER_PORT": "9876"
      }
    }
  }
}
```
> **Catatan Windows:** Penggunaan `"command": "cmd"` dengan `"args": ["/c", "uvx", "mcp-for-blender"]` sangat disarankan di Windows agar Antigravity IDE yang dibuka dari Start Menu/Desktop tetap bisa menemukan `uvx` di `PATH` tanpa error `spawn uvx ENOENT`.

4. Simpan konfigurasi dan **Refresh / Restart** MCP server di Antigravity IDE.
