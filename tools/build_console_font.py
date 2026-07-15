#!/usr/bin/env python3
"""Build the static, ASCII-only Clawd Console TrueType asset."""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont


NAME_VALUES = {
    1: "Clawd Console",
    2: "Regular",
    3: "Clawd Console Regular 1.0",
    4: "Clawd Console Regular",
    5: "Version 1.0",
    6: "ClawdConsole-Regular",
    16: "Clawd Console",
    17: "Regular",
}


def rename_font(font: TTFont) -> None:
    names = font["name"]
    for record in names.names:
        value = NAME_VALUES.get(record.nameID)
        if value is None:
            continue
        encoding = record.getEncoding() or "utf-16-be"
        try:
            record.string = value.encode(encoding)
        except (LookupError, UnicodeEncodeError):
            record.string = value.encode("utf-16-be")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("font", type=Path, help="path to an OFL CascadiaMono.ttf")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "package" / "font" / "clawd_console.ttf",
    )
    args = parser.parse_args()

    source = args.font.resolve()
    if not source.is_file():
        raise SystemExit(f"font not found: {source}")

    font = TTFont(source)
    if "fvar" in font:
        font = instantiateVariableFont(font, {"wght": 400}, inplace=False)

    options = subset.Options()
    options.hinting = True
    options.layout_features = []
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14, 16, 17]
    options.name_legacy = True
    options.name_languages = [0x0409]
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=range(0x20, 0x7F))
    subsetter.subset(font)
    rename_font(font)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    font.save(args.output)
    print(f"built {args.output} ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
