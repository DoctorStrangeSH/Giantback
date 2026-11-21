"""Build Giantback.rbxlx with Python 3; no plugins or downloaded assets."""
import math
import random
import xml.etree.ElementTree as X
from pathlib import Path

root = Path(__file__).resolve().parent
doc = X.Element("roblox", version="4")
serial = 0


def obj(parent, cls, name):
    global serial
    serial += 1
    node = X.SubElement(parent, "Item", {"class": cls, "referent": f"RBX{serial}"})
    props = X.SubElement(node, "Properties")
    X.SubElement(props, "string", name="Name").text = name
    return node


def prop(node, kind, key, val):
    X.SubElement(node.find("Properties"), kind, name=key).text = str(val)


def part(parent, name, pos, size, color, ball=False, cls="Part", tilt=0, yaw=0):
    n = obj(parent, cls, name)
    prop(n, "bool", "Anchored", "true")
    prop(n, "Color3uint8", "Color3uint8", int(color, 16) | 0xff000000)
    if ball:
        prop(n, "token", "shape", 0)
    for attr, kind, vals in [("size", "Vector3", size), ("CFrame", "CoordinateFrame", pos)]:
        el = X.SubElement(n.find("Properties"), kind, name=attr)
        for k, v in zip("XYZ", vals):
            X.SubElement(el, k).text = str(v)
        if attr == "CFrame":
            a = math.radians(tilt)
            y = math.radians(yaw)
            ca, sa, cy, sy = math.cos(a), math.sin(a), math.cos(y), math.sin(y)
            rotation = (
                ca * cy, -sa, ca * sy,
                sa * cy, ca, sa * sy,
                -sy, 0, cy,
            )
            for i, v in enumerate(rotation):
                X.SubElement(el, f"R{i//3}{i%3}").text = str(v)
    return n


w = obj(doc, "Workspace", "Workspace")
server_storage = obj(doc, "ServerStorage", "ServerStorage")
g = obj(server_storage, "Model", "HomeIslandTemplate")
part(w, "Lagoon", (0, -6, -40), (900, 2, 900), "65BFC3")

# The home island is a static, personal giantback turtle. It lives in ServerStorage
# and is cloned into a unique world slot for each player after the visual pass.
pivot = part(g, "IslandPivot", (0, 0, 0), (0.2, 0.2, 0.2), "FFFFFF")
for key in ("Transparency",):
    prop(pivot, "float", key, 1)
for key in ("CanCollide", "CanTouch", "CanQuery", "CastShadow"):
    prop(pivot, "bool", key, "false")
part(g, "Shell", (0, 4, 0), (39, 16, 32), "476F64", True)
part(g, "Meadow", (0, 10, 0), (34, 4, 28), "89B979")
part(g, "Head", (21, 7, 0), (14, 11, 13), "97C897", True)
for side in (-1, 1):
    part(g, "Eye", (24, 8.5, side * 5.4), (2.2, 2.4, 1.4), "233F46", True)
    part(g, "Glint", (24.35, 9, side * 5.95), (0.65, 0.65, 0.45), "FFF2CD", True)
    for x in (-11, 11):
        part(g, "Flipper", (x, 0, side * 12), (10, 5, 13), "719F86", True)
part(g, "Cottage", (-9, 15, -6), (9, 6, 7), "F3D299")
for dx in (-1, 1):
    part(g, "Roof", (-9 + dx * 2.65, 19, -6), (6.2, 0.8, 9), "BC6253", tilt=-dx * 25)
part(g, "Window", (-9, 15, -2.46), (3, 2.3, 0.2), "FFC469")
part(g, "Planter", (-8, 12.5, 5), (6, 1, 4), "805B48")
spawn = part(g, "HomeSpawn", (0, 12.15, 1), (5, 0.3, 5), "BDCD8C", cls="SpawnLocation")
prop(spawn, "bool", "Neutral", "true")
part(g, "TownBoard", (10, 13.2, 0), (2.8, 2.4, 0.8), "CE9661")
part(g, "LanternBase", (6, 12.35, 8), (3, 0.7, 3), "AA8964")
part(g, "Gangway", (0, 11.5, -17), (6, 1, 8), "B98F65")

