"""Check that a release archive matches its declared assets and notices."""
import argparse
import hashlib
import json
import re
from pathlib import Path, PurePosixPath


def resolve(root, value):
    if not isinstance(value, str) or "\\" in value or not value:
        raise ValueError("paths must be nonempty and use forward slashes")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or ":" in value or str(path) != value:
        raise ValueError(f"unsafe or noncanonical path: {value}")
    target = root.joinpath(*path.parts)
    if not target.resolve().is_relative_to(root):
        raise ValueError(f"path escapes release root: {value}")
    return target


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def audit(root, manifest):
    root = Path(root).resolve()
    if not isinstance(manifest, dict) or not isinstance(manifest.get("assets"), list):
        raise ValueError("manifest must contain an assets array")
    problems, declared, verified = [], set(), 0
    for index, asset in enumerate(manifest["assets"], 1):
        try:
            if not isinstance(asset, dict):
                raise ValueError("asset entry must be an object")
            name = asset.get("path")
            target = resolve(root, name)
            canonical = name.casefold()
            if canonical in declared:
                raise ValueError(f"duplicate asset path: {name}")
            declared.add(canonical)
            expected = asset.get("sha256")
            if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected):
                raise ValueError(f"{name}: expected a lowercase SHA-256 digest")
            for key in ("origin", "license"):
                if not isinstance(asset.get(key), str) or not asset[key].strip():
                    raise ValueError(f"{name}: missing {key}")
            if "notice" in asset:
                notice = resolve(root, asset["notice"])
                if not notice.is_file() or notice.stat().st_size == 0:
                    raise ValueError(f"{name}: notice missing or empty")
            elif asset["origin"] != "original":
                raise ValueError(f"{name}: third-party origin requires a notice file")
            if not target.is_file():
                raise ValueError(f"{name}: asset file missing")
            if digest(target) != expected:
                raise ValueError(f"{name}: checksum mismatch")
            verified += 1
        except (ValueError, OSError) as error:
            problems.append({"entry": index, "error": str(error)})
    return {"verified": verified, "declared": len(manifest["assets"]), "problems": problems}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--root", type=Path, help="Release directory, defaulting to the manifest's directory")
    args = parser.parse_args()
    try:
        document = json.loads(args.manifest.read_text(encoding="utf-8"))
        report = audit(args.root or args.manifest.parent, document)
    except (ValueError, OSError) as error:
        parser.exit(2, f"asset-ledger: {error}\n")
    print(json.dumps(report, indent=2))
    raise SystemExit(1 if report["problems"] else 0)


if __name__ == "__main__":
    main()
