#!/usr/bin/env python3
"""Generate LeanEat draft exercise images from media_generation_jobs.jsonl.

This runner only needs OPENAI_API_KEY because the job file already contains the
exercise technique prompt and target path exported from Supabase.

Defaults are deliberately conservative:
- generates only 2 jobs per run (normally one exercise: female + male)
- medium quality
- skips files that already exist

Examples:
  python tools/generate_media_from_jobs.py
  python tools/generate_media_from_jobs.py --exercise ankle_mobility_rock
  python tools/generate_media_from_jobs.py --exercise ankle_mobility_rock --sex female
  python tools/generate_media_from_jobs.py --limit 10

Bulk generation requires both --all and --confirm-bulk because image API usage
is paid and 298 current jobs is a large run.

Generated images are DRAFTS. Do not mark them reviewed until exercise technique
and media quality have been checked.
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
import urllib.request

OPENAI_IMAGE_ENDPOINT = "https://api.openai.com/v1/images/generations"
MODEL = "gpt-image-2"
DEFAULT_JOBS = Path("media_generation_jobs.jsonl")
DEFAULT_OUTPUT = Path("exercise_media_source")


def require_key() -> str:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise SystemExit(
            "Missing OPENAI_API_KEY. Set it only in your local terminal environment; "
            "do not paste it into chat or commit it to GitHub."
        )
    return key


def read_jobs(path: Path) -> list[dict]:
    if not path.exists():
        raise SystemExit(
            f"Job file not found: {path}. Run tools/export_media_generation_jobs.py first."
        )
    jobs: list[dict] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            jobs.append(json.loads(line))
        except json.JSONDecodeError as exc:
            raise SystemExit(f"Invalid JSON on line {line_number}: {exc}") from exc
    return jobs


def request_image(api_key: str, prompt: str, quality: str) -> bytes:
    payload = json.dumps(
        {
            "model": MODEL,
            "prompt": prompt,
            "size": "1536x1024",
            "quality": quality,
            "output_format": "png",
            "n": 1,
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        OPENAI_IMAGE_ENDPOINT,
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Image API HTTP {exc.code}: {detail}") from exc

    data = result.get("data") or []
    if not data:
        raise RuntimeError(f"Image API returned no image data: {result}")
    encoded = data[0].get("b64_json")
    if not encoded:
        raise RuntimeError("Image API response did not include b64_json.")
    return base64.b64decode(encoded)


def output_path(root: Path, job: dict) -> Path:
    return root / job["exercise_id"] / f"{job['sex']}.png"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jobs", default=str(DEFAULT_JOBS))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--exercise")
    parser.add_argument("--sex", choices=("male", "female"))
    parser.add_argument("--quality", choices=("low", "medium", "high"), default="medium")
    parser.add_argument("--limit", type=int, default=2)
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--confirm-bulk", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    if args.all and not args.confirm_bulk:
        raise SystemExit("Refusing bulk generation without --confirm-bulk.")

    api_key = require_key()
    jobs = read_jobs(Path(args.jobs))

    if args.exercise:
        jobs = [job for job in jobs if job.get("exercise_id") == args.exercise]
    if args.sex:
        jobs = [job for job in jobs if job.get("sex") == args.sex]
    if not args.all:
        jobs = jobs[: max(1, args.limit)]

    if not jobs:
        raise SystemExit("No matching generation jobs found.")

    output_root = Path(args.output)
    output_root.mkdir(parents=True, exist_ok=True)

    print(f"LeanEat draft media generation using {MODEL}")
    print(f"Jobs selected: {len(jobs)}")
    generated = 0
    skipped = 0

    for index, job in enumerate(jobs, start=1):
        destination = output_path(output_root, job)
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and not args.overwrite:
            print(f"SKIP {job['exercise_id']}/{job['sex']}: {destination} already exists")
            skipped += 1
            continue

        print(
            f"GENERATE {index}/{len(jobs)}: {job['exercise_name']} / {job['sex']}",
            flush=True,
        )
        image = request_image(api_key, job["prompt"], args.quality)
        destination.write_bytes(image)
        generated += 1
        print(f"SAVED {destination} ({len(image) // 1024} KB)")
        time.sleep(0.5)

    print()
    print(f"Generated: {generated}")
    print(f"Skipped: {skipped}")
    print("These are drafts. Review them before uploading/marking reviewed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
