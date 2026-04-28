import json
from datetime import datetime, timezone
from curl_cffi import requests as cf_requests


def _extract_cookie_val(cookie: str, name: str) -> str:
    for part in cookie.split(";"):
        part = part.strip()
        if part.startswith(name + "="):
            return part[len(name) + 1:]
    return ""


def _get(url: str, cookie: str) -> dict:
    device_id = _extract_cookie_val(cookie, "anthropic-device-id")
    headers = {
        "Cookie": cookie,
        "Accept": "application/json",
        "Referer": "https://claude.ai",
        "Origin": "https://claude.ai",
        "anthropic-client-platform": "web_claude_ai",
        "anthropic-client-version": "1.0.0",
    }
    if device_id:
        headers["anthropic-device-id"] = device_id
    r = cf_requests.get(url, headers=headers, timeout=10, impersonate="safari")
    r.raise_for_status()
    return r.json()


def get_org_id(cookie: str) -> str | None:
    # 1. check cookie string directly
    for part in cookie.split(";"):
        part = part.strip()
        if part.startswith("lastActiveOrg="):
            return part[len("lastActiveOrg="):]
    # 2. try /api/bootstrap
    try:
        data = _get("https://claude.ai/api/bootstrap", cookie)
        return data["account"]["lastActiveOrgId"]
    except Exception:
        pass
    # 3. try /api/organizations (returns list, pick first)
    try:
        orgs = _get("https://claude.ai/api/organizations", cookie)
        if isinstance(orgs, list) and orgs:
            return orgs[0]["id"]
    except Exception:
        pass
    return None


def _parse_dt(s: str | None) -> datetime | None:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


def fetch_usage(cookie: str, org_id: str | None = None) -> dict:
    """Returns dict with keys: session, weekly, weekly_sonnet (optional)."""
    if not org_id:
        org_id = get_org_id(cookie)
    if not org_id:
        raise ValueError("Could not get organisation ID — check your cookie")

    raw = _get(f"https://claude.ai/api/organizations/{org_id}/usage", cookie)

    result = {}
    for key, label in [
        ("five_hour", "session"),
        ("seven_day", "weekly"),
        ("seven_day_sonnet", "weekly_sonnet"),
    ]:
        if key in raw and raw[key] is not None:
            b = raw[key]
            result[label] = {
                "pct": int(b.get("utilization", 0)),
                "resets_at": _parse_dt(b.get("resets_at")),
            }
    return result


def fmt_reset(dt: datetime | None) -> str:
    if dt is None:
        return "–"
    now = datetime.now(timezone.utc)
    total = int((dt - now).total_seconds())
    if total <= 0:
        return "now"
    h, rem = divmod(total, 3600)
    m = rem // 60
    return f"{h}h {m}m" if h else f"{m}m"
