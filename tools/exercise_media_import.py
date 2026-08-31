#!/usr/bin/env python3
"""Bulk uploader for LeanEat production exercise media.

This is a developer tool, not app runtime code. It intentionally requires the
Supabase service-role key from the local environment so no privileged secret is
committed to GitHub or bundled into Flutter.

Expected source layout:

exercise_media_source/
  plank/
    male.webp
    female.webp
  dumbbell_bench_press/
    male.webp
    female.webp

Run without --apply for a safe validation/dry run.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse
import urllib.request

BUCKET = "exercise-media"
ALLOWED_EXTENSIONS = (".webp", ".png", ".jpg", ".jpeg")
MAX_BYTES = 8 * 1024 * 1024
MIN_BYTES = 4 * 1024


def env_required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(
            f"Missing {name}. Set it in your LOCAL terminal environment. "
            "Never paste the service-role key into GitHub or Flutter source code."
        )
    return value.rstrip("/") if name == "SUPABASE_URL" else value


def request(
    url: str,
    *,
    key: str,
    method: str = "GET",
    body: bytes | None = None,
    content_type: str | None = None,
    extra_headers: dict[str, str] | None = None,
) -> bytes:
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
    }
    if content_type:
        headers["Content-Type"] = content_type
    if extra_headers:
        headers.update(extra_headers)

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def fetch_active_exercises(base_url: str, key: str) -> dict[str, str]:
    query = urllib.parse.urlencode(
        {
            "select": "id,name",
            "is_active": "eq.true",
            "order": "name.asc",
        }
    )
    raw = request(f"{base_url}/rest/v1/exercises?{query}", key=key)
    rows = json.loads(raw.decode("utf-8"))
    return {row["id"]: row["name"] for row in rows}


def fetch_coverage(base_url: str, key: str) -> dict[str, int]:
    raw = request(
        f"{base_url}/rest/v1/exercise_media_coverage?select=*",
        key=key,
    )
    rows = json.loads(raw.decode("utf-8"))
    if not rows:
        return {}
    return {k: int(v or 0) for k, v in rows[0].items()}


def find_gender_file(folder: Path, gender: str) -> Path | None:
    for extension in ALLOWED_EXTENSIONS:
        candidate = folder / f"{gender}{extension}"
        if candidate.exists():
            return candidate
    return None


def validate_file(path: Path) -> list[str]:
    issues: list[str] = []
    size = path.stat().st_size
    if size < MIN_BYTES:
        issues.append(f"file is suspiciously small ({size} bytes)")
    if size > MAX_BYTES:
        issues.append(f"file exceeds {MAX_BYTES // (1024 * 1024)} MB")
    if path.suffix.lower() not in ALLOWED_EXTENSIONS:
        issues.append(f"unsupported extension {path.suffix}")
    return issues


def upload_file(
    base_url: str,
    key: str,
    exercise_id: str,
    gender: str,
    source: Path,
) -> str:
    extension = source.suffix.lower()
    destination = f"{exercise_id}/{gender}{extension}"
    encoded = "/".join(urllib.parse.quote(part, safe="") for part in destination.split("/"))
    mime = mimetypes.guess_type(source.name)[0] or "application/octet-stream"
    request(
        f"{base_url}/storage/v1/object/{BUCKET}/{encoded}",
        key=key,
        method="POST",
        body=source.read_bytes(),
        content_type=mime,
        extra_headers={"x-upsert": "true"},
    )
    return destination


def patch_exercise(
    base_url: str,
    key: str,
    exercise_id: str,
    updates: dict[str, object],
) -> None:
    query = urllib.parse.urlencode({"id": f"eq.{exercise_id}"})
    request(
        f"{base_url}/rest/v1/exercises?{query}",
        key=key,
        method="PATCH",
        body=json.dumps(updates).encode("utf-8"),
        content_type="application/json",
        extra_headers={"Prefer": "return=minimal"},
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate and bulk-upload LeanEat male/female exercise photos."
    )
    parser.add_argument(
        "--source",
        default="exercise_media_source",
        help="Local source directory (default: exercise_media_source)",
    )
    parser.add_argument(
        "--exercise",
        help="Import only one exercise id, e.g. dumbbell_bench_press",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually upload files and update Supabase. Without this flag the tool is dry-run only.",
    )
    parser.add_argument(
        "--reviewed",
        action="store_true",
        help=(
            "Mark imported photos reviewed. Use only after BOTH technique and media rights "
            "have been checked. Otherwise they stay hidden from production UI."
        ),
    )
    parser.add_argument(
        "--source-label",
        default="LeanEat commissioned/original media",
        help="Media source label stored in the exercise record.",
    )
    parser.add_argument(
        "--license",
        default="project-owned",
        help="Rights/license label stored in the exercise record.",
    )
    args = parser.parse_args()

    base_url = env_required("SUPABASE_URL")
    service_key = env_required("SUPABASE_SERVICE_ROLE_KEY")
    source_root = Path(args.source)

    if not source_root.exists():
        raise SystemExit(
            f"Source folder not found: {source_root}\n"
            "Create it using the layout documented in docs/exercise-media-import.md."
        )

    exercises = fetch_active_exercises(base_url, service_key)
    if args.exercise:
        if args.exercise not in exercises:
            raise SystemExit(f"Unknown active exercise id: {args.exercise}")
        selected = {args.exercise: exercises[args.exercise]}
    else:
        selected = exercises

    valid_jobs: list[tuple[str, str, Path]] = []
    missing_pairs = 0
    invalid_files = 0

    print(f"LeanEat media importer: checking {len(selected)} exercise(s)")
    for exercise_id, name in selected.items():
        folder = source_root / exercise_id
        male = find_gender_file(folder, "male") if folder.exists() else None
        female = find_gender_file(folder, "female") if folder.exists() else None

        if male is None or female is None:
            missing_pairs += 1
            missing = []
            if male is None:
                missing.append("male")
            if female is None:
                missing.append("female")
            print(f"MISS  {exercise_id:<36} {name} ({', '.join(missing)})")

        for gender, path in (("male", male), ("female", female)):
            if path is None:
                continue
            issues = validate_file(path)
            if issues:
                invalid_files += 1
                print(f"BAD   {exercise_id}/{gender}: {'; '.join(issues)}")
                continue
            valid_jobs.append((exercise_id, gender, path))

    print()
    print(f"Valid image files: {len(valid_jobs)}")
    print(f"Exercises missing at least one gender image: {missing_pairs}")
    print(f"Invalid image files: {invalid_files}")

    if not args.apply:
        print("\nDRY RUN ONLY. Add --apply when the source files are ready.")
        return 1 if invalid_files else 0

    if invalid_files:
        raise SystemExit("Refusing to upload while invalid files exist.")

    grouped_updates: dict[str, dict[str, object]] = {}
    for index, (exercise_id, gender, path) in enumerate(valid_jobs, start=1):
        print(f"UPLOAD {index}/{len(valid_jobs)} {exercise_id}/{gender} ...", end=" ", flush=True)
        destination = upload_file(base_url, service_key, exercise_id, gender, path)
        updates = grouped_updates.setdefault(exercise_id, {})
        updates[f"{gender}_image_path"] = destination
        updates[f"{gender}_image_reviewed"] = bool(args.reviewed)
        print("OK")

    for exercise_id, updates in grouped_updates.items():
        updates["media_source"] = args.source_label
        updates["media_license"] = args.license
        updates["media_review_notes"] = (
            "Imported and marked reviewed by media importer."
            if args.reviewed
            else "Imported; pending technique and rights review."
        )
        patch_exercise(base_url, service_key, exercise_id, updates)

    coverage = fetch_coverage(base_url, service_key)
    if coverage:
        print("\nSupabase media coverage")
        print(f"Active exercises: {coverage.get('active_exercises', 0)}")
        print(f"Male images: {coverage.get('male_images', 0)}")
        print(f"Female images: {coverage.get('female_images', 0)}")
        print(f"Fully publishable pairs: {coverage.get('fully_publishable_exercises', 0)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
