from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCENE_PATH = PROJECT_ROOT / "scenes" / "levels" / "ashdown" / "rooms" / "LibraryBenchmark.tscn"
RESOURCE_LINE = '[ext_resource type="PackedScene" path="res://assets/hd2d/library/library_book_dressing.glb" id="15_hd2d_books"]'
INSTANCE_BLOCK = '\n[node name="HD2DBookDressing" parent="Furniture" instance=ExtResource("15_hd2d_books")]\n'


def main() -> None:
    text = SCENE_PATH.read_text(encoding="utf-8")
    if RESOURCE_LINE not in text:
        last_ext = text.rfind("[ext_resource")
        next_section = text.find("\n\n", last_ext)
        text = text[:next_section] + "\n" + RESOURCE_LINE + text[next_section:]
    if "HD2DBookDressing" not in text:
        furniture_header = re.search(r'\[node name="Furniture"[^\n]*\]\n', text)
        if furniture_header is None:
            raise RuntimeError("Furniture branch not found")
        insert_at = furniture_header.end()
        text = text[:insert_at] + INSTANCE_BLOCK + text[insert_at:]

    lines = text.splitlines()
    output: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        output.append(line)
        if line.startswith('[node name="Books_'):
            lookahead = index + 1
            has_visibility = False
            while lookahead < len(lines) and not lines[lookahead].startswith("[node "):
                if lines[lookahead].startswith("visible ="):
                    has_visibility = True
                    break
                lookahead += 1
            if not has_visibility:
                output.append("visible = false")
        index += 1
    SCENE_PATH.write_text("\n".join(output) + "\n", encoding="utf-8")
    print(f"Applied HD-2D book dressing to {SCENE_PATH}")


if __name__ == "__main__":
    main()
