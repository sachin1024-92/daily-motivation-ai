"""Prints the centre "x y" of the first on-screen element whose text or description contains argv[1].

Reads a `uiautomator dump` XML from stdin. Exit code 1 when nothing matches.
"""
import re
import sys
import xml.etree.ElementTree as ET

want = sys.argv[1]
data = sys.stdin.read()
start = data.find("<?xml")
if start < 0:
    sys.exit(1)
try:
    root = ET.fromstring(data[start:])
except ET.ParseError:
    sys.exit(1)
for node in root.iter("node"):
    label = (node.get("text") or "") + "|" + (node.get("content-desc") or "")
    if want in label:
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds", "")))
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
sys.exit(1)
