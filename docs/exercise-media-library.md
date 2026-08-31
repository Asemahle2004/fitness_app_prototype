# LeanEat exercise media library

LeanEat uses the Supabase Storage bucket `exercise-media` for production exercise demonstrations.

## Required production coverage

Every active exercise should ultimately have reviewed, original or properly licensed demonstration media. For gender-matched presentation the preferred fields are:

- `male_image_path`
- `female_image_path`
- `male_video_path` (optional later)
- `female_video_path` (optional later)

The Flutter client selects the saved user's exercise-model preference first and then their profile sex. It does not hard-code individual exercise names.

Photo-first media is now used in the exercise library, workout cards, exercise details and the live workout screen. Stick-figure movement diagrams are no longer treated as the production fallback in these main user flows.

The persistent member navigation exposes the full exercise library directly from the `Exercises` tab, so users can browse the complete catalogue without repeating onboarding.

## Storage naming convention

Use one folder per exercise id, for example:

```
exercise-media/
  dumbbell_bench_press/
    male.webp
    female.webp
  plank/
    male.webp
    female.webp
  wrist_circles/
    male.webp
    female.webp
```

Database paths should be relative to the bucket, such as `plank/male.webp`.

## Batch production workflow

The repository now contains two media-production tools:

- `tools/check_exercise_media_coverage.py` — read-only coverage report for all active exercises.
- `tools/upload_exercise_media.py` — batch uploader that sends reviewed images to Supabase Storage and updates the matching exercise rows.

Prepare source images locally like this:

```
media_source/
  dumbbell_bench_press/
    male.webp
    female.webp
  leg_press/
    male.webp
    female.webp
```

Then set the Supabase service-role key only in your local terminal environment and run the uploader. Never put the service-role key in source code or commit it to GitHub.

The uploader validates exercise ids, uploads to the `exercise-media` bucket, and writes `male_image_path` / `female_image_path` automatically. This means new media can be added in batches without changing Flutter code.

## Media standard

Production demonstrations should:

1. Show the actual exercise, not a generic pose.
2. Prefer a clear START and FINISH view in one image, or a reviewed short video later.
3. Keep camera angle, crop and background consistent across the library.
4. Use the requested male/female model variant where available.
5. Avoid misleading anatomy, impossible joint positions or exaggerated range of motion.
6. Be reviewed for technique before being marked production-ready.
7. Be original to LeanEat or licensed for redistribution in a commercial app.

## Publishing rule

Do not ship third-party watermarked fitness-guide images without a licence. Production media should be created for LeanEat, commissioned, or licensed for app redistribution and should be reviewed for exercise technique before publication.

Until an exercise has approved photo media, the app shows an explicit branded photo-pending state rather than presenting a generic stick-figure diagram as final exercise media.
