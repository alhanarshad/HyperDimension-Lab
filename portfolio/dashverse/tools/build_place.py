"""Build an openable Roblox XML place from the Dashverse Luau source."""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


source = Path(__file__).resolve().parents[1] / "src"
output = Path(sys.argv[1]).resolve()
counter = 0
root = ET.Element("roblox", {"version": "4"})


def item(parent, class_name, name, properties=()):
    global counter
    counter += 1
    node = ET.SubElement(parent, "Item", {"class": class_name, "referent": f"RBX{counter:08d}"})
    attributes = ET.SubElement(node, "Properties")
    for tag, key, value in [("string", "Name", name), *properties]:
        prop = ET.SubElement(attributes, tag, {"name": key})
        if isinstance(value, dict):
            for axis, component in value.items():
                ET.SubElement(prop, axis).text = str(component)
        else:
            prop.text = value
    return node


workspace = item(root, "Workspace", "Workspace", [
    ("bool", "StreamingEnabled", "true"),
    ("int", "StreamingMinRadius", "96"),
    ("int", "StreamingTargetRadius", "352"),
])
item(workspace, "Terrain", "Terrain")
item(root, "Lighting", "Lighting")
replicated = item(root, "ReplicatedStorage", "ReplicatedStorage")
server = item(root, "ServerScriptService", "ServerScriptService")
starter = item(root, "StarterPlayer", "StarterPlayer")
client = item(starter, "StarterPlayerScripts", "StarterPlayerScripts")
item(starter, "StarterCharacterScripts", "StarterCharacterScripts")
item(root, "StarterGui", "StarterGui")

for service, directory in [(replicated, "shared"), (server, "server"), (client, "client")]:
    folder = item(service, "Folder", "Dashverse")
    for path in sorted((source / directory).glob("*.luau")):
        name = path.name.split(".")[0]
        class_name = "ModuleScript"
        properties = [("ProtectedString", "Source", path.read_text(encoding="utf-8"))]
        if path.name.endswith(".server.luau"):
            class_name = "Script"
        elif path.name.endswith(".client.luau"):
            class_name = "LocalScript"
        if class_name != "ModuleScript":
            properties.append(("bool", "Disabled", "false"))
        item(folder, class_name, name, properties)

output.parent.mkdir(parents=True, exist_ok=True)
ET.indent(root)
ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
