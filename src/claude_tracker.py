import rumps
import json
import os
from datetime import datetime, timedelta

DATA_FILE = os.path.expanduser("~/.claude_tracker.json")

DEFAULT_DATA = {
    "daily_limit": 20,
    "weekly_limit": 100,
    "daily_count": 0,
    "weekly_count": 0,
    "day_start": None,
    "week_start": None,
}


def load_data():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE) as f:
            data = json.load(f)
        # Fill missing keys from defaults
        for key, val in DEFAULT_DATA.items():
            data.setdefault(key, val)
        return data
    return DEFAULT_DATA.copy()


def save_data(data):
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)


def now_iso():
    return datetime.now().isoformat()


def parse_dt(s):
    return datetime.fromisoformat(s) if s else None


def next_midnight():
    tomorrow = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
    return tomorrow


def next_monday():
    now = datetime.now()
    days_ahead = 7 - now.weekday()  # weekday: Mon=0 … Sun=6
    if days_ahead == 7:
        days_ahead = 7
    return (now + timedelta(days=days_ahead)).replace(hour=0, minute=0, second=0, microsecond=0)


def fmt_duration(delta: timedelta) -> str:
    total = int(delta.total_seconds())
    if total <= 0:
        return "0s"
    h, rem = divmod(total, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}h {m}m"
    if m:
        return f"{m}m {s}s"
    return f"{s}s"


class ClaudeTrackerApp(rumps.App):
    def __init__(self):
        super().__init__("☁️", quit_button=None)
        self.data = load_data()
        self._reset_if_needed()

        self.menu = [
            rumps.MenuItem("── Daily ──", callback=None),
            rumps.MenuItem("  Log usage (+1)", callback=self.log_daily),
            rumps.MenuItem("  Reset daily", callback=self.reset_daily),
            None,
            rumps.MenuItem("── Weekly ──", callback=None),
            rumps.MenuItem("  Log usage (+1)", callback=self.log_weekly),
            rumps.MenuItem("  Reset weekly", callback=self.reset_weekly),
            None,
            rumps.MenuItem("⚙  Set daily limit", callback=self.set_daily_limit),
            rumps.MenuItem("⚙  Set weekly limit", callback=self.set_weekly_limit),
            None,
            rumps.MenuItem("Quit", callback=rumps.quit_application),
        ]

        self._update_timer = rumps.Timer(self._tick, 10)
        self._update_timer.start()
        self._update_title()

    # ── helpers ──────────────────────────────────────────────────────────────

    def _reset_if_needed(self):
        changed = False
        now = datetime.now()

        day_start = parse_dt(self.data.get("day_start"))
        if day_start is None or now >= next_midnight_after(day_start):
            self.data["daily_count"] = 0
            self.data["day_start"] = now_iso()
            changed = True

        week_start = parse_dt(self.data.get("week_start"))
        if week_start is None or now >= next_monday_after(week_start):
            self.data["weekly_count"] = 0
            self.data["week_start"] = now_iso()
            changed = True

        if changed:
            save_data(self.data)

    def _update_title(self):
        d = self.data["daily_count"]
        dl = self.data["daily_limit"]
        w = self.data["weekly_count"]
        wl = self.data["weekly_limit"]

        d_left = max(dl - d, 0)
        w_left = max(wl - w, 0)

        d_pct = d / dl if dl else 0
        w_pct = w / wl if wl else 0

        d_icon = "🔴" if d_pct >= 1 else ("🟡" if d_pct >= 0.8 else "🟢")
        w_icon = "🔴" if w_pct >= 1 else ("🟡" if w_pct >= 0.8 else "🟢")

        d_reset = fmt_duration(next_midnight() - datetime.now())
        w_reset = fmt_duration(next_monday() - datetime.now())

        self.title = f"Claude {d_icon}{d_left}d {w_icon}{w_left}w"

        # Update dynamic menu items
        self.menu["── Daily ──"].title = (
            f"📅 Daily: {d}/{dl}  (reset in {d_reset})"
        )
        self.menu["── Weekly ──"].title = (
            f"📆 Weekly: {w}/{wl}  (reset in {w_reset})"
        )

    # ── timer ────────────────────────────────────────────────────────────────

    def _tick(self, _):
        self._reset_if_needed()
        self._update_title()

    # ── actions ──────────────────────────────────────────────────────────────

    def log_daily(self, _):
        self.data["daily_count"] += 1
        save_data(self.data)
        self._update_title()

    def log_weekly(self, _):
        self.data["weekly_count"] += 1
        save_data(self.data)
        self._update_title()

    def reset_daily(self, _):
        self.data["daily_count"] = 0
        self.data["day_start"] = now_iso()
        save_data(self.data)
        self._update_title()

    def reset_weekly(self, _):
        self.data["weekly_count"] = 0
        self.data["week_start"] = now_iso()
        save_data(self.data)
        self._update_title()

    def set_daily_limit(self, _):
        win = rumps.Window(
            title="Set Daily Limit",
            message="Enter new daily message limit:",
            default_text=str(self.data["daily_limit"]),
            ok="Save",
            cancel="Cancel",
            dimensions=(200, 24),
        )
        resp = win.run()
        if resp.clicked and resp.text.strip().isdigit():
            self.data["daily_limit"] = int(resp.text.strip())
            save_data(self.data)
            self._update_title()

    def set_weekly_limit(self, _):
        win = rumps.Window(
            title="Set Weekly Limit",
            message="Enter new weekly message limit:",
            default_text=str(self.data["weekly_limit"]),
            ok="Save",
            cancel="Cancel",
            dimensions=(200, 24),
        )
        resp = win.run()
        if resp.clicked and resp.text.strip().isdigit():
            self.data["weekly_limit"] = int(resp.text.strip())
            save_data(self.data)
            self._update_title()


# ── helpers for reset detection ───────────────────────────────────────────────

def next_midnight_after(dt: datetime) -> datetime:
    """First midnight that is strictly after dt."""
    base = dt.replace(hour=0, minute=0, second=0, microsecond=0)
    return base + timedelta(days=1)


def next_monday_after(dt: datetime) -> datetime:
    """First Monday midnight that is >= 7 days after the week start."""
    base = dt.replace(hour=0, minute=0, second=0, microsecond=0)
    days_ahead = (7 - base.weekday()) % 7 or 7
    return base + timedelta(days=days_ahead)


if __name__ == "__main__":
    ClaudeTrackerApp().run()
