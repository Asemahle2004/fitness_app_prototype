#!/usr/bin/env python3
"""Generate LeanEat draft exercise demonstration images with OpenAI GPT-Image-2.

The generated files are DRAFTS. They must be reviewed for technique and media
quality before tools/exercise_media_import.py is run with --reviewed.

Required local environment variables:
  OPENAI_API_KEY
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY

No secret is written to the repository or printed by this script.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

OPENAI_IMAGE_ENDPOINT = "https://api.openai.com/v1/images/generations"
MODEL = "gpt-image-2"
DEFAULT_SOURCE = Path("exercise_media_source")


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(
            f"Missing {name}. Set it only in your local terminal environment."
        )
    return value.rstrip("/") if name == "SUPABASE_URL" else value


def http_json(
    url: str,
    *,
    method: str,
    headers: dict[str, str],
    payload: dict | None = None,
    timeout: int = 180,
) -> dict | list:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def fetch_exercises(base_url: str, service_key: str) -> list[dict]:
    query = urllib.parse.urlencode(
        {
            "select": "id,name,category,difficulty,movement_pattern,equipment,instructions,common_mistakes,male_image_path,female_image_path,male_image_reviewed,female_image_reviewed",
            "is_active": "eq.true",
            "order": "name.asc",
        }
    )
    result = http_json(
        f"{base_url}/rest/v1/exercises?{query}",
        method="GET",
        headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
        },
    )
    return list(result)


def image_prompt(exercise: dict, gender: str) -> str:
    name = exercise["name"]
    category = exercise.get("category") or "fitness"
    pattern = exercise.get("movement_pattern") or "exercise"
    difficulty = exercise.get("difficulty") or "general"
    equipment = ", ".join(exercise.get("equipment") or ["appropriate equipment"])
    instructions = exercise.get("instructions") or []
    mistakes = exercise.get("common_mistakes") or []

    model_wording = (
        "a fictional adult Black South African woman fitness model"
        if gender == "female"
        else "a fictional adult Black South African man fitness model"
    )

    instruction_text = " ".join(f"{i + 1}. {line}" for i, line in enumerate(instructions[:6]))
    mistake_text = "; ".join(mistakes[:5])

    return f"""
Create a premium LeanEat exercise demonstration image for: {name}.

SUBJECT:
Use {model_wording}, healthy athletic build, professional fitness clothing in deep green, mint and neutral LeanEat brand colours. The person must be fictional and not resemble a public figure or real identifiable person.

FORMAT:
One landscape 1536x1024 instructional fitness image on a clean bright studio background. Show the SAME person in two large side-by-side positions: START on the left and FINISH on the right. The exercise and equipment must be large, clear and phone-readable. Keep the whole body and all equipment visible. No watermark, no company logo, no website URL, no tiny instruction text, no anatomy labels, no extra people, no collage beyond the two start/finish positions.

EXERCISE DATA:
Exercise: {name}
Category: {category}
Movement pattern: {pattern}
Difficulty: {difficulty}
Equipment: {equipment}
Technique instructions: {instruction_text}
Common mistakes to avoid visually: {mistake_text}

TECHNIQUE PRIORITY:
The body position, joint alignment, equipment setup and start/finish relationship must follow the supplied technique instructions. Do not exaggerate range of motion. Use a safe, controlled demonstration appropriate for a general fitness education app. If the exercise is a continuous activity such as running, walking, cycling or rowing, show two representative phases of correct technique rather than inventing a strength-training start/finish pose.

VISUAL STYLE:
Photorealistic professional fitness photography, clean studio lighting, consistent camera angle between START and FINISH, realistic equipment, simple neutral background, premium mobile fitness app quality. The image should look like an original LeanEat training demonstration rather than a stock-photo collage.
""".strip()


def generate_image(openai_key: str, prompt: str, *, quality: str) -> bytes:
    response = http_json(
        OPENAI_IMAGE_ENDPOINT,
        method="POST",
        headers={
            "Authorization": f"Bearer {openai_key}",
            "Content-Type": "application/json",
        },
        payload={
            "model": MODEL,
            "prompt": prompt,
            "size": "1536x1024",
            "quality": quality,
            "output_format": "png",
            "n": 1,
        },
        timeout=300,
    )
    data = response.get("data") if isinstance(response, dict) else None
    if not data:
        raise RuntimeError(f"Image API returned no image data: {response}")
    encoded = data[0].get("b64_json")
    if not encoded:
        raise RuntimeError("Image API response did not include b64_json.")
    return base64.b64decode(encoded)


def already_has_source(root: Path, exercise_id: str, gender: str) -> bool:
    folder = root / exercise_id
    return any((folder / f"{gender}{ext}").exists() for ext in (".png", ".webp", ".jpg", ".jpeg"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate draft male/female LeanEat exercise demonstrations."
    )
    parser.add_argument("--exercise", help="Generate one exercise id only")
    parser.add_argument(
        "--gender",
        choices=("male", "female", "both"),
        default="both",
    )
    parser.add_argument(
        "--quality",
        choices=("low", "medium", "high"),
        default="medium",
        help="Image generation quality. Medium is the default production-draft balance.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=1,
        help="Maximum exercises to generate in this run (default 1).",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate missing drafts for every active exercise. Requires --confirm-bulk.",
    )
    parser.add_argument(
        "--confirm-bulk",
        action="store_true",
        help="Required with --all because large runs consume paid image-generation API usage.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Regenerate source files that already exist locally.",
    )
    parser.add_argument(
        "--source",
        default=str(DEFAULT_SOURCE),
    )
    args = parser.parse_args()

    if args.all and not args.confirm_bulk:
        raise SystemExit("Refusing bulk generation without --confirm-bulk.")

    openai_key = required_env("OPENAI_API_KEY")
    base_url = required_env("SUPABASE_URL")
    service_key = required_env("SUPABASE_SERVICE_ROLE_KEY")
    root = Path(args.source)
    root.mkdir(parents=True, exist_ok=True)

    exercises = fetch_exercises(base_url, service_key)
    if args.exercise:
        exercises = [row for row in exercises if row["id"] == args.exercise]
        if not exercises:
            raise SystemExit(f"Unknown active exercise id: {args.exercise}")
    elif not args.all:
        exercises = exercises[: max(1, args.limit)]

    genders = ("male", "female") if args.gender == "both" else (args.gender,)
    generated = 0
    skipped = 0

    print(f"Using {MODEL}. Drafts will NOT be marked reviewed automatically.")
    for exercise_index, exercise in enumerate(exercises, start=1):
        exercise_id = exercise["id"]
        folder = root / exercise_id
        folder.mkdir(parents=True, exist_ok=True)

        for gender in genders:
            if not args.overwrite and already_has_source(root, exercise_id, gender):
                print(f"SKIP {exercise_id}/{gender}: local source already exists")
                skipped += 1
                continue

            print(
                f"GENERATE {exercise_index}/{len(exercises)} {exercise_id}/{gender} ...",
                flush=True,
            )
            prompt = image_prompt(exercise, gender)
            image_bytes = generate_image(openai_key, prompt, quality=args.quality)
            destination = folder / f"{gender}.png"
            destination.write_bytes(image_bytes)
            generated += 1
            print(f"SAVED {destination} ({len(image_bytes) // 1024} KB)")

            # Keep requests comfortably separated for lower API tiers.
            time.sleep(0.4)

    print(f"\nGenerated: {generated}; skipped: {skipped}")
    print("Next: visually review technique and rights, then run exercise_media_import.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
