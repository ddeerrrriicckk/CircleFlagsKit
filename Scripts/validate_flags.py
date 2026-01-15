# validate_flags.py

#!/usr/bin/env python3
"""
validate_flags.py (Python 3.13+)

Validate CircleFlagsKit generated PNG resources.

Typical checks:
- Resources directory exists and contains PNGs
- Filenames follow expected naming rules
- Optional allowlist: ensure required codes exist (allowed_codes.txt)
- Optional fallback: ensure e.g. xx.png exists
- Detect duplicates after normalization (case-insensitive)

This script is intended for developer/CI usage, not runtime.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ALPHA2_RE = re.compile(r"^[a-z]{2}$")
DEFAULT_PNG_RE = re.compile(r"^[a-z0-9][a-z0-9\-]*$")  # generic safe key, if not strict-alpha2


@dataclass(frozen=True)
class ValidationConfig:
    resources_dir: Path
    allowlist_path: Path | None
    require_fallback_code: str | None
    strict_alpha2: bool
    extra_allowed_codes: set[str]


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def read_allowlist(path: Path) -> set[str]:
    """
    Read allowlist file (one code per line, supports comments starting with '#').

    Returns lowercased codes.
    """
    codes: set[str] = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip().lower()
        if not line or line.startswith("#"):
            continue
        codes.add(line)
    return codes


def list_png_files(resources_dir: Path) -> list[Path]:
    return sorted([p for p in resources_dir.iterdir() if p.is_file() and p.suffix.lower() == ".png"])


def validate_filename(code: str, cfg: ValidationConfig) -> tuple[bool, str | None]:
    """
    Validate the code portion (filename without extension).

    If strict_alpha2=True:
      - allow: [a-z]{2} + extra_allowed_codes (e.g. 'xx')
    Else:
      - allow generic safe keys (letters/digits/dash), plus extra_allowed_codes
    """
    if code in cfg.extra_allowed_codes:
        return True, None

    if cfg.strict_alpha2:
        if ALPHA2_RE.match(code):
            return True, None
        return False, "not ISO alpha-2 (expected exactly 2 lowercase letters)"
    else:
        if DEFAULT_PNG_RE.match(code):
            return True, None
        return False, "invalid key format (expected lowercase letters/digits/dash)"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Validate CircleFlagsKit PNG resources (for dev/CI)."
    )
    parser.add_argument(
        "--resources",
        required=True,
        type=Path,
        help="Path to the Resources directory (e.g. Sources/CircleFlagsKit/Resources).",
    )
    parser.add_argument(
        "--allowlist",
        required=False,
        type=Path,
        default=None,
        help="Optional allowlist file path (one code per line). If provided, script checks all codes exist.",
    )
    parser.add_argument(
        "--require-fallback",
        required=False,
        default=None,
        help="Optional fallback code to require (e.g. 'xx' means xx.png must exist).",
    )
    parser.add_argument(
        "--strict-alpha2",
        action="store_true",
        help="If set, only allow ISO alpha-2 codes (xx, us, gb...), plus extras you explicitly allow.",
    )
    parser.add_argument(
        "--allow-extra",
        action="append",
        default=[],
        help="Extra allowed codes besides alpha2, can be provided multiple times. Example: --allow-extra xx",
    )

    args = parser.parse_args(argv)

    resources_dir: Path = args.resources
    allowlist_path: Path | None = args.allowlist
    require_fallback_code: str | None = args.require_fallback
    strict_alpha2: bool = bool(args.strict_alpha2)

    extra_allowed = {c.strip().lower() for c in args.allow_extra if c.strip()}
    if require_fallback_code:
        extra_allowed.add(require_fallback_code.strip().lower())

    cfg = ValidationConfig(
        resources_dir=resources_dir,
        allowlist_path=allowlist_path,
        require_fallback_code=require_fallback_code.strip().lower() if require_fallback_code else None,
        strict_alpha2=strict_alpha2,
        extra_allowed_codes=extra_allowed,
    )

    # ---------- checks ----------
    errors: list[str] = []
    warnings: list[str] = []

    if not cfg.resources_dir.exists():
        errors.append(f"Resources directory does not exist: {cfg.resources_dir}")
        report(errors, warnings)
        return 2

    if not cfg.resources_dir.is_dir():
        errors.append(f"Resources path is not a directory: {cfg.resources_dir}")
        report(errors, warnings)
        return 2

    pngs = list_png_files(cfg.resources_dir)

    # Ignore .gitkeep etc; only care about png count.
    if not pngs:
        errors.append(
            f"No PNG files found in: {cfg.resources_dir}\n"
            "Did you run update_flags.sh to generate resources?"
        )
        report(errors, warnings)
        return 2

    # 1) Validate filenames + detect duplicates after normalization
    seen_normalized: dict[str, Path] = {}
    for p in pngs:
        code = p.stem  # filename without extension
        normalized = code.strip().lower()

        ok, reason = validate_filename(normalized, cfg)
        if not ok:
            errors.append(f"Invalid filename: {p.name} ({reason})")

        # Detect duplicates after normalization (case-insensitive)
        if normalized in seen_normalized and seen_normalized[normalized] != p:
            errors.append(
                f"Duplicate code after normalization: '{normalized}'\n"
                f" - {seen_normalized[normalized].name}\n"
                f" - {p.name}"
            )
        else:
            seen_normalized[normalized] = p

        # Warn if file name isn't already normalized
        if code != normalized:
            warnings.append(f"Non-normalized filename: {p.name} (should be {normalized}.png)")

    # 2) Optional: require fallback asset, e.g. xx.png
    if cfg.require_fallback_code:
        expected = cfg.resources_dir / f"{cfg.require_fallback_code}.png"
        if not expected.exists():
            errors.append(f"Missing required fallback asset: {expected.name}")

    # 3) Optional: allowlist coverage (ensure listed codes exist)
    if cfg.allowlist_path:
        if not cfg.allowlist_path.exists():
            errors.append(f"Allowlist file does not exist: {cfg.allowlist_path}")
        else:
            required_codes = read_allowlist(cfg.allowlist_path)
            present_codes = set(seen_normalized.keys())

            missing = sorted([c for c in required_codes if c not in present_codes])
            extra = sorted([c for c in present_codes if c not in required_codes])

            if missing:
                errors.append(
                    "Missing PNGs for allowlist codes:\n  - " + "\n  - ".join(missing)
                )

            # "extra" isn't necessarily an error (depends on your policy).
            # If you want a strict match, change this warning into an error.
            if extra:
                warnings.append(
                    "Extra PNGs found not listed in allowlist (may be OK):\n  - "
                    + "\n  - ".join(extra[:80])
                    + ("" if len(extra) <= 80 else f"\n  ...and {len(extra) - 80} more")
                )

    report(errors, warnings)

    return 0 if not errors else 2


def report(errors: list[str], warnings: list[str]) -> None:
    if warnings:
        eprint("==> WARNINGS:")
        for w in warnings:
            eprint(f"- {w}")

    if errors:
        eprint("\n==> ERRORS:")
        for err in errors:
            eprint(f"- {err}")

        eprint("\nValidation FAILED.")
    else:
        print("Validation OK.")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
