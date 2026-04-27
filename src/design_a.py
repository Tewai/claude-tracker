"""
Design A — SPARK (Minimal / Monochrome)
────────────────────────────────────────
Menu bar:  ✦ 10%
Style:     clean, technical, no colour noise
"""
import rumps
import threading
import os
import sys
from Foundation import NSOperationQueue

sys.path.insert(0, os.path.dirname(__file__))
from api import fetch_usage, fmt_reset


def _on_main(fn):
    NSOperationQueue.mainQueue().addOperationWithBlock_(fn)

COOKIE_FILE = os.path.expanduser("~/.claude_tracker_cookie.txt")
REFRESH_SEC = 300  # 5 min


def _bar(pct: int, width: int = 20) -> str:
    filled = round(pct / 100 * width)
    return "█" * filled + "░" * (width - filled)


def _indicator(pct: int) -> str:
    if pct >= 90:
        return "▲"   # warning
    if pct >= 70:
        return "◆"   # caution
    return "◇"       # ok


class SparkApp(rumps.App):
    def __init__(self):
        super().__init__("✦ –%", quit_button=None)
        self._cookie = self._load_cookie()
        self._lock = threading.Lock()

        # ── display items (hold refs so we can update .title) ──────────────
        self._s_bar   = rumps.MenuItem("  ░░░░░░░░░░░░░░░░░░░░  –%", callback=None)
        self._s_reset = rumps.MenuItem("  Resets –", callback=None)

        self._w_bar   = rumps.MenuItem("  ░░░░░░░░░░░░░░░░░░░░  –%", callback=None)
        self._w_reset = rumps.MenuItem("  Resets –", callback=None)

        self._sn_bar   = rumps.MenuItem("  ░░░░░░░░░░░░░░░░░░░░  –%", callback=None)
        self._sn_reset = rumps.MenuItem("  Resets –", callback=None)

        self._footer = rumps.MenuItem("  Last update: –", callback=None)

        self.menu = [
            rumps.MenuItem("┄ Session (5 h window) ┄┄┄┄┄┄┄", callback=None),
            self._s_bar,
            self._s_reset,
            None,
            rumps.MenuItem("┄ Weekly · All Models ┄┄┄┄┄┄┄┄", callback=None),
            self._w_bar,
            self._w_reset,
            None,
            rumps.MenuItem("┄ Weekly · Sonnet ┄┄┄┄┄┄┄┄┄┄┄┄", callback=None),
            self._sn_bar,
            self._sn_reset,
            None,
            self._footer,
            None,
            rumps.MenuItem("↻  Refresh", callback=self.refresh),
            rumps.MenuItem("⚙  Set Cookie…", callback=self.set_cookie),
            None,
            rumps.MenuItem("Quit", callback=rumps.quit_application),
        ]

        self._timer = rumps.Timer(lambda _: self._fetch(), REFRESH_SEC)
        self._timer.start()
        if self._cookie:
            self._fetch()
        else:
            self.title = "✦ no cookie"

    # ── cookie ──────────────────────────────────────────────────────────────

    def _load_cookie(self) -> str:
        if os.path.exists(COOKIE_FILE):
            return open(COOKIE_FILE).read().strip()
        return ""

    def _save_cookie(self, c: str):
        with open(COOKIE_FILE, "w") as f:
            f.write(c)
        self._cookie = c

    def set_cookie(self, _):
        w = rumps.Window(
            title="Set Session Cookie",
            message=(
                "Paste your claude.ai cookie string.\n\n"
                "How to get it:\n"
                "  1. Open claude.ai in browser\n"
                "  2. DevTools → Application → Cookies → claude.ai\n"
                "  3. Copy the full cookie string from the request header\n"
                "     (Network tab → any request → Request Headers → Cookie)"
            ),
            default_text=self._cookie,
            ok="Save",
            cancel="Cancel",
            dimensions=(500, 80),
        )
        resp = w.run()
        if resp.clicked and resp.text.strip():
            self._save_cookie(resp.text.strip())
            self._fetch()

    # ── fetch ────────────────────────────────────────────────────────────────

    def _fetch(self):
        if not self._cookie:
            return
        threading.Thread(target=self._fetch_bg, daemon=True).start()

    def _fetch_bg(self):
        try:
            data = fetch_usage(self._cookie)
            _on_main(lambda: self._update(data))
        except Exception as e:
            msg = str(e)
            _on_main(lambda: self._set_error(msg))

    def _update(self, data: dict):
        from datetime import datetime
        s  = data.get("session",       {"pct": 0, "resets_at": None})
        w  = data.get("weekly",        {"pct": 0, "resets_at": None})
        sn = data.get("weekly_sonnet", {"pct": 0, "resets_at": None})

        # menu bar title: highest usage wins
        top = max(s["pct"], w["pct"])
        ind = _indicator(top)
        self.title = f"✦ {ind} {top}%"

        # session row
        self._s_bar.title   = f"  {_bar(s['pct'])}  {s['pct']}%"
        self._s_reset.title = f"  Resets in {fmt_reset(s['resets_at'])}"

        # weekly row
        self._w_bar.title   = f"  {_bar(w['pct'])}  {w['pct']}%"
        self._w_reset.title = f"  Resets in {fmt_reset(w['resets_at'])}"

        # sonnet row
        if sn:
            self._sn_bar.title   = f"  {_bar(sn['pct'])}  {sn['pct']}%"
            self._sn_reset.title = f"  Resets in {fmt_reset(sn['resets_at'])}"
        else:
            self._sn_bar.title   = "  not available on this plan"
            self._sn_reset.title = ""

        self._footer.title = f"  Last update: {datetime.now().strftime('%H:%M')}"

    def _set_error(self, msg: str):
        self.title = "✦ !"
        self._footer.title = f"  Error: {msg}"

    # ── actions ──────────────────────────────────────────────────────────────

    def refresh(self, _):
        self._footer.title = "  Refreshing…"
        self._fetch()


if __name__ == "__main__":
    SparkApp().run()
