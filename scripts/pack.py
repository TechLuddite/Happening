#!/usr/bin/env python3
"""Build dist/Happening.vmz and its SHA256 checksum using only public runtime files."""

from __future__ import annotations

import argparse
import configparser
import hashlib
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parent.parent
FILES = {
    "mod.txt": "mod.txt",
    "LICENSE": "Happening_LICENSE",
    "mods/Happening/Main.gd": "mods/Happening/Main.gd",
    "mods/Happening/Selection.gd": "mods/Happening/Selection.gd",
    "mods/Happening/Banner.gd": "mods/Happening/Banner.gd",
}
VERSION = re.compile(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)")


def version(root: Path = ROOT) -> str:
    manifest = configparser.ConfigParser(interpolation=None, delimiters=("=",))
    manifest.optionxform = str
    manifest.read_string((root / "mod.txt").read_text(encoding="utf-8"))

    def value(section: str, key: str) -> str:
        return manifest.get(section, key).strip().strip('"')

    if value("mod", "id") != "happening" or value("mod", "name") != "Happening":
        raise ValueError("mod.txt must identify Happening (id happening)")
    if value("autoload", "HappeningMain") != "res://mods/Happening/Main.gd":
        raise ValueError("mod.txt has an unexpected HappeningMain autoload path")
    result = value("mod", "version")
    if VERSION.fullmatch(result) is None:
        raise ValueError("mod.txt version must be a stable X.Y.Z version")
    return result


def pack(out: Path, root: Path = ROOT) -> Path:
    version(root)
    contents: dict[str, bytes] = {}
    for source, target in FILES.items():
        path = root / source
        if any(parent.is_symlink() for parent in [path, *path.parents] if parent != root):
            raise ValueError(f"Refusing a symlink in approved source: {source}")
        contents[target] = path.read_bytes()
    out = out.resolve()
    checksum = out.with_name(out.name + ".sha256")
    sources = {(root / source).resolve() for source in FILES}
    if out in sources or checksum in sources:
        raise ValueError("Output must not overwrite an approved source file")
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, payload in sorted(contents.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, payload)
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    checksum.write_text(f"{digest}  {out.name}\n", encoding="ascii")
    return out


def release_notes(root: Path = ROOT) -> str:
    current = version(root)
    text = (root / "CHANGELOG.md").read_text(encoding="utf-8")
    headings = list(re.finditer(r"(?m)^##[ \t]+[^\n]+$", text))
    matches = [index for index, heading in enumerate(headings)
               if re.fullmatch(r"##[ \t]+" + re.escape(current) + r"(?:[ \t]+[^\n]*)?", heading.group())]
    if len(matches) != 1:
        raise ValueError(f"CHANGELOG.md must contain exactly one ## {current} section")
    index = matches[0]
    end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
    notes = text[headings[index].end():end].strip()
    if not notes:
        raise ValueError(f"CHANGELOG.md section {current} must not be empty")
    return notes + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--print-version", action="store_true")
    mode.add_argument("--release-notes", action="store_true")
    parser.add_argument("--out", type=Path, default=ROOT / "dist/Happening.vmz")
    args = parser.parse_args()
    try:
        if args.print_version:
            print(version())
        elif args.release_notes:
            print(release_notes(), end="")
        else:
            out = pack(args.out)
            print(f"Built {out} v{version()} ({out.stat().st_size} bytes)")
            print(f"Checksum: {out.name}.sha256")
    except (OSError, ValueError, configparser.Error) as error:
        parser.exit(1, f"Packaging failed: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
