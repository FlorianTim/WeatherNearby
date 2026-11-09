from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

def run(command: list[str], cwd: Path | None = None) -> None:
    subprocess.run(command, cwd=cwd, check=True)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="FlorianTim/lumbrecode-engineering")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--profile", required=True, choices=["common", "flutter", "webapp", "astro", "all"])
    parser.add_argument("--target", required=True, type=Path)
    args = parser.parse_args()

    if shutil.which("gh") is None:
        raise RuntimeError("GitHub CLI is required. Install it and run `gh auth login`.")

    run(["gh", "auth", "status"])

    asset = f"lumbrecode-baseline-v{args.tag.lstrip('v')}.zip"
    with tempfile.TemporaryDirectory(prefix="lumbrecode-baseline-") as temp_name:
        temp = Path(temp_name)
        run([
            "gh", "release", "download", args.tag,
            "--repo", args.repo,
            "--pattern", asset,
            "--dir", str(temp),
        ])
        archive_path = temp / asset
        extract = temp / "engineering"
        extract.mkdir()
        with zipfile.ZipFile(archive_path) as archive:
            archive.extractall(extract)

        candidates = list(extract.glob("*/scripts/apply_baseline.py"))
        if len(candidates) != 1:
            raise RuntimeError("Unexpected baseline archive structure.")

        script = candidates[0]
        run([
            "python", str(script),
            "--profile", args.profile,
            "--target", str(args.target.resolve()),
            "--apply",
        ])

    return 0

if __name__ == "__main__":
    raise SystemExit(main())
