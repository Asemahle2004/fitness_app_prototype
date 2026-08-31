#!/usr/bin/env python3
"""Batch-upload reviewed LeanEat exercise media to Supabase Storage.

Expected source layout:

media_source/
  plank/
    male.webp
    female.webp
  dumbbell_bench_press/
    male.webp
    female.webp

The script uploads each image to the public `exercise-media` bucket and updates
public.exercises.male_image_path / female_image_path.

Required environment variable:
  SUPABASE_SERVICE_ROLE_KEY

Optional:
  LEANEAT_MEDIA_SOURCE (defaults to ./media_source)

Never commit the service-role key to GitHub.
"""

from __future__ import annotations

import json
import mimetypes
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT_URL = "https://ukrapyyqyrwhbyjhkxeh.supabase.co"
BUCKET = "exercise-media"
SOURCE_ROOT = Path(os.environ.get("LEANEAT_MEDIA_SOURCE", "media_source"))
ALLOWED_EXTENSIONS = {".webp", ".png", ".jpg", ".jpeg"}


def _request(url: str, *, method: str = "GET", data: bytes | None = None,
             headers: dict[str, str] | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, method=method)
    for key, value in (headers or {}).items():
        req.add_header(key, value)
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} for {url}: {body}") from exc


def _headers(service_key: str) -> dict[str, str]:
    return {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
    }


def _active_exercise_ids(service_key: str) -> set[str]:
    query = urllib.parse.urlencode({
        "select": "id",
        "is_active": "eq.true",
    })
    raw = _request(
        f"{PROJECT_URL}/rest/v1/exercises?{query}",
        headers={**_headers(service_key), "Accept": "application/json"},
    )
    return {row["id"] for row in json.loads(raw.decode("utf-8"))}


def _upload_file(service_key: str, exercise_id: str, sex: str, path: Path) -> str:
    extension = path.suffix.lower()
    storage_path = f"{exercise_id}/{sex}{extension}"
    encoded = "/".join(urllib.parse.quote(part, safe="") for part in storage_path.split("/"))
    content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    _request(
        f"{PROJECT_URL}/storage/v1/object/{BUCKET}/{encoded}",
        method="POST",
        data=path.read_bytes(),
        headers={
            **_headers(service_key),
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )
    return storage_path


def _update_exercise(service_key: str, exercise_id: str, fields: dict[str, str]) -> None:
    query = urllib.parse.urlencode({"id": f"eq.{exercise_id}"})
    payload = json.dumps(fields).encode("utf-8")
    _request(
        f"{PROJECT_URL}/rest/v1/exercises?{query}",
        method="PATCH",
        data=payload,
        headers={
            **_headers(service_key),
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        },
    )


def main() -> int:
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not service_key:
        print("ERROR: SUPABASE_SERVICE_ROLE_KEY is not set.", file=sys.stderr)
        return 2
    if not SOURCE_ROOT.exists():
        print(f"ERROR: media source folder does not exist: {SOURCE_ROOT}", file=sys.stderr)
        return 2

    valid_ids = _active_exercise_ids(service_key)
    uploaded_images = 0
    updated_exercises = 0
    skipped = 0

    for folder in sorted(path for path in SOURCE_ROOT.iterdir() if path.is_dir()):
        exercise_id = folder.name
        if exercise_id not in valid_ids:
            print(f"SKIP {exercise_id}: no active exercise with this id")
            skipped += 1
            continue

        updates: dict[str, str] = {}
        for sex in ("male", "female"):
            candidates = [
                file for file in folder.iterdir()
                if file.is_file()
                and file.stem.lower() == sex
                and file.suffix.lower() in ALLOWED_EXTENSIONS
            ]
            if not candidates:
                continue
            if len(candidates) > 1:
                print(f"SKIP {exercise_id}/{sex}: more than one supported image file")
                skipped += 1
                continue
            storage_path = _upload_file(service_key, exercise_id, sex, candidates[0])
            updates[f"{sex}_image_path"] = storage_path
            uploaded_images += 1
            print(f"UPLOADED {exercise_id}: {sex} -> {storage_path}")

        if updates:
            _update_exercise(service_key, exercise_id, updates)
            updated_exercises += 1

    print()
    print(f"Uploaded images: {uploaded_images}")
    print(f"Updated exercises: {updated_exercises}")
    print(f"Skipped items: {skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
