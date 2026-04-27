import urllib.request
import json
from datetime import datetime, timezone

_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)


def _get(url: str, cookie: str) -> dict:
    req = urllib.request.Request(url, headers={
        "Cookie": cookie,
        "Accept": "application/json",
        "User-Agent": _UA,
        "Referer": "https://claude.ai",
        "Origin": "https://claude.ai",
    })
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


def get_org_id(cookie: str) -> str | None:
    for part in cookie.split(";"):
        part = part.strip()
        if part.startswith("lastActiveOrg="):
            return part[len("lastActiveOrg="):]
    try:
        data = _get("https://claude.ai/api/bootstrap", cookie)
        return data["account"]["lastActiveOrgId"]
    except Exception:
        return None


def _parse_dt(s: str | None) -> datetime | None:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


def fetch_usage(cookie: str) -> dict:
    """Returns dict with keys: session, weekly, weekly_sonnet (optional)."""
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
        if key in raw:
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
