"""Reject archives with an upstream push gateway or inconsistent CallKit capability."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
settings = (root / "ElementX/Sources/Application/Settings/AppSettings.swift").read_text()
match = re.search(r'var pushGatewayBaseURL: URL = "([^"]+)"', settings)
if not match or match[1] != "http://sygnal:5000":
    raise SystemExit("Tich push destination differs from the managed Sygnal gateway")
nse_entitlements = (root / "NSE/SupportingFiles/NSE.entitlements").read_text()
app_entitlements = (root / "ElementX/SupportingFiles/ElementX.entitlements").read_text()
app_target = (root / "ElementX/SupportingFiles/target.yml").read_text()
nse_target = (root / "NSE/SupportingFiles/target.yml").read_text()
has_entitlement = "com.apple.developer.usernotifications.filtering" in nse_entitlements
has_compile_flag = '"-DTICH_HAS_NOTIFICATION_FILTERING_ENTITLEMENT"' in nse_target
if has_entitlement != has_compile_flag:
    raise SystemExit("Tich CallKit entitlement and compile-time capability differ")

for description, content in (("application", app_entitlements), ("NSE", nse_entitlements)):
    if "com.apple.developer.usernotifications.time-sensitive" not in content:
        raise SystemExit(f"Tich {description} time-sensitive entitlement is missing")
for description, content in (("application", app_target), ("NSE", nse_target)):
    if "com.apple.developer.usernotifications.time-sensitive: true" not in content:
        raise SystemExit(f"Tich {description} time-sensitive capability is missing")

state = "CallKit" if has_entitlement else "alert fallback"
print(f"Tich push destination: verified; incoming calls: {state}; time-sensitive: enabled")
