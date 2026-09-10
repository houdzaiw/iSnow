#!/usr/bin/env python3
"""Download room UI image assets from a Lanhu exported HTML file.

Usage:
  python3 tools/download_lanhu_room_assets.py \
    "lanhu-mcp/data/lanhu_designs/<project_id>/二十麦位.html"
"""

from __future__ import annotations

import argparse
import json
import os
import re
import struct
import zlib
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlencode, urlparse
from urllib.request import Request, urlopen


CLASS_TO_FILENAME = {
    "image_1": "room_home_indicator.png",
    "single-avatar_1": "room_avatar_sample.png",
    "icon_2": "room_power.png",
    "thumbnail_1": "room_mic_seat.png",
    "thumbnail_6": "room_heat.png",
    "avatar-group_1": "room_avatar_group.png",
    "thumbnail_41": "room_chat_panel_gift.png",
    "label_1": "room_big_win_banner.png",
    "thumbnail_42": "room_carousel_dot.png",
    "thumbnail_43": "room_chat_badge_country.png",
    "thumbnail_44": "room_badge_charm.png",
    "thumbnail_45": "room_badge_shield.png",
    "thumbnail_46": "room_badge_medal.png",
    "label_2": "room_treasure_banner.png",
    "label_3": "room_bottom_chat.png",
    "thumbnail_48": "room_bottom_mic.png",
    "label_4": "room_bottom_gift.png",
    "thumbnail_49": "room_bottom_message.png",
    "label_5": "room_bottom_more.png",
}

# The More tools design is a Figma document. The layer order is stable within
# this design, while generated HTML class names are not semantic.
ROOM_MORE_SEMANTIC_FILES = {
    "Basic Tools": [
        "room_more_share.png",
        "room_more_report.png",
        "room_more_music.png",
        "room_more_charm_counter.png",
        "room_more_charm_counter_muted.png",
        "room_more_voice.png",
        "room_more_voice_muted.png",
        "room_more_room_data.png",
        "room_more_charm_setting.png",
        "room_more_message.png",
        "room_more_message_badge.png",
        "room_more_effects_setting.png",
    ],
    "room mode": [
        "room_more_mode_chat.png",
        "room_more_mode_game.png",
        "room_more_mode_win.png",
        "room_more_mode_party.png",
        "room_more_mode_ktv.png",
    ],
    "Party": [
        "room_more_pk.png",
        "room_more_lucky_box.png",
        "room_more_party_win.png",
    ],
}

ASSET_DIR = Path("assets/lanhu/room")
MISSING_ICON = "room_icon_missing.png"
MANIFEST = "lanhu_room_assets_manifest.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "html",
        type=Path,
        nargs="?",
        help="Lanhu exported room HTML path",
    )
    parser.add_argument(
        "--design-url",
        help="Lanhu design URL containing pid and image_id for Figma assets",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ASSET_DIR,
        help="Output asset directory",
    )
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)

    manifest = _load_manifest(args.output / MANIFEST)
    if args.design_url:
        assets = _fetch_room_more_assets(args.design_url)
    else:
        if args.html is None:
            parser.error("provide an HTML path or --design-url")
        html = args.html.read_text(encoding="utf-8")
        image_urls = _extract_image_urls(html, args.html.parent)
        assets = [
            (filename, image_urls.get(class_name))
            for class_name, filename in CLASS_TO_FILENAME.items()
        ]

    downloaded = 0
    for filename, url in assets:
        if not url:
            continue
        _download(url, args.output / filename)
        manifest[filename] = url
        downloaded += 1

    _write_missing_icon(args.output / MISSING_ICON)
    manifest[MISSING_ICON] = (
        "generated red missing-icon placeholder; replace with Lanhu MCP icon "
        "when available"
    )
    (args.output / MANIFEST).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Downloaded {downloaded} Lanhu assets to {args.output}")


class _AssetMarkupParser(HTMLParser):
    def __init__(self, base_dir: Path | None) -> None:
        super().__init__()
        self.base_dir = base_dir
        self.urls: dict[str, str] = {}

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        class_names = (attributes.get("class") or "").split()
        candidates = []
        src = attributes.get("src")
        if src:
            candidates.append(src)
        candidates.extend(_extract_css_urls(attributes.get("style") or ""))
        for class_name in class_names:
            for candidate in candidates:
                normalized = _normalize_asset_source(candidate, self.base_dir)
                if normalized:
                    self.urls.setdefault(class_name, normalized)
                    break


def _extract_image_urls(html: str, base_dir: Path | None = None) -> dict[str, str]:
    """Extract remote/local image sources from img tags and CSS backgrounds."""
    parser = _AssetMarkupParser(base_dir)
    parser.feed(html)

    # Exported Lanhu HTML usually puts background URLs in a class selector,
    # for example `.group_6 { background: url(...) }`.
    css_rule = re.compile(r"([^{}]+)\{([^{}]*url\([^{}]+\)[^{}]*)\}")
    for selector, body in css_rule.findall(html):
        selectors = re.findall(r"\.([\w-]+)", selector)
        candidates = _extract_css_urls(body)
        for class_name in selectors:
            for candidate in candidates:
                normalized = _normalize_asset_source(candidate, base_dir)
                if normalized:
                    parser.urls.setdefault(class_name, normalized)
                    break
    return parser.urls


