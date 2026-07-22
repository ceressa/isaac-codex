"""Scrape platinumgod.co.uk Repentance page into a structured JSON.

Usage:
    python scraper/scrape.py

Outputs:
    assets/data/items.json
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

from bs4 import BeautifulSoup, Tag

ROOT = Path(__file__).resolve().parent.parent
HTML_PATH = ROOT / "scraper" / "page.html"
OUT_PATH = ROOT / "assets" / "data" / "items.json"


# Map the icon-class prefix on the inner <div> to a normalised category.
CLASS_TO_CATEGORY = {
    "rep-item": "repentance_item",
    "rep-trink": "repentance_trinket",
    "re-itm": "rebirth_item",
    "ab-itm": "afterbirth_item",
    "abn-itm": "afterbirth_item",
    "ab-item": "afterbirth_item",
    "abp-itm": "afterbirth_plus_item",
    "abp-item": "afterbirth_plus_item",
    "trinket": "trinket",
    "rebirth-card": "card",
    "rebirth-pill": "pill",
    "rebirth-rune": "rune",
    "rebirth-pickup": "pickup",
    "rebirth-pocket": "pocket_item",
    "ab-card": "card",
    "abp-card": "card",
    "ab-pill": "pill",
    "abp-pill": "pill",
    "repc": "repentance_consumable",
}

SECTION_FALLBACK = {
    "Repentance Items": "repentance_item",
    "Repentance Trinkets": "repentance_trinket",
    "Rebirth Items": "rebirth_item",
    "Afterbirth Items": "afterbirth_item",
    "Afterbirth Plus Items": "afterbirth_plus_item",
    "Rebirth Trinkets": "trinket",
    "Afterbirth Trinkets": "trinket",
    "Afterbirth Plus Trinkets": "trinket",
    "Consumables + Misc.": "consumable",
}


def categorise(class_list: list[str]) -> tuple[str, str]:
    """Return (category, slug) from the inner div class list."""
    # Drop generic helper classes and the per-item id (e.g. "rep553", "trinket012").
    keep = [c for c in class_list if c not in ("item",)]
    cat = "unknown"
    slug = ""
    for c in keep:
        if c in CLASS_TO_CATEGORY:
            cat = CLASS_TO_CATEGORY[c]
            break
        # Detect numbered-only id classes like rep553, re-itm263, trinket012, r-card05.
        if re.fullmatch(r"[a-z\-]+\d+", c):
            slug = c
    if cat == "unknown":
        # Fall back to inferring from slug prefix.
        for prefix, mapped in CLASS_TO_CATEGORY.items():
            if slug.startswith(prefix):
                cat = mapped
                break
    if cat == "unknown" and slug.startswith("r-card"):
        cat = "card"
    if cat == "unknown" and slug.startswith("r-pill"):
        cat = "pill"
    if cat == "unknown" and slug.startswith("r-rune"):
        cat = "rune"
    return cat, slug


def parse_item(li: Tag, section: str) -> dict | None:
    inner_div = li.find("div", class_="item")
    if not inner_div:
        return None
    classes = inner_div.get("class", [])
    category, slug = categorise(classes)
    if category == "unknown":
        category = SECTION_FALLBACK.get(section, "unknown")

    span = li.find("span")
    if not span:
        return None

    title_p = span.find("p", class_="item-title")
    name = title_p.get_text(strip=True) if title_p else ""

    id_p = span.find("p", class_="r-itemid")
    raw_id = id_p.get_text(strip=True) if id_p else ""
    id_match = re.search(r"(\w+):\s*(\d+)", raw_id)
    id_kind = id_match.group(1) if id_match else ""
    id_num = int(id_match.group(2)) if id_match else None

    pickup_p = span.find("p", class_="pickup")
    pickup = pickup_p.get_text(strip=True).strip('"') if pickup_p else ""

    quality_p = span.find("p", class_="quality")
    quality = None
    if quality_p:
        m = re.search(r"\d+", quality_p.get_text())
        if m:
            quality = int(m.group(0))

    tags_p = span.find("p", class_="tags")
    tags = []
    if tags_p:
        tags = [t.strip() for t in tags_p.get_text().split(",") if t.strip() and t.strip() != "*"]

    # Description: every <p> directly under span that has no class.
    description_parts = []
    for p in span.find_all("p", recursive=False):
        if p.get("class"):
            continue
        txt = p.get_text(" ", strip=True)
        if txt:
            description_parts.append(txt)

    # Type / Item Pool / Charge etc. live in <ul><p>...</p></ul>.
    metadata: dict[str, str] = {}
    for ul in span.find_all("ul", recursive=False):
        for p in ul.find_all("p"):
            txt = p.get_text(" ", strip=True)
            if ":" in txt:
                k, _, v = txt.partition(":")
                metadata[k.strip()] = v.strip()

    if not name:
        return None

    return {
        "id": f"{category}:{slug or (str(id_num) if id_num is not None else name)}",
        "slug": slug,
        "category": category,
        "section": section,
        "name": name,
        "name_tr": "",
        "id_kind": id_kind,
        "id_number": id_num,
        "pickup": pickup,
        "quality": quality,
        "description": description_parts,
        "description_tr": [],
        "metadata": metadata,
        "tags": tags,
    }


def scrape() -> dict:
    html = HTML_PATH.read_text(encoding="utf-8")
    soup = BeautifulSoup(html, "html.parser")

    items: list[dict] = []
    current_section = "Unknown"
    seen_ids: set[str] = set()

    # Walk every direct descendant in document order so we can attribute items
    # to the most recent <h2> section header.
    for el in soup.find_all(["h2", "li"]):
        if el.name == "h2":
            current_section = re.sub(r"\s*\(\d+\)\s*$", "", el.get_text(strip=True))
            continue
        if "textbox" not in (el.get("class") or []):
            continue
        item = parse_item(el, current_section)
        if not item:
            continue
        # De-duplicate by id (page sometimes has hidden duplicate).
        if item["id"] in seen_ids:
            continue
        seen_ids.add(item["id"])
        items.append(item)

    # Build category counts for sanity check.
    counts: dict[str, int] = {}
    for it in items:
        counts[it["category"]] = counts.get(it["category"], 0) + 1

    return {
        "source": "https://platinumgod.co.uk/repentance",
        "version": 1,
        "counts": counts,
        "items": items,
    }


def main() -> int:
    if not HTML_PATH.exists():
        print(f"Missing {HTML_PATH}; download it first.", file=sys.stderr)
        return 1
    data = scrape()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(data['items'])} entries to {OUT_PATH}")
    print("Categories:")
    for k, v in sorted(data["counts"].items(), key=lambda kv: -kv[1]):
        print(f"  {k:30s} {v}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
