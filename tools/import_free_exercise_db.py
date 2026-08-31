#!/usr/bin/env python3
"""Import free-exercise-db records into LeanIt's Supabase exercise catalogue.

The source dataset is yuhonas/free-exercise-db (Unlicense/public-domain
publication). The tool is intentionally dry-run by default and never stores a
Supabase service-role key in source code.

By default it prepares up to 300 exercises. Existing LeanIt exercise rows are
left untouched unless --update-existing is supplied.

Generic source images are stored in image_path. They are NOT shown by LeanIt
until --reviewed is supplied, which writes an [approved-generic] marker into
media_review_notes. Use --reviewed only after visually checking the imported
exercise demonstrations for technique and suitability.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter

SOURCE_REPO = "yuhonas/free-exercise-db"
SOURCE_JSON = (
    "https://raw.githubusercontent.com/"
    "yuhonas/free-exercise-db/main/dist/exercises.json"
)
SOURCE_IMAGE_BASE = (
    "https://raw.githubusercontent.com/"
    "yuhonas/free-exercise-db/main/exercises/"
)
SOURCE_LICENSE = "Unlicense / public-domain dedication"
DEFAULT_LIMIT = 300
BATCH_SIZE = 50


def request(
    url: str,
    *,
    method: str = "GET",
    key: str | None = None,
    body: bytes | None = None,
    headers: dict[str, str] | None = None,
) -> bytes:
    final_headers = {
        "User-Agent": "LeanIt-free-exercise-db-importer/1.0",
        "Accept": "application/json",
    }
    if key:
        final_headers["apikey"] = key
        final_headers["Authorization"] = f"Bearer {key}"
    if body is not None:
        final_headers["Content-Type"] = "application/json"
    if headers:
        final_headers.update(headers)

    req = urllib.request.Request(
        url,
        data=body,
        headers=final_headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def env_required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(
            f"Missing {name}. Set it in your LOCAL terminal environment. "
            "Never commit the Supabase service-role key."
        )
    return value.rstrip("/") if name == "SUPABASE_URL" else value


def fetch_source() -> list[dict[str, object]]:
    raw = request(SOURCE_JSON)
    data = json.loads(raw.decode("utf-8"))
    if not isinstance(data, list):
        raise RuntimeError("Unexpected source dataset shape: expected a JSON array")
    return [item for item in data if isinstance(item, dict)]


def leanit_id(name: str) -> str:
    value = name.lower().replace("&", "and")
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_")


def string_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip() for item in value if str(item).strip()]


def infer_locations(equipment: str | None, category: str | None) -> list[str]:
    equipment_value = (equipment or "").strip().lower()
    category_value = (category or "").strip().lower()

    if equipment_value in {"body only", "none", ""}:
        locations = ["Home", "Gym", "Outside"]
    elif equipment_value in {
        "dumbbell",
        "kettlebells",
        "bands",
        "medicine ball",
        "exercise ball",
        "foam roll",
        "other",
    }:
        locations = ["Home", "Gym"]
    else:
        locations = ["Gym"]

    if category_value == "cardio" and "Outside" not in locations:
        locations.append("Outside")

    return locations


def image_url(path: object) -> str | None:
    if not isinstance(path, str) or not path.strip():
        return None
    encoded = urllib.parse.quote(path.strip(), safe="/_-.()")
    return SOURCE_IMAGE_BASE + encoded


def transform(source: dict[str, object], *, reviewed: bool) -> dict[str, object] | None:
    name = str(source.get("name") or "").strip()
    if not name:
        return None

    images = source.get("images")
    first_image = None
    if isinstance(images, list) and images:
        first_image = image_url(images[0])

    equipment_value = source.get("equipment")
    equipment = str(equipment_value).strip() if equipment_value else "Bodyweight"
    category_value = source.get("category")
    category = str(category_value).strip() if category_value else "exercise"
    mechanic_value = source.get("mechanic")
    force_value = source.get("force")
    movement_pattern = (
        str(mechanic_value).strip()
        if mechanic_value
        else (str(force_value).strip() if force_value else None)
    )

    review_marker = "[approved-generic]" if reviewed else "[pending-generic]"
    review_text = (
        f"{review_marker} Imported from {SOURCE_REPO}. Generic source image; "
        "not sex-specific. Rights are declared under the repository Unlicense. "
        + (
            "Technique/suitability was manually reviewed before approval."
            if reviewed
            else "Technique/suitability review is still required before LeanIt displays it."
        )
    )

    return {
        "id": leanit_id(name),
        "name": name,
        "category": category,
        "primary_muscles": string_list(source.get("primaryMuscles")),
        "secondary_muscles": string_list(source.get("secondaryMuscles")),
        "equipment": [equipment],
        "difficulty": str(source.get("level") or "").strip() or None,
        "movement_pattern": movement_pattern,
        "locations": infer_locations(equipment, category),
        "instructions": string_list(source.get("instructions")),
        "common_mistakes": [],
        "image_path": first_image,
        "media_source": SOURCE_REPO,
        "media_license": SOURCE_LICENSE,
        "media_review_notes": review_text,
        "is_active": True,
    }


def fetch_existing_ids(base_url: str, key: str) -> set[str]:
    query = urllib.parse.urlencode({"select": "id", "limit": "5000"})
    raw = request(f"{base_url}/rest/v1/exercises?{query}", key=key)
    rows = json.loads(raw.decode("utf-8"))
    return {
        str(row.get("id"))
        for row in rows
        if isinstance(row, dict) and row.get("id")
    }


def upsert_batch(base_url: str, key: str, rows: list[dict[str, object]]) -> None:
    query = urllib.parse.urlencode({"on_conflict": "id"})
    request(
        f"{base_url}/rest/v1/exercises?{query}",
        method="POST",
        key=key,
        body=json.dumps(rows).encode("utf-8"),
        headers={
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )


def select_rows(
    source: list[dict[str, object]],
    *,
    limit: int,
    categories: set[str],
    existing_ids: set[str],
    update_existing: bool,
    reviewed: bool,
) -> tuple[list[dict[str, object]], int]:
    selected: list[dict[str, object]] = []
    skipped_existing = 0

    for item in source:
        source_category = str(item.get("category") or "").strip().lower()
        if categories and source_category not in categories:
            continue

        row = transform(item, reviewed=reviewed)
        if row is None or not row.get("image_path"):
            continue

        exercise_id = str(row["id"])
        if exercise_id in existing_ids and not update_existing:
            skipped_existing += 1
            continue

        selected.append(row)
        if limit > 0 and len(selected) >= limit:
            break

    return selected, skipped_existing


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage free-exercise-db exercises for LeanIt's Supabase catalogue."
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum exercises to prepare (default: 300, use 0 for all)",
    )
    parser.add_argument(
        "--categories",
        default="",
        help="Optional comma-separated source categories, e.g. strength,stretching",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write rows to Supabase. Without this flag the tool is a dry run.",
    )
    parser.add_argument(
        "--update-existing",
        action="store_true",
        help="Allow source data to update existing LeanIt exercise ids.",
    )
    parser.add_argument(
        "--reviewed",
        action="store_true",
        help=(
            "Mark generic source images approved for display. Use only after "
            "manual technique/suitability review."
        ),
    )
    args = parser.parse_args()

    categories = {
        value.strip().lower()
        for value in args.categories.split(",")
        if value.strip()
    }

    print(f"Downloading source dataset from {SOURCE_REPO} ...")
    source = fetch_source()
    print(f"Source records: {len(source)}")

    base_url: str | None = None
    service_key: str | None = None
    existing_ids: set[str] = set()

    if args.apply:
        base_url = env_required("SUPABASE_URL")
        service_key = env_required("SUPABASE_SERVICE_ROLE_KEY")
        existing_ids = fetch_existing_ids(base_url, service_key)
        print(f"Existing LeanIt exercise ids: {len(existing_ids)}")

    rows, skipped_existing = select_rows(
        source,
        limit=max(args.limit, 0),
        categories=categories,
        existing_ids=existing_ids,
        update_existing=args.update_existing,
        reviewed=args.reviewed,
    )

    category_counts = Counter(str(row.get("category") or "unknown") for row in rows)
    print(f"Prepared rows: {len(rows)}")
    if skipped_existing:
        print(f"Skipped existing rows: {skipped_existing}")
    if category_counts:
        print("Categories:")
        for category, count in sorted(category_counts.items()):
            print(f"  {category}: {count}")

    print("\nSample:")
    for row in rows[:5]:
        print(
            f"  {row['id']}: {row['name']} | {row['difficulty']} | "
            f"{', '.join(row['equipment'])}"
        )
        print(f"    image: {row['image_path']}")

    if not args.apply:
        print("\nDRY RUN ONLY — no Supabase rows were changed.")
        print("To import, set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY locally, then add --apply.")
        return 0

    if not rows:
        print("Nothing to import.")
        return 0

    assert base_url is not None and service_key is not None
    for start in range(0, len(rows), BATCH_SIZE):
        batch = rows[start : start + BATCH_SIZE]
        upsert_batch(base_url, service_key, batch)
        print(f"Imported {min(start + len(batch), len(rows))}/{len(rows)}")

    print("\nImport complete.")
    if args.reviewed:
        print("Generic images were marked approved because --reviewed was supplied.")
    else:
        print("Images remain pending review and LeanIt will keep the safe placeholder until approved.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