def _extract_css_urls(value: str) -> list[str]:
    return [unquote(match) for match in re.findall(r"url\(\s*['\"]?([^)'\"]+)", value)]


def _normalize_asset_source(source: str, base_dir: Path | None) -> str | None:
    source = source.strip()
    if source.startswith(("http://", "https://")):
        return source
    if base_dir is None:
        return None
    local_path = (base_dir / source).resolve()
    if not local_path.is_file():
        return None
    return local_path.as_uri()


def _load_manifest(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def _fetch_room_more_assets(design_url: str) -> list[tuple[str, str]]:
    params = parse_qs(urlparse(design_url).fragment.split("?", 1)[-1])
    project_id = _first_query_value(params, "pid")
    image_id = _first_query_value(params, "image_id")
    team_id = _first_query_value(params, "tid")
    if not project_id or not image_id:
        raise ValueError("design URL must contain pid and image_id")

    cookie = _load_lanhu_cookie()
    query = urlencode(
        {
            "dds_status": 1,
            "image_id": image_id,
            "project_id": project_id,
            **({"team_id": team_id} if team_id else {}),
        }
    )
    design = _fetch_json(
        f"https://lanhuapp.com/api/project/image?{query}",
        cookie=cookie,
    )
    if design.get("code") != "00000":
        raise RuntimeError(f"Lanhu design request failed: {design.get('msg')}")

    versions = (design.get("result") or {}).get("versions") or []
    if not versions or not versions[0].get("json_url"):
        raise RuntimeError("Lanhu design has no exported Figma JSON")
    sketch = _fetch_json(versions[0]["json_url"])

    assets: list[tuple[str, str]] = []
    for section_name, filenames in ROOM_MORE_SEMANTIC_FILES.items():
        section = _find_layer(sketch.get("artboard") or {}, section_name)
        if section is None:
            continue
        item_layers = _section_item_layers(section)
        for index, filename in enumerate(filenames):
            if index >= len(item_layers):
                continue
            urls = _export_urls(item_layers[index])
            if urls:
                # Some mode cells contain a reusable background export followed
                # by the actual icon. The final export is the foreground icon.
                assets.append((filename, urls[-1]))
    return assets


def _first_query_value(params: dict[str, list[str]], key: str) -> str | None:
    values = params.get(key) or []
    return values[0] if values else None


def _fetch_json(url: str, cookie: str = "") -> dict:
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Referer": "https://lanhuapp.com/web/",
        "Accept": "application/json, text/plain, */*",
    }
    if cookie:
        headers["Cookie"] = cookie
    request = Request(url, headers=headers)
    with urlopen(request, timeout=30) as response:
        value = json.loads(response.read().decode("utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"Expected JSON object from {url}")
    return value


def _load_lanhu_cookie() -> str:
    cookie = os.getenv("LANHU_COOKIE", "").strip()
    if cookie:
        return cookie
    env_path = Path("lanhu-mcp/.env")
    if not env_path.is_file():
        return ""
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("LANHU_COOKIE="):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ""


def _find_layer(root: dict, name: str) -> dict | None:
    for layer in root.get("layers") or []:
        if isinstance(layer, dict) and layer.get("name") == name:
            return layer
    return None


def _section_item_layers(section: dict) -> list[dict]:
    rows = [
        child
        for child in section.get("layers") or []
        if isinstance(child, dict) and child.get("type") == "artboard"
    ]
    items: list[dict] = []
    for row in rows:
        items.extend(
            child
            for child in row.get("layers") or []
            if isinstance(child, dict) and child.get("type") == "groupLayer"
        )
    return items


def _export_urls(layer: dict) -> list[str]:
    urls: list[str] = []
    image = layer.get("image")
    if layer.get("hasExportImage") and isinstance(image, dict):
        image_url = image.get("imageUrl")
        if image_url:
            urls.append(image_url)
    for key in ("layers", "children"):
        for child in layer.get(key) or []:
            if isinstance(child, dict):
                urls.extend(_export_urls(child))
    return urls


def _download(url: str, target: Path) -> None:
    if url.startswith("file://"):
        target.write_bytes(Path(unquote(urlparse(url).path)).read_bytes())
        return
    request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(request, timeout=30) as response:
        target.write_bytes(response.read())


def _write_missing_icon(target: Path, width: int = 96, height: int = 96) -> None:
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            border = x < 4 or y < 4 or x >= width - 4 or y >= height - 4
            diagonal = abs(x - y) < 4 or abs((width - 1 - x) - y) < 4
            if border or diagonal:
                row.extend((255, 255, 255, 255))
            else:
                row.extend((255, 0, 58, 255))
        rows.append(bytes(row))

    raw = b"".join(rows)
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(
        b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    )
    data += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += _png_chunk(b"IEND", b"")
    target.write_bytes(data)


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


if __name__ == "__main__":
    main()
