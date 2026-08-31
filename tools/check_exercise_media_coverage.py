#!/usr/bin/env python3
"""Report LeanEat exercise-photo coverage from Supabase.

This read-only script uses the publishable client key already used by the app.
It prints missing male/female image coverage for active exercises.
"""

from __future__ import annotations

import json
import urllib.parse
import urllib.request

PROJECT_URL = "https://ukrapyyqyrwhbyjhkxeh.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Larl3RdDTmOlyhwkhWaWRw_UdJA7mTr"


def main() -> int:
    params = urllib.parse.urlencode({
        "select": "id,name,male_image_path,female_image_path,image_path",
        "is_active": "eq.true",
        "order": "name.asc",
    })
    request = urllib.request.Request(
        f"{PROJECT_URL}/rest/v1/exercises?{params}",
        headers={
            "apikey": PUBLISHABLE_KEY,
            "Authorization": f"Bearer {PUBLISHABLE_KEY}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        rows = json.loads(response.read().decode("utf-8"))

    male = sum(bool(row.get("male_image_path")) for row in rows)
    female = sum(bool(row.get("female_image_path")) for row in rows)
    generic = sum(bool(row.get("image_path")) for row in rows)
    complete = sum(
        bool(row.get("male_image_path")) and bool(row.get("female_image_path"))
        for row in rows
    )

    print(f"Active exercises: {len(rows)}")
    print(f"Male images: {male}/{len(rows)}")
    print(f"Female images: {female}/{len(rows)}")
    print(f"Both genders complete: {complete}/{len(rows)}")
    print(f"Generic legacy images: {generic}/{len(rows)}")
    print("\nMissing production media:")
    for row in rows:
        missing = []
        if not row.get("male_image_path"):
            missing.append("male")
        if not row.get("female_image_path"):
            missing.append("female")
        if missing:
            print(f"- {row['id']}: {row['name']} -> {', '.join(missing)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
