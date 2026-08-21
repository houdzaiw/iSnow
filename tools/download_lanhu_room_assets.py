#!/usr/bin/env python3
"""Download room UI image assets from a Lanhu exported HTML file.

Usage:
  python3 tools/download_lanhu_room_assets.py \
    "lanhu-mcp/data/lanhu_designs/<project_id>/二十麦位.html"
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import zlib
from pathlib import Path
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

ASSET_DIR = Path("assets/lanhu/room")
MISSING_ICON = "room_icon_missing.png"
MANIFEST = "lanhu_room_assets_manifest.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("html", type=Path, help="Lanhu exported room HTML path")
    parser.add_argument(
        "--output",
        type=Path,
        default=ASSET_DIR,
        help="Output asset directory",
    )
    args = parser.parse_args()

    html = args.html.read_text(encoding="utf-8")
    image_urls = _extract_image_urls(html)
    args.output.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, str] = {}
    for class_name, filename in CLASS_TO_FILENAME.items():
        url = image_urls.get(class_name)
        if not url:
            continue
        _download(url, args.output / filename)
        manifest[filename] = url

    _write_missing_icon(args.output / MISSING_ICON)
    manifest[MISSING_ICON] = (
        "generated red missing-icon placeholder; replace with Lanhu MCP icon "
        "when available"
    )
    (args.output / MANIFEST).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Downloaded {len(manifest) - 1} Lanhu assets to {args.output}")


def _extract_image_urls(html: str) -> dict[str, str]:
    pattern = re.compile(r"<img\s+class=([^\s>]+)[^>]*?src=(https?://[^\s>]+)")
    urls: dict[str, str] = {}
    for class_name, url in pattern.findall(html):
        urls.setdefault(class_name, url)
    return urls


def _download(url: str, target: Path) -> None:
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
