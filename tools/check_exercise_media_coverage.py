#!/usr/bin/env python3
"""Report reviewed LeanEat exercise-photo coverage from Supabase.

This read-only script uses the publishable client key already used by the app.
It reports production-ready male/female media, not merely files that happen to
exist in Storage.
"""

from __future__ import annotations

import json
import urllib.parse
import urllib.request

PROJECT_URL = "https://ukrapyyqyrwhbyjhkxeh.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Larl3RdDTmOlyhwkhWaWRw_UdJA7mTr"


def _get(path: str, params: dict[str, str]) -> list[dict] | dict:
    query = urllib.parse.urlencode(params)
    request = urllib.request.Request(
        f"{PROJECT_URL}/rest/v1/{path}?{query}",
        headers={
            "apikey": PUBLISHABLE_KEY,
            "Authorization": f"Bearer {PUBLISHABLE_KEY}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> int:
    coverage = _get("exercise_media_coverage", {"select": "*"})
    if isinstance(coverage, list):
        coverage = coverage[0] if coverage else {}

    queue = _get(
        "exercise_media_production_queue",
        {
            "select": "exercise_id,exercise_name,sex,target_storage_path",
            "order": "exercise_name.asc,sex.asc",
        },
    )
    if not isinstance(queue, list):
        queue = []

    active = int(coverage.get("active_exercises") or 0)
    male = int(coverage.get("male_reviewed") or 0)
    female = int(coverage.get("female_reviewed") or 0)
    complete = int(coverage.get("fully_publishable_exercises") or 0)

    print(f"Active exercises: {active}")
    print(f"Reviewed male images: {male}/{active}")
    print(f"Reviewed female images: {female}/{active}")
    print(f"Publishable male+female pairs: {complete}/{active}")
    print(f"Missing reviewed image jobs: {len(queue)}")
    print("\nProduction queue:")
    for row in queue:
        print(
            f"- {row['exercise_id']}: {row['exercise_name']} / "
            f"{row['sex']} -> {row['target_storage_path']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
