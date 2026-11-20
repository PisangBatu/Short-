# ==============================================================================
# Kirim Perintah Pembuatan 3D Muka Kodok ke Blender MCP (localhost:9876)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "Mengirim perintah 3D Muka Kodok ke Blender MCP di localhost:9876..." -ForegroundColor Cyan

$BlenderPythonCode = @'
import bpy
import math

# Hapus objek default Cube jika masih ada
if "Cube" in bpy.data.objects:
    bpy.data.objects.remove(bpy.data.objects["Cube"], do_unlink=True)

collection_name = "FrogFace_MCP"
if collection_name in bpy.data.collections:
    old_col = bpy.data.collections[collection_name]
    for obj in list(old_col.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
else:
    old_col = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(old_col)

def move_to_frog_col(obj):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    old_col.objects.link(obj)

def make_material(name, base_color, roughness=0.4, metallic=0.0, specular=0.5):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = specular
        elif "Specular" in bsdf.inputs:
            bsdf.inputs["Specular"].default_value = specular
    return mat

mat_green = make_material("Frog_Green", (0.14, 0.62, 0.16, 1.0), roughness=0.35)
mat_light_green = make_material("Frog_LightGreen", (0.45, 0.82, 0.30, 1.0), roughness=0.45)
mat_eye_white = make_material("Frog_EyeWhite", (0.98, 0.98, 0.96, 1.0), roughness=0.15)
mat_pupil = make_material("Frog_Pupil", (0.02, 0.02, 0.02, 1.0), roughness=0.08)
mat_eye_shine = make_material("Frog_EyeShine", (1.0, 1.0, 1.0, 1.0), roughness=0.0)
mat_cheek = make_material("Frog_Cheek", (0.95, 0.38, 0.45, 1.0), roughness=0.5)
mat_mouth = make_material("Frog_Mouth", (0.06, 0.18, 0.06, 1.0), roughness=0.4)
mat_tongue = make_material("Frog_Tongue", (0.92, 0.25, 0.35, 1.0), roughness=0.35)

def add_sphere(name, location, scale, material, rotation=(0, 0, 0), subdiv=2):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1.0, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.shade_smooth()
    if subdiv > 0:
        mod = obj.modifiers.new(name="Subsurf", type='SUBSURF')
        mod.levels = subdiv
        mod.render_levels = subdiv
    obj.data.materials.clear()
    obj.data.materials.append(material)
    move_to_frog_col(obj)
    return obj

# Kepala & Dagu Kodok
add_sphere("Frog_Head", (0.0, 0.0, 1.2), (1.55, 1.25, 1.05), mat_green)
add_sphere("Frog_Chin", (0.0, -0.18, 0.95), (1.35, 1.12, 0.82), mat_light_green)

# Mata, Pupil, Highlight, Pipi, dan Hidung (Kiri & Kanan)
for side, x_sign in [("L", -1.0), ("R", 1.0)]:
    add_sphere(f"Frog_EyeSocket_{side}", (x_sign * 0.78, -0.15, 2.05), (0.55, 0.50, 0.55), mat_green)
    add_sphere(f"Frog_Eyeball_{side}", (x_sign * 0.78, -0.35, 2.08), (0.42, 0.38, 0.42), mat_eye_white)
    add_sphere(f"Frog_Pupil_{side}", (x_sign * 0.78, -0.66, 2.10), (0.20, 0.12, 0.22), mat_pupil)
    add_sphere(f"Frog_EyeHighlight_{side}", (x_sign * 0.68, -0.75, 2.22), (0.07, 0.04, 0.07), mat_eye_shine, subdiv=1)
    add_sphere(f"Frog_Cheek_{side}", (x_sign * 1.18, -0.82, 1.12), (0.32, 0.18, 0.20), mat_cheek, rotation=(0.0, 0.0, x_sign * -0.35))
    add_sphere(f"Frog_Nostril_{side}", (x_sign * 0.22, -1.18, 1.48), (0.07, 0.05, 0.05), mat_mouth, subdiv=1)

# Mulut Senyum Lebar
curve_data = bpy.data.curves.new("Frog_Smile_Curve", type='CURVE')
curve_data.dimensions = '3D'
curve_data.bevel_depth = 0.065
curve_data.bevel_resolution = 8
curve_data.use_fill_caps = True

spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(2)
pts = [
    ((-0.88, -1.02, 1.18), (-1.05, -0.92, 1.28), (-0.55, -1.18, 0.98)),
    ((0.0,   -1.26, 0.95), (-0.40, -1.26, 0.95), (0.40,  -1.26, 0.95)),
    ((0.88,  -1.02, 1.18), (0.55,  -1.18, 0.98), (1.05,  -0.92, 1.28)),
]
for i, (co, hl, hr) in enumerate(pts):
    bp = spline.bezier_points[i]
    bp.co = co
    bp.handle_left = hl
    bp.handle_right = hr

smile_obj = bpy.data.objects.new("Frog_Smile", curve_data)
smile_obj.data.materials.append(mat_mouth)
move_to_frog_col(smile_obj)

# Lidah Kecil
add_sphere("Frog_Tongue", (0.32, -1.24, 0.86), (0.22, 0.16, 0.14), mat_tongue, rotation=(0.35, 0.1, -0.2))

# Ubah Viewport ke Material Preview agar warnanya langsung tampil
for window in bpy.context.window_manager.windows:
    for area in window.screen.areas:
        if area.type == 'VIEW_3D':
            for space in area.spaces:
                if space.type == 'VIEW_3D':
                    space.shading.type = 'MATERIAL'

print("Muka Kodok 3D berhasil dibuat lewat MCP!")
'@

$Payload = @{
    type = "execute_code"
    params = @{
        code = $BlenderPythonCode
    }
} | ConvertTo-Json -Depth 5 -Compress

try {
    $Client = New-Object System.Net.Sockets.TcpClient("localhost", 9876)
    $Stream = $Client.GetStream()
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Payload)
    $Stream.Write($Bytes, 0, $Bytes.Length)
    $Stream.Flush()

    $Buffer = New-Object byte[] 65536
    $Client.ReceiveTimeout = 10000
    $Read = $Stream.Read($Buffer, 0, $Buffer.Length)
    $Response = [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Read)
    $Stream.Close()
    $Client.Close()

    Write-Host "BERHASIL! Respons dari Blender MCP: $Response" -ForegroundColor Green
    Write-Host "Silakan lihat jendela 3D Viewport Blender Anda sekarang!" -ForegroundColor Green
} catch {
    Write-Host "Gagal mengirim ke localhost:9876. Pastikan aplikasi Blender sudah dibuka dan addon MCP for Blender sudah dicentang/Connected!" -ForegroundColor Red
    Write-Host "Detail error: $_" -ForegroundColor Yellow
}
