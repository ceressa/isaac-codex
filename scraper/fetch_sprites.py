"""Fetch Repentance item sprites from platinumgod.co.uk and slice per-item PNGs.

The sprites are game art (c) Nicalis / Edmund McMillen, used here under fan-use
with attribution (see README). Only the sliced per-item PNGs land in assets/;
the downloaded spritesheets/HTML/CSS are cached and git-ignored.

Adds a "sprite" path to each matched item in assets/data/items.json.

Usage:
    python scraper/fetch_sprites.py
"""
from __future__ import annotations
import io
import json
import re
import sys
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ITEMS = ROOT / "assets" / "data" / "items.json"
OUT = ROOT / "assets" / "sprites"
CACHE = ROOT / "scraper" / "_cache"
BASE = "https://platinumgod.co.uk"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120 Safari/537.36"}


def fetch(url: str) -> bytes:
    return urllib.request.urlopen(
        urllib.request.Request(url, headers=UA), timeout=60).read()


def cached(name: str, url: str) -> bytes:
    CACHE.mkdir(parents=True, exist_ok=True)
    p = CACHE / name
    if not p.exists():
        p.write_bytes(fetch(url))
    return p.read_bytes()


def norm(name: str) -> str:
    return re.sub(r"\s+", " ", name).strip().lower()


def safe(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    html = cached("page.html", BASE + "/repentance").decode("utf-8", "replace")
    css = cached("main.css", BASE + "/assets/main.css").decode("utf-8", "replace")

    # base class -> (sheet_rel, width|None, height|None)
    base_sheet: dict[str, tuple[str, int | None, int | None]] = {}
    for m in re.finditer(r"\.([a-z][a-z0-9_-]*)\{([^}]*url\([^)]*\)[^}]*)\}", css):
        cls, decl = m.group(1), m.group(2)
        um = re.search(r'url\(["\']?([^)"\']+\.png)', decl)
        if not um:
            continue
        w = re.search(r"width:(\d+)px", decl)
        h = re.search(r"height:(\d+)px", decl)
        base_sheet[cls] = (um.group(1), int(w.group(1)) if w else None,
                           int(h.group(1)) if h else None)

    # slug -> (x, y, w|None, h|None)
    slug_pos: dict[str, tuple[int, int, int | None, int | None]] = {}
    for m in re.finditer(r"\.([a-z][a-z0-9_-]*\d+)\{([^}]*background-position[^}]*)\}", css):
        slug, decl = m.group(1), m.group(2)
        pm = re.search(r"background-position:\s*(-?\d+)px\s+(-?\d+)", decl)
        if not pm:
            continue
        w = re.search(r"width:(\d+)px", decl)
        h = re.search(r"height:(\d+)px", decl)
        slug_pos[slug] = (abs(int(pm.group(1))), abs(int(pm.group(2))),
                          int(w.group(1)) if w else None, int(h.group(1)) if h else None)

    # HTML: name -> (base, slug), parsed robustly
    soup = BeautifulSoup(html, "html.parser")
    html_by_name: dict[str, tuple[str, str]] = {}
    for div in soup.find_all("div", class_="item"):
        classes = div.get("class", [])
        slug = next((c for c in classes if re.fullmatch(r"[a-z][a-z-]*\d+", c)), None)
        base = next((c for c in classes if c in base_sheet), None)
        if not slug or not base:
            continue
        li = div.find_parent("li") or div.parent
        title = li.find("p", class_="item-title") if li else None
        name = title.get_text(strip=True) if title else ""
        if name:
            html_by_name.setdefault(norm(name), (base, slug))

    def sheet_url(rel: str) -> str:
        rel = rel.lstrip("./")
        return f"{BASE}/{rel}" if rel.startswith("images/") else f"{BASE}/assets/{rel}"

    sheets: dict[str, Image.Image | None] = {}

    def load_sheet(rel: str) -> Image.Image | None:
        if rel not in sheets:
            try:
                url = sheet_url(rel)
                data = cached(safe(url.split("/")[-1]) + ".png", url)
                sheets[rel] = Image.open(io.BytesIO(data)).convert("RGBA")
            except Exception as e:
                print(f"  sheet fail {rel}: {e}")
                sheets[rel] = None
        return sheets[rel]

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    items = data["items"]
    ok = 0
    no_match = 0
    montage = []

    for i, it in enumerate(items):
        it.pop("sprite", None)
        pair = html_by_name.get(norm(it.get("name", "")))
        if not pair:
            no_match += 1
            continue
        base, slug = pair
        if slug not in slug_pos:
            no_match += 1
            continue
        srel, bw, bh = base_sheet[base]
        x, y, w, h = slug_pos[slug]
        w = w or bw or 50
        h = h or bh or 50
        sheet = load_sheet(srel)
        if sheet is None or x + w > sheet.width or y + h > sheet.height:
            continue
        sprite = sheet.crop((x, y, x + w, y + h))
        key = f"s{i}"
        sprite.save(OUT / f"{key}.png")
        it["sprite"] = f"assets/sprites/{key}.png"
        ok += 1
        if len(montage) < 24:
            montage.append((sprite, it.get("name", "")))

    ITEMS.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    if montage:
        cell = 96
        cols = 6
        rows = (len(montage) + cols - 1) // cols
        mon = Image.new("RGBA", (cols * cell, rows * cell), (24, 22, 24, 255))
        d = ImageDraw.Draw(mon)
        for i, (spr, name) in enumerate(montage):
            cx, cy = (i % cols) * cell, (i // cols) * cell
            s = spr.copy()
            s.thumbnail((cell - 20, cell - 34), Image.NEAREST)
            mon.paste(s, (cx + (cell - s.width) // 2, cy + 6), s)
            d.text((cx + 3, cy + cell - 22), name[:15], fill=(230, 220, 222, 255))
        mon.save(CACHE / "montage.png")

    total = len(items)
    print(f"items={total} sprites_ok={ok} no_match={no_match} "
          f"sheets={sum(1 for v in sheets.values() if v)} coverage={ok*100//total}%")
    return 0


if __name__ == "__main__":
    sys.exit(main())