rng = random.Random(143)
world_center_x, world_center_z = 0.0, -40.0
island_specs = [
    ("Grove", world_center_x, world_center_z, (150, 9, 150), "91B883", "6DA878"),
    ("Dusk", 57.4025, -178.5819, (70, 9, 60), "ABAC92", "AA83B3"),
]
for label, center_x, center_z, bank_size, bank_color, canopy in island_specs:
    model = obj(w, "Model", label)
    bank = part(model, "Bank", (center_x, 7, center_z), bank_size, bank_color)
    tree_count = 22 if label == "Grove" else 12
    for _ in range(tree_count):
        tx = center_x + rng.uniform(-bank_size[0] * 0.38, bank_size[0] * 0.38)
        tz = center_z + rng.uniform(-bank_size[2] * 0.36, bank_size[2] * 0.36)
        scale = rng.uniform(0.78, 1.18) if label == "Grove" else rng.uniform(0.72, 1.0)
        part(model, "Trunk", (tx, 15, tz), (1.8 * scale, 7 * scale, 1.8 * scale), "836851")
        part(model, "Crown", (tx, 20 + (scale - 1) * 4, tz), (9 * scale, 8 * scale, 9 * scale), canopy, True)
    for _ in range(34 if label == "Grove" else 20):
        fx = center_x + rng.uniform(-bank_size[0] * 0.43, bank_size[0] * 0.43)
        fz = center_z + rng.uniform(-bank_size[2] * 0.42, bank_size[2] * 0.42)
        part(model, "Bloom", (fx, 11.9, fz), (0.8, 0.8, 0.8), rng.choice(["F6C975", "F6E6BB", "D48488"]), True)
    if label == "Grove":
        public_spawn = part(model, "PublicSpawn", (center_x, 12.15, center_z + 5), (5, 0.3, 5), "BDCD8C", cls="SpawnLocation")
        prop(public_spawn, "bool", "Neutral", "true")
        prop(public_spawn, "float", "Transparency", 1)
        prop(public_spawn, "bool", "CanCollide", "false")
        prop(public_spawn, "bool", "CanQuery", "false")
    part(model, "Trail", (center_x, 11.54, center_z + 9), (4, 0.08, 18), "CBBD93")
    part(model, "Nest", (center_x, 12, center_z), (5, 1, 4), "BE996C", True)
    if label == "Grove":
        part(model, "Driftwood", (center_x + 10, 12.3, center_z + 8), (5, 1.6, 2), "A17B55", True)

# Eight fixed home islands surround a shared forest hub. Every island has its
# own permanent bridge; all bridges meet the same public Grove without crossing.
def radial_point(radius, angle):
    return (
        math.sin(angle) * radius,
        -40.0 - math.cos(angle) * radius,
    )

