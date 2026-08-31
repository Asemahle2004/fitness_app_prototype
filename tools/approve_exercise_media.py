#!/usr/bin/env python3
"""Approve a staged LeanEat exercise image for production.

Example:
  python tools/approve_exercise_media.py plank male \
    --source "LeanEat original" --license "LeanEat-owned" \
    --notes "Technique and rights reviewed"

Required environment variable:
  SUPABASE_SERVICE_ROLE_KEY

Never commit the service-role key to GitHub.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT_URL = "https://ukrapyyqyrwhbyjhkxeh.supabase.co"


def _request(url: str, *, method: str = "GET", data: bytes | None = None,
             headers: dict[str, str] | None = None) -> bytes:
    request = urllib.request.Request(url, data=data, method=method)
    for key, value in (headers or {}).items():
        request.add_header(key, value)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body}") from exc


def _headers(service_key: str) -> dict[str, str]:
    return {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
    }


def _exercise(service_key: str, exercise_id: str) -> dict | None:
    params = urllib.parse.urlencode({
        "select": "id,name,male_image_path,female_image_path",
        "id": f"eq.{exercise_id}",
    })
    raw = _request(
        f"{PROJECT_URL}/rest/v1/exercises?{params}",
        headers={**_headers(service_key), "Accept": "application/json"},
    )
    rows = json.loads(raw.decode("utf-8"))
    return rows[0] if rows else None


def _upsert_asset(service_key: str, *, exercise_id: str, sex: str,
                  storage_path: str, source: str, license_name: str,
                  notes: str) -> None:
    params = urllib.parse.urlencode({"on_conflict": "exercise_id,sex,media_type"})
    payload = json.dumps({
        "exercise_id": exercise_id,
        "sex": sex,
        "media_type": "image",
        "storage_path": storage_path,
        "source_name": source,
        "license_name": license_name,
        "technique_reviewed": True,
        "rights_reviewed": True,
        "review_notes": notes,
        "reviewed_at": "now()",
    }).replace('"now()"', 'null').encode("utf-8")

    # reviewed_at is set separately so PostgREST does not receive a SQL expression.
    data = json.loads(payload.decode("utf-8"))
    data.pop("reviewed_at", None)
    _request(
        f"{PROJECT_URL}/rest/v1/exercise_media_assets?{params}",
        method="POST",
        data=json.dumps(data).encode("utf-8"),
        headers={
            **_headers(service_key),
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )


def _approve_exercise_row(service_key: str, *, exercise_id: str, sex: str,
                          source: str, license_name: str, notes: str) -> None:
    fields = {
        f"{sex}_image_reviewed": True,
        "media_source": source,
        "media_license": license_name,
        "media_review_notes": notes,
    }
    params = urllib.parse.urlencode({"id": f"eq.{exercise_id}"})
    _request(
        f"{PROJECT_URL}/rest/v1/exercises?{params}",
        method="PATCH",
        data=json.dumps(fields).encode("utf-8"),
        headers={
            **_headers(service_key),
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        },
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("exercise_id")
    parser.add_argument("sex", choices=("male", "female"))
    parser.add_argument("--source", default="LeanEat original")
    parser.add_argument("--license", dest="license_name", default="LeanEat-owned")
    parser.add_argument("--notes", default="Technique and media rights reviewed for production use.")
    args = parser.parse_args()

    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not service_key:
        print("ERROR: SUPABASE_SERVICE_ROLE_KEY is not set.", file=sys.stderr)
        return 2

    exercise = _exercise(service_key, args.exercise_id)
    if exercise is None:
        print(f"ERROR: exercise not found: {args.exercise_id}", file=sys.stderr)
        return 2

    path_key = f"{args.sex}_image_path"
    storage_path = (exercise.get(path_key) or "").strip()
    if not storage_path:
        print(
            f"ERROR: {exercise['name']} has no staged {args.sex} image path. Upload it first.",
            file=sys.stderr,
        )
        return 2

    _upsert_asset(
        service_key,
        exercise_id=args.exercise_id,
        sex=args.sex,
        storage_path=storage_path,
        source=args.source,
        license_name=args.license_name,
        notes=args.notes,
    )
    _approve_exercise_row(
        service_key,
        exercise_id=args.exercise_id,
        sex=args.sex,
        source=args.source,
        license_name=args.license_name,
        notes=args.notes,
    )

    print(f"APPROVED: {exercise['name']} / {args.sex} / {storage_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
