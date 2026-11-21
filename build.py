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


def part(parent, name, pos, size, color, ball=False, cls="Part", tilt=0):
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
            for i, v in enumerate((math.cos(a), -math.sin(a), 0, math.sin(a), math.cos(a), 0, 0, 0, 1)):
                X.SubElement(el, f"R{i//3}{i%3}").text = str(v)
    return n


w = obj(doc, "Workspace", "Workspace")
g = obj(w, "Model", "Mossback")
part(w, "Lagoon", (48, -6, 0), (460, 2, 300), "65BFC3")
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
part(g, "Helm", (10, 13.2, 0), (2, 2.4, 2), "CE9661")
part(g, "LanternBase", (6, 12.35, 8), (3, 0.7, 3), "AA8964")
part(g, "Gangway", (0, 11.5, -17), (6, 1, 8), "B98F65")

rng = random.Random(143)
for x, label, canopy in [(0, "Grove", "6DA878"), (100, "Dusk", "AA83B3")]:
    model = obj(w, "Model", label)
    part(model, "Bank", (x, 7, -40), (45, 9, 40), "91B883" if x == 0 else "ABAC92")
    for _ in range(10):
        tx = x + rng.choice([-1, 1]) * rng.uniform(8, 20)
        tz = rng.uniform(-58, -33)
        part(model, "Trunk", (tx, 15, tz), (1.8, 7, 1.8), "836851")
        part(model, "Crown", (tx, 20, tz), (9, 8, 9), canopy, True)
    for _ in range(20):
        fx, fz = x + rng.uniform(-20, 20), rng.uniform(-58, -24)
        part(model, "Bloom", (fx, 11.9, fz), (0.8, 0.8, 0.8), rng.choice(["F6C975", "F6E6BB", "D48488"]), True)
    part(model, "Trail", (x, 11.54, -31), (4, 0.08, 18), "CBBD93")
    part(model, "Nest", (x, 12, -40), (5, 1, 4), "BE996C", True)
    if label == "Grove":
        part(model, "Driftwood", (x + 10, 12.3, -32), (5, 1.6, 2), "A17B55", True)

# Permanent wooden bridges replace the old moving-island travel loop.
bridge_home = obj(w, "Model", "BridgeToGrove")
for i, z in enumerate((-14.5, -17.5, -20.5)):
    part(bridge_home, "BridgeDeck", (0, 12.0, z), (5.2, 0.48, 3.0), "A87950")
for side in (-1, 1):
    part(bridge_home, "BridgeRail", (side * 2.65, 13.0, -17.5), (0.35, 1.55, 9.0), "79583F")
    for z in (-21.0, -17.5, -14.0):
        part(bridge_home, "BridgePost", (side * 2.65, 13.1, z), (0.55, 2.0, 0.55), "936847")

bridge_forest = obj(w, "Model", "BridgeToDusk")
for i in range(15):
    x = 25.0 + i * 3.55
    part(bridge_forest, "BridgeDeck", (x, 12.0, -40), (3.35, 0.48, 5.3), "A87950")
for side in (-1, 1):
    part(bridge_forest, "BridgeRail", (50.0, 13.0, -40 + side * 2.65), (55.0, 0.35, 0.35), "79583F")
    for i in range(8):
        x = 25.0 + i * 7.1
        part(bridge_forest, "BridgePost", (x, 13.1, -40 + side * 2.65), (0.55, 2.0, 0.55), "936847")
for x in (27.0, 73.0):
    part(bridge_forest, "BridgeLamp", (x, 14.0, -40), (0.55, 2.6, 0.55), "CE9661")

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

X.indent(doc)
X.ElementTree(doc).write(root / "Giantback.rbxlx", encoding="utf-8", xml_declaration=True)
