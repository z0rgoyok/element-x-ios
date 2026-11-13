"""Reject archives that register Tich devices with an upstream push gateway."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
settings = (root / "ElementX/Sources/Application/Settings/AppSettings.swift").read_text()
match = re.search(r'var pushGatewayBaseURL: URL = "([^"]+)"', settings)
if not match or match[1] != "http://sygnal:5000":
    raise SystemExit("Tich push destination differs from the managed Sygnal gateway")
print("Tich push destination: verified")