def add_radial_bridge(parent, name, angle, start_radius, end_radius):
    bridge = obj(parent, "Model", name)
    start_x, start_z = radial_point(start_radius, angle)
    end_x, end_z = radial_point(end_radius, angle)
    dx, dz = end_x - start_x, end_z - start_z
    length = math.sqrt(dx * dx + dz * dz)
    yaw = 180 - math.degrees(angle)
    segments = max(1, math.ceil(length / 8))
    plank_length = length / segments + 0.12
    for index in range(segments):
        t = (index + 0.5) / segments
        x, z = start_x + dx * t, start_z + dz * t
        part(bridge, "BridgeDeck", (x, 12.0, z), (5.2, 0.48, plank_length), "A87950", yaw=yaw)
    midpoint_x, midpoint_z = (start_x + end_x) / 2, (start_z + end_z) / 2
    local_x = (math.cos(math.radians(yaw)), -math.sin(math.radians(yaw)))
    for side in (-1, 1):
        rx = midpoint_x + local_x[0] * side * 2.65
        rz = midpoint_z + local_x[1] * side * 2.65
        part(bridge, "BridgeRail", (rx, 13.0, rz), (0.35, 1.55, length), "79583F", yaw=yaw)
        for index in range(0, segments + 1, max(1, math.ceil(segments / 7))):
            t = index / segments
            x, z = start_x + dx * t, start_z + dz * t
            px = x + local_x[0] * side * 2.65
            pz = z + local_x[1] * side * 2.65
            part(bridge, "BridgePost", (px, 13.1, pz), (0.55, 2.0, 0.55), "936847")
    for t in (0.28, 0.72):
        x, z = start_x + dx * t, start_z + dz * t
        part(bridge, "BridgeLamp", (x, 14.0, z), (0.55, 2.6, 0.55), "CE9661")

bridge_home = obj(w, "Model", "BridgeToGrove")
for slot_index in range(8):
    angle = math.pi * 2 * slot_index / 8
    add_radial_bridge(bridge_home, f"HomeBridge{slot_index + 1:02d}", angle, 219, 73)

# The Moon Grove is a small side-island connected to the shared forest hub.
bridge_dusk = obj(w, "Model", "BridgeToDusk")
add_radial_bridge(bridge_dusk, "MoonBridge", math.pi / 8, 73, 120)

storage = obj(doc, "ReplicatedStorage", "ReplicatedStorage")
for name in ("Fox", "Moth"):
    model = obj(storage, "Model", name)
    if name == "Fox":
        part(model, "Body", (0, 0, 0), (2.6, 2.5, 3), "D88653", True)
        part(model, "Muzzle", (0, -0.3, -1.2), (1.6, 1.2, 1.1), "FFDDAB", True)
        for side in (-1, 1):
            part(model, "Ear", (side * 0.8, 1.1, -0.4), (0.65, 1.4, 0.65), "BB654A", tilt=-side * 15)
            part(model, "Eye", (side * 0.62, 0.24, -1.25), (0.35, 0.39, 0.32), "293B40", True)
        part(model, "Tail", (0, 0.25, 1.8), (1.4, 1.4, 2.3), "F4C78B", True)
    else:
        part(model, "Body", (0, 0, 0), (0.75, 1.5, 1.8), "FFE1A1", True)
        for side in (-1, 1):
            part(model, "Wing", (side * 1.05, 0.3, 0), (2.3, 2, 0.65), "A68CD0", True, tilt=-side * 25)
            part(model, "Mark", (side * 1.35, 0.45, -0.32), (0.65, 0.65, 0.15), "FFE1A1", True)
    for child in model.findall("Item"):
        prop(child, "bool", "CanCollide", "false")

# Keep the gameplay scripts in one ServerScriptService and the client journal in StarterPlayerScripts.
server_service = obj(doc, "ServerScriptService", "ServerScriptService")
for filename in ("World.server.luau", "WorldVisuals.server.luau"):
    script = obj(server_service, "Script", filename.split(".")[0])
    prop(script, "ProtectedString", "Source", (root / filename).read_text(encoding="utf-8"))

starter_player = obj(doc, "StarterPlayer", "StarterPlayer")
starter_scripts = obj(starter_player, "StarterPlayerScripts", "StarterPlayerScripts")
client_script = obj(starter_scripts, "LocalScript", "Album")
prop(client_script, "ProtectedString", "Source", (root / "Album.client.luau").read_text(encoding="utf-8"))

hud_script = obj(starter_scripts, "LocalScript", "GiantbackHUD")
prop(hud_script, "ProtectedString", "Source", (root / "HUD.client.luau").read_text(encoding="utf-8"))

X.indent(doc)
X.ElementTree(doc).write(root / "Giantback.rbxlx", encoding="utf-8", xml_declaration=True)
