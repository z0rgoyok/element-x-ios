"""Reject archives with an upstream push gateway or inconsistent CallKit capability."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
settings = (root / "ElementX/Sources/Application/Settings/AppSettings.swift").read_text()
match = re.search(r'var pushGatewayBaseURL: URL = "([^"]+)"', settings)
if not match or match[1] != "http://sygnal:5000":
    raise SystemExit("Tich push destination differs from the managed Sygnal gateway")
entitlements = (root / "NSE/SupportingFiles/NSE.entitlements").read_text()
target = (root / "NSE/SupportingFiles/target.yml").read_text()
has_entitlement = "com.apple.developer.usernotifications.filtering" in entitlements
has_compile_flag = '"-DTICH_HAS_NOTIFICATION_FILTERING_ENTITLEMENT"' in target
if has_entitlement != has_compile_flag:
    raise SystemExit("Tich CallKit entitlement and compile-time capability differ")

state = "CallKit" if has_entitlement else "alert fallback"
print(f"Tich push destination: verified; incoming calls: {state}")
