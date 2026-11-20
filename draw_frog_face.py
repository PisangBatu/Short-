import bpy
import math
import json
import socket
import sys


def get_frog_blender_code() -> str:
    """Return the Blender Python script string that builds a 3D Frog Face in Blender."""
    return '''
import bpy
import math

# 1. Buat Collection khusus untuk Muka Kodok agar rapi
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

# Materials
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

# 2. Kepala Utama (Lebar dan agak pipih khas kodok)
head = add_sphere("Frog_Head", (0.0, 0.0, 1.2), (1.55, 1.25, 1.05), mat_green)

# Dagu / Rahang Bawah (Hijau muda)
chin = add_sphere("Frog_Chin", (0.0, -0.18, 0.95), (1.35, 1.12, 0.82), mat_light_green)

# 3. Tonjolan Mata Besar di Atas Kepala (Kiri & Kanan)
for side, x_sign in [("L", -1.0), ("R", 1.0)]:
    # Kelopak / Soket Mata Hijau
    add_sphere(
        f"Frog_EyeSocket_{side}",
        (x_sign * 0.78, -0.15, 2.05),
        (0.55, 0.50, 0.55),
        mat_green
    )
    # Bola Mata Putih
    add_sphere(
        f"Frog_Eyeball_{side}",
        (x_sign * 0.78, -0.35, 2.08),
        (0.42, 0.38, 0.42),
        mat_eye_white
    )
    # Pupil Hitam
    add_sphere(
        f"Frog_Pupil_{side}",
        (x_sign * 0.78, -0.66, 2.10),
        (0.20, 0.12, 0.22),
        mat_pupil
    )
    # Pantulan Cahaya Mata (Eye Highlight)
    add_sphere(
        f"Frog_EyeHighlight_{side}",
        (x_sign * 0.68, -0.75, 2.22),
        (0.07, 0.04, 0.07),
        mat_eye_shine,
        subdiv=1
    )
    # Pipi Merona (Blush)
    add_sphere(
        f"Frog_Cheek_{side}",
        (x_sign * 1.18, -0.82, 1.12),
        (0.32, 0.18, 0.20),
        mat_cheek,
        rotation=(0.0, 0.0, x_sign * -0.35)
    )
    # Lubang Hidung (Nostril)
    add_sphere(
        f"Frog_Nostril_{side}",
        (x_sign * 0.22, -1.18, 1.48),
        (0.07, 0.05, 0.05),
        mat_mouth,
        subdiv=1
    )

# 4. Mulut Senyum Lebar Kodok (Menggunakan Curved Torus / Bezier Curve)
curve_data = bpy.data.curves.new("Frog_Smile_Curve", type='CURVE')
curve_data.dimensions = '3D'
curve_data.bevel_depth = 0.065
curve_data.bevel_resolution = 8
curve_data.use_fill_caps = True

spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(2)  # Total 3 titik: Kiri, Tengah, Kanan

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

# 5. Lidah Kecil yang Menjulur Lucu di Samping Senyum
add_sphere(
    "Frog_Tongue",
    (0.32, -1.24, 0.86),
    (0.22, 0.16, 0.14),
    mat_tongue,
    rotation=(0.35, 0.1, -0.2)
)

# 6. Atur Pencahayaan & Kamera agar langsung bagus dilihat di Viewport
if not any(o.type == 'LIGHT' for o in bpy.context.scene.objects):
    bpy.ops.object.light_add(type='SUN', location=(4.0, -5.0, 6.0), rotation=(math.radians(45), 0, math.radians(30)))
    sun = bpy.context.active_object
    sun.data.energy = 3.0

# Aktifkan Material Preview di semua 3D Viewport agar warna hijau kodok langsung terlihat
for window in bpy.context.window_manager.windows:
    for area in window.screen.areas:
        if area.type == 'VIEW_3D':
            for space in area.spaces:
                if space.type == 'VIEW_3D':
                    space.shading.type = 'MATERIAL'

print("Muka Kodok 3D berhasil dibuat!")
'''


def send_to_blender_mcp(host="localhost", port=9876):
    """Kirim perintah pembuatan Muka Kodok langsung ke socket server Blender MCP."""
    code = get_frog_blender_code()
    payload = {
        "type": "execute_code",
        "params": {
            "code": code
        }
    }
    try:
        with socket.create_connection((host, port), timeout=10) as sock:
            sock.sendall(json.dumps(payload).encode("utf-8"))
            response = sock.recv(65536).decode("utf-8")
            print("Respons dari Blender MCP:", response)
            return True
    except Exception as e:
        print(f"Gagal terhubung ke Blender MCP di {host}:{port}: {e}")
        return False


if __name__ == "__main__":
    # Jika dijalankan langsung di dalam Blender Text Editor:
    try:
        import bpy as _bpy
        if hasattr(_bpy, "context") and _bpy.context is not None:
            exec(get_frog_blender_code())
            sys.exit(0)
    except ImportError:
        pass

    # Jika dijalankan dari terminal Python di luar Blender, kirim lewat socket MCP (port 9876):
    send_to_blender_mcp()
