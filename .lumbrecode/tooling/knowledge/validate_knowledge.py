"""Validate LumbreCode knowledge documents, and size up a change for `/knowledge finish`.

Two subcommands:

``check [PATH ...]`` (the default)
    Validates knowledge drafts and the local manifest before anything is
    proposed for the central knowledge base:

    1. frontmatter of every Markdown file against
       ``schemas/knowledge/v1/frontmatter.schema.json``;
    2. ``manifest.yaml`` against ``schemas/knowledge/v1/manifest.schema.json``;
    3. rules JSON Schema cannot express -- the ID prefix matches the type,
       ``implemented``/``production`` needs at least ``code-verified``
       evidence, a reuse candidate is never a released library, IDs are
       unique, relationship targets exist;
    4. publication safety -- secrets, personal e-mail addresses and base64
       images are errors; screenshots that are outdated or need a privacy
       review must not carry a Drive file ID;
    5. relative links and screenshot paths resolve inside the repository.

``scope RANGE``
    Sorts the paths changed in a git range (``main..HEAD``) into buckets and
    says whether the change *looks* material for the knowledge base. It is the
    materiality hint of `/knowledge finish`, not a verdict: a one-line change
    can switch on a feature flag.

Usage:
    python .lumbrecode/tooling/knowledge/validate_knowledge.py docs/knowledge
    python .lumbrecode/tooling/knowledge/validate_knowledge.py scope main..HEAD
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError as error:
    raise SystemExit(
        "Missing validation dependencies. Install with:\n"
        "python -m pip install PyYAML jsonschema"
    ) from error

SCRIPT = Path(__file__).resolve()
# <root>/tooling/knowledge/ here, <root>/.lumbrecode/tooling/knowledge/ in a
# consumer: `schemas/` is two levels up in both cases.
SCHEMAS = SCRIPT.parents[2] / "schemas" / "knowledge" / "v1"

ID_PREFIX = {
    "application": "app.",
    "template": "template.",
    "capability": "cap.",
    "implementation": "impl.",
    "library": "lib.",
    "standard": "std.",
    "known-issue": "issue.",
    "reuse-candidate": "candidate.",
    "feature": "feat.",
    "screenshot": "shot.",
}

VERIFICATION_RANK = {
    "reported": 0,
    "documentation-reviewed": 1,
    "code-verified": 2,
    "test-verified": 3,
    "release-verified": 4,
}

SECRET_PATTERNS = [
    ("GitHub token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}")),
    ("GitHub token", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}")),
    ("private key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("Google API key", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("API secret key", re.compile(r"\bsk-[A-Za-z0-9_-]{20,}")),
    ("bearer token", re.compile(r"\bBearer\s+[A-Za-z0-9._~+/-]{20,}=*")),
    ("password assignment", re.compile(r"(?i)\b(?:password|passwd|secret)\s*[:=]\s*['\"][^'\"\s]{6,}['\"]")),
]
EMAIL = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
# Addresses that are not personal data: documentation placeholders and
# no-reply senders.
EMAIL_ALLOWED = re.compile(
    r"(?i)@(?:example\.(?:com|org|net)|users\.noreply\.github\.com)$|^(?:noreply|no-reply)@"
)
BASE64_IMAGE = re.compile(r"data:image/[a-z+]+;base64,", re.I)
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)\)|!\[[^\]]*\]\(([^)\s]+)\)")
FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)


STRING_KEYS = {"revision", "app_version", "version", "id", "drive_file_id"}


def _normalise_dates(value):
    """YAML turns an unquoted 2026-10-16 into a date; the schemas expect strings."""
    if isinstance(value, (datetime.date, datetime.datetime)):
        return value.isoformat()
    if isinstance(value, dict):
        # An all-digit short SHA (`6657053`) or a version like `1` loads as a
        # number; both are identifiers and the schemas expect strings.
        return {
            key: str(item) if key in STRING_KEYS and isinstance(item, (int, float)) else _normalise_dates(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [_normalise_dates(item) for item in value]
    return value


def _load_schema(name: str) -> Draft202012Validator:
    schema = json.loads((SCHEMAS / name).read_text(encoding="utf-8"))
    return Draft202012Validator(schema, format_checker=FormatChecker())


def _repo_root(start: Path) -> Path:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start if start.is_dir() else start.parent,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        return Path(out).resolve()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return (start if start.is_dir() else start.parent).resolve()


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, where: Path | str, message: str) -> None:
        self.errors.append(f"{where}: {message}")

    def warn(self, where: Path | str, message: str) -> None:
        self.warnings.append(f"{where}: {message}")


def _scan_text(rel: str, text: str, report: Report) -> None:
    for label, pattern in SECRET_PATTERNS:
        if pattern.search(text):
            report.error(rel, f"possible {label}; remove it before publication")
    for match in EMAIL.finditer(text):
        address = match.group(0)
        if not EMAIL_ALLOWED.search(address):
            report.error(rel, f"e-mail address {address!r} may be personal data")
    if BASE64_IMAGE.search(text):
        report.error(rel, "embedded base64 image; reference the file instead")


def _check_links(rel: str, path: Path, text: str, repo: Path, report: Report) -> None:
    for match in MARKDOWN_LINK.finditer(text):
        target = match.group(1) or match.group(2)
        if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I) or target.startswith("#"):
            continue  # URL, mailto:, anchor
        target = target.split("#", 1)[0]
        if not target or "<" in target:
            continue  # template placeholder
        candidates = [(path.parent / target).resolve(), (repo / target).resolve()]
        if not any(candidate.exists() for candidate in candidates):
            report.warn(rel, f"link target not found: {target}")


def _check_entity(rel: str, data: dict, report: Report) -> None:
    kind = data.get("type")
    entity_id = data.get("id")
    prefix = ID_PREFIX.get(kind)
    if prefix and entity_id and not entity_id.startswith(prefix):
        report.error(rel, f"id {entity_id!r} does not match type {kind!r} (expected prefix {prefix!r})")
    if prefix and not entity_id:
        report.error(rel, f"type {kind!r} requires a stable id")

    lifecycle = data.get("lifecycle")
    verification = data.get("verification")
    if lifecycle in {"implemented", "production"}:
        if verification is None or VERIFICATION_RANK.get(verification, -1) < VERIFICATION_RANK["code-verified"]:
            report.error(
                rel,
                f"lifecycle {lifecycle!r} needs verification code-verified or better, "
                f"found {verification!r}",
            )
    if lifecycle == "production" and verification != "release-verified":
        report.warn(rel, "lifecycle 'production' without release-verified evidence")

    if kind == "reuse-candidate":
        if lifecycle == "production":
            report.error(rel, "a reuse candidate is not a released library (lifecycle production)")
        if "version" in data or "package_version" in data:
            report.error(rel, "a reuse candidate must not carry a package version")

    if data.get("status") == "current" and kind in {"application", "feature-catalog"}:
        for field in ("revision", "last_verified"):
            if not data.get(field):
                report.error(rel, f"a current {kind} document needs {field!r}")


def _check_markdown(path: Path, repo: Path, schema: Draft202012Validator, report: Report,
                    ids: dict[str, str], targets: list[tuple[str, str]]) -> None:
    rel = path.relative_to(repo).as_posix() if path.is_relative_to(repo) else str(path)
    text = path.read_text(encoding="utf-8")
    _scan_text(rel, text, report)
    _check_links(rel, path, text, repo, report)

    match = FRONTMATTER.match(text)
    if not match:
        report.warn(rel, "no YAML frontmatter; not a knowledge document")
        return
    try:
        data = _normalise_dates(yaml.safe_load(match.group(1)) or {})
    except yaml.YAMLError as error:
        report.error(rel, f"frontmatter is not valid YAML: {error}")
        return
    if not isinstance(data, dict):
        report.error(rel, "frontmatter must be a mapping")
        return

    for error in sorted(schema.iter_errors(data), key=lambda e: list(e.absolute_path)):
        location = "/".join(str(p) for p in error.absolute_path) or "(root)"
        report.error(rel, f"frontmatter {location}: {error.message}")

    _check_entity(rel, data, report)

    entity_id = data.get("id")
    if entity_id:
        if entity_id in ids and ids[entity_id] != rel:
            report.error(rel, f"duplicate id {entity_id!r} (also in {ids[entity_id]})")
        ids.setdefault(entity_id, rel)
        for alias in data.get("aliases") or []:
            ids.setdefault(f"alias:{alias}", rel)
    for relationship in data.get("relationships") or []:
        if isinstance(relationship, dict) and relationship.get("target"):
            targets.append((rel, relationship["target"]))
    for key in ("derived_from",):
        if isinstance(data.get(key), str):
            targets.append((rel, data[key]))


def _check_manifest(path: Path, repo: Path, report: Report, ids: dict[str, str]) -> None:
    rel = path.relative_to(repo).as_posix() if path.is_relative_to(repo) else str(path)
    text = path.read_text(encoding="utf-8")
    _scan_text(rel, text, report)
    try:
        data = _normalise_dates(yaml.safe_load(text))
    except yaml.YAMLError as error:
        report.error(rel, f"not valid YAML: {error}")
        return
    validator = _load_schema("manifest.schema.json")
    for error in sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path)):
        location = "/".join(str(p) for p in error.absolute_path) or "(root)"
        report.error(rel, f"{location}: {error.message}")
    if not isinstance(data, dict):
        return

    for source in data.get("sources") or []:
        if isinstance(source, dict) and source.get("path") and not (repo / source["path"]).exists():
            report.error(rel, f"source path does not exist: {source['path']}")
    shots = data.get("screenshots") or {}
    for key in ("manifest", "directory"):
        value = shots.get(key)
        if value and not (repo / value).exists():
            report.error(rel, f"screenshots.{key} does not exist: {value}")
    seen: set[str] = set()
    for shot in shots.get("selected") or []:
        if not isinstance(shot, dict):
            continue
        shot_id = shot.get("id", "?")
        if shot_id in seen:
            report.error(rel, f"screenshot {shot_id} selected twice")
        seen.add(shot_id)
        ids.setdefault(shot_id, rel)
        _check_shot(rel, shot, repo, report, source_key="file")
    snapshot = data.get("snapshot") or {}
    if snapshot.get("path") and not (repo / snapshot["path"]).exists():
        report.error(rel, f"snapshot.path does not exist: {snapshot['path']}")


def _check_shot(rel: str, shot: dict, repo: Path, report: Report, source_key: str) -> None:
    shot_id = shot.get("id", "?")
    source = shot.get(source_key)
    if source and not (repo / source).exists():
        report.error(rel, f"screenshot {shot_id}: file not found: {source}")
    published = bool(shot.get("drive_file_id"))
    if shot.get("verification") == "outdated":
        (report.error if published else report.warn)(
            rel, f"screenshot {shot_id} is outdated" + (" but published" if published else "")
        )
    if shot.get("privacy") == "needs-review":
        (report.error if published else report.warn)(
            rel, f"screenshot {shot_id} needs a privacy review" + (" but is published" if published else "")
        )


def _check_screenshot_index(path: Path, repo: Path, report: Report, ids: dict[str, str]) -> None:
    rel = path.relative_to(repo).as_posix() if path.is_relative_to(repo) else str(path)
    text = path.read_text(encoding="utf-8")
    _scan_text(rel, text, report)
    try:
        data = yaml.safe_load(text)
    except yaml.YAMLError as error:
        report.error(rel, f"not valid YAML: {error}")
        return
    entries = data.get("screenshots") if isinstance(data, dict) else data
    if not isinstance(entries, list):
        report.error(rel, "a screenshot index is a list of entries (or a mapping with 'screenshots')")
        return
    for entry in entries:
        if not isinstance(entry, dict) or not str(entry.get("id", "")).startswith("shot."):
            report.error(rel, f"entry without a shot.* id: {entry!r}"[:160])
            continue
        if entry["id"] in ids and ids[entry["id"]] != rel:
            pass  # the manifest selecting an indexed shot is expected
        ids.setdefault(entry["id"], rel)
        if not entry.get("source"):
            report.error(rel, f"screenshot {entry['id']}: missing source path")
        _check_shot(rel, entry, repo, report, source_key="source")


def check(paths: list[Path], repo_arg: Path | None) -> int:
    report = Report()
    schema = _load_schema("frontmatter.schema.json")
    ids: dict[str, str] = {}
    targets: list[tuple[str, str]] = []

    files: list[Path] = []
    for path in paths:
        path = path.resolve()
        if path.is_dir():
            files.extend(sorted(p for p in path.rglob("*") if p.is_file()))
        elif path.is_file():
            files.append(path)
        else:
            report.error(path, "does not exist")
    repo = repo_arg.resolve() if repo_arg else _repo_root(paths[0].resolve() if paths else Path.cwd())

    for file in files:
        name = file.name.lower()
        if file.suffix.lower() == ".md":
            _check_markdown(file, repo, schema, report, ids, targets)
        elif name in {"manifest.yaml", "manifest.yml"}:
            _check_manifest(file, repo, report, ids)
        elif name in {"screenshots.yaml", "screenshots.yml"} and "knowledge" in file.as_posix():
            _check_screenshot_index(file, repo, report, ids)

    for rel, target in sorted(set(targets)):
        if target not in ids:
            report.warn(rel, f"relationship target {target!r} is not defined in the validated set; "
                             "make sure it exists centrally")

    for line in report.warnings:
        print(f"WARN  {line}")
    for line in report.errors:
        print(f"ERROR {line}", file=sys.stderr)
    checked = len(files)
    if report.errors:
        print(f"\nKnowledge validation failed: {len(report.errors)} error(s), "
              f"{len(report.warnings)} warning(s) in {checked} file(s).", file=sys.stderr)
        return 1
    print(f"Knowledge documents are valid: {checked} file(s), {len(report.warnings)} warning(s).")
    return 0


# --- scope -----------------------------------------------------------------

BUCKETS: list[tuple[str, re.Pattern[str]]] = [
    ("generated", re.compile(r"\.(g|freezed|gr|mocks|config)\.dart$|\.generated\.|(^|/)generated/")),
    ("lockfile", re.compile(r"(^|/)(pubspec\.lock|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Podfile\.lock|Cargo\.lock)$")),
    ("baseline", re.compile(r"(^|/)\.lumbrecode/")),
    ("ci-tooling", re.compile(r"(^|/)(\.github|\.claude|scripts|tools|tooling|\.vscode|\.idea)/|(^|/)(Makefile|melos\.yaml|analysis_options\.yaml|\.editorconfig|\.gitignore|renovate\.json5?)$")),
    ("screenshots", re.compile(r"(^|/)(design/)?screenshots/|\.(png|jpe?g|webp)$", re.I)),
    ("tests", re.compile(r"(^|/)(test|tests|integration_test|e2e|__tests__)/|_test\.dart$|\.(test|spec)\.[cm]?[jt]sx?$")),
    ("dependencies", re.compile(r"(^|/)(pubspec\.yaml|package\.json)$")),
    ("localization", re.compile(r"\.arb$|(^|/)(l10n|i18n|locales?)/")),
    ("documentation", re.compile(r"\.md$|(^|/)docs/|(^|/)CHANGELOG|(^|/)VERSION$")),
    ("styling", re.compile(r"(^|/)(theme|themes|styles?)/|\.(s?css|less)$|_theme\.dart$|(^|/)colors?\.dart$", re.I)),
    ("product", re.compile(r"\.(dart|[cm]?[jt]sx?|vue|svelte|astro|py|go|kt|swift|java|sql)$")),
]


def _git(repo: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True, check=True).stdout


def scope(range_spec: str, repo_arg: Path | None, threshold: int, as_json: bool) -> int:
    repo = repo_arg.resolve() if repo_arg else _repo_root(Path.cwd())
    try:
        numstat = _git(repo, "diff", "--numstat", "-M", range_spec)
        status = _git(repo, "diff", "--name-status", "-M", range_spec)
    except subprocess.CalledProcessError as error:
        print(f"git diff failed for {range_spec!r}: {error.stderr.strip()}", file=sys.stderr)
        return 2

    added_files = {line.split("\t")[-1] for line in status.splitlines() if line.startswith("A")}
    buckets: dict[str, dict[str, int]] = {}
    product_lines = 0
    new_product_files = 0
    for line in numstat.splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        added, removed, path = parts[0], parts[1], parts[-1]
        lines = (int(added) if added.isdigit() else 0) + (int(removed) if removed.isdigit() else 0)
        bucket = next((name for name, pattern in BUCKETS if pattern.search(path)), "other")
        entry = buckets.setdefault(bucket, {"files": 0, "lines": 0})
        entry["files"] += 1
        entry["lines"] += lines
        if bucket == "product":
            product_lines += lines
            if path in added_files:
                new_product_files += 1

    reasons: list[str] = []
    if new_product_files:
        reasons.append(f"{new_product_files} new product source file(s)")
    if product_lines > threshold:
        reasons.append(f"{product_lines} changed product lines (> {threshold})")
    if "dependencies" in buckets:
        reasons.append("dependency manifest changed")
    if "screenshots" in buckets:
        reasons.append("screenshots changed")
    if "localization" in buckets and buckets["localization"]["lines"] > threshold:
        reasons.append("localization resources changed substantially")
    verdict = "material" if reasons else "minor"
    if not reasons:
        reasons.append("only tests, docs, styling, generated code, lockfiles, CI/tooling or small product edits changed")

    result = {"range": range_spec, "verdict": verdict, "reasons": reasons, "buckets": buckets}
    if as_json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Range: {range_spec}")
        for name in sorted(buckets):
            print(f"  {name:13} {buckets[name]['files']:4} file(s) {buckets[name]['lines']:6} line(s)")
        print(f"Verdict (hint): {verdict} - " + "; ".join(reasons))
        if verdict == "minor":
            print('Likely result: "No material central knowledge update required." Confirm by reading the diff.')
    return 0


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "scope":
        parser = argparse.ArgumentParser(prog="validate_knowledge.py scope")
        parser.add_argument("range", help="git range, e.g. main..HEAD")
        parser.add_argument("--repo", type=Path)
        parser.add_argument("--threshold", type=int, default=40,
                            help="changed product lines above which a change counts as material")
        parser.add_argument("--json", action="store_true")
        args = parser.parse_args(argv[1:])
        return scope(args.range, args.repo, args.threshold, args.json)

    if argv and argv[0] == "check":
        argv = argv[1:]
    parser = argparse.ArgumentParser(prog="validate_knowledge.py [check]")
    parser.add_argument("paths", nargs="*", type=Path, default=[Path("docs/knowledge")])
    parser.add_argument("--repo", type=Path, help="repository root for resolving paths (default: git toplevel)")
    args = parser.parse_args(argv)
    return check(args.paths, args.repo)


if __name__ == "__main__":
    raise SystemExit(main())
