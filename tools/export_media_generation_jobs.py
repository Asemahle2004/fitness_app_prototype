#!/usr/bin/env python3
"""Export every missing LeanEat exercise photo as a generation job.

The script reads the public Supabase view `exercise_media_production_queue` and
writes one JSON object per missing male/female reviewed image.

Output defaults to:
  media_generation_jobs.jsonl

This does NOT create or approve images. It creates the production queue and
prompt specification so an image-production process can create consistent,
original LeanEat assets without copying third-party fitness graphics.
"""

from __future__ import annotations

import json
from pathlib import Path
import urllib.parse
import urllib.request

PROJECT_URL = "https://ukrapyyqyrwhbyjhkxeh.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Larl3RdDTmOlyhwkhWaWRw_UdJA7mTr"
OUTPUT = Path("media_generation_jobs.jsonl")


def _rows() -> list[dict]:
    params = urllib.parse.urlencode({
        "select": "exercise_id,exercise_name,sex,category,difficulty,movement_pattern,primary_muscles,equipment,instructions,target_storage_path",
        "order": "exercise_name.asc,sex.asc",
    })
    request = urllib.request.Request(
        f"{PROJECT_URL}/rest/v1/exercise_media_production_queue?{params}",
        headers={
            "apikey": PUBLISHABLE_KEY,
            "Authorization": f"Bearer {PUBLISHABLE_KEY}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def _prompt(row: dict) -> str:
    sex = row["sex"]
    model = "adult Black South African woman" if sex == "female" else "adult Black South African man"
    equipment = ", ".join(row.get("equipment") or []) or "appropriate exercise equipment"
    muscles = ", ".join(row.get("primary_muscles") or [])
    instructions = row.get("instructions") or []
    technique = " ".join(f"Step {i + 1}: {step}" for i, step in enumerate(instructions))

    return (
        f"Create an original photorealistic LeanEat exercise demonstration for {row['exercise_name']}. "
        f"Show the same {model} in a clean professional fitness studio, wearing simple unbranded training clothing. "
        "Use one wide image containing two clearly separated panels: left is the START position and right is the FINISH position. "
        "Keep camera angle, person, clothing, lighting, body proportions and equipment consistent between panels. "
        f"Equipment: {equipment}. Primary muscles: {muscles}. "
        f"Technique reference: {technique} "
        "Demonstrate controlled, anatomically plausible form. Keep the full body and all relevant equipment visible. "
        "Plain light background, high clarity, realistic anatomy, instructional fitness photography. "
        "Do not add text, labels, logos, brand marks, watermarks, arrows, muscle overlays or decorative graphics. "
        "Do not imitate or reproduce any existing fitness website image. The image must be an original LeanEat production asset."
    )


def main() -> int:
    rows = _rows()
    with OUTPUT.open("w", encoding="utf-8") as handle:
        for row in rows:
            job = {
                "exercise_id": row["exercise_id"],
                "exercise_name": row["exercise_name"],
                "sex": row["sex"],
                "target_storage_path": row["target_storage_path"],
                "category": row.get("category"),
                "difficulty": row.get("difficulty"),
                "movement_pattern": row.get("movement_pattern"),
                "prompt": _prompt(row),
                "status": "needs_generation",
                "technique_review_required": True,
                "rights_review_required": True,
            }
            handle.write(json.dumps(job, ensure_ascii=False) + "\n")

    print(f"Missing reviewed image jobs: {len(rows)}")
    print(f"Saved: {OUTPUT.resolve()}")
    if rows:
        print("First jobs:")
        for row in rows[:10]:
            print(f"- {row['exercise_id']} / {row['sex']} -> {row['target_storage_path']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
