import gzip
import io
import json
import unittest
from unittest.mock import patch

from tools import download_lanhu_room_assets as downloader


class LanhuRoomAssetsTest(unittest.TestCase):
    def test_music_uses_exact_layer_ids_not_generated_css_names(self):
        layers = [{"name": "section_30", "id": "other", "image": {
            "imageUrl": "wrong.png"}}]
        expected = []
        for index, (layer_id, filename) in enumerate(downloader.ROOM_MUSIC_EXPORTS.items()):
            url = f"https://example.com/{filename}"
            layers.append({"id": layer_id, "name": "Frame",
                           "ddsImage" if index == 0 else "image": {"imageUrl": url}})
            expected.append((filename, url))
        self.assertEqual(downloader._room_music_assets({"artboard": {"layers": layers}}), expected)
        self.assertFalse(any("slider" in name for name, _ in expected))

    def test_music_fails_when_real_export_is_missing(self):
        with self.assertRaisesRegex(RuntimeError, "exports missing"):
            downloader._room_music_assets({})

    def test_gift_exports_are_scoped_to_their_design_section(self):
        sections = []
        expected = []
        for section_name, names in downloader.ROOM_GIFT_SEMANTIC_FILES.items():
            exports = []
            for layer_name, filename in names.items():
                url = f"https://example.com/{filename}"
                expected.append((filename, url))
                exports.append({"name": layer_name, "type": "shapeLayer"})
                exports.append({
                    "name": layer_name,
                    "type": "bitmapLayer",
                    "image": {"imageUrl": url},
                })
            sections.append({
                "name": section_name,
                "layers": [{"name": "nested group", "layers": exports}],
            })
        sketch = {"artboard": {"layers": [
            {"name": "Polygon_25", "image": {"imageUrl": "wrong-design.png"}},
            *sections,
        ]}}
        self.assertEqual(downloader._room_gift_assets(sketch), expected)
        self.assertEqual(len(expected), 9)

    def test_missing_export_does_not_silently_reuse_an_unrelated_layer(self):
        with self.assertRaisesRegex(RuntimeError, "section missing"):
            downloader._room_gift_assets({"artboard": {"layers": []}})

    def test_json_supports_gzipped_lanhu_exports(self):
        data = {"artboard": {"layers": []}}
        payload = gzip.compress(json.dumps(data).encode("utf-8"))
        with patch.object(downloader, "urlopen", return_value=io.BytesIO(payload)):
            self.assertEqual(downloader._fetch_json("https://example.com"), data)

    def test_existing_html_images_and_css_backgrounds_still_work(self):
        markup = """
            <img class="image_1" src="https://example.com/image.png">
            <div class="group_6"></div>
            <style>.group_6 { background-image: url('https://example.com/share.png'); }</style>
            <div class="inline" style="background:url(https://example.com/inline.png)"></div>
        """
        self.assertEqual(downloader._extract_image_urls(markup), {
            "image_1": "https://example.com/image.png",
            "group_6": "https://example.com/share.png",
            "inline": "https://example.com/inline.png",
        })


if __name__ == "__main__":
    unittest.main()
