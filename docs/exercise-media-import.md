# LeanEat production exercise media pipeline

The Flutter app is now photo-first and gender-aware. The remaining content job is to provide approved original/licensed male and female demonstrations for every active exercise.

## Current rule

A Storage path by itself does **not** make an image publishable. LeanEat only shows gender-specific Supabase media when the corresponding review field is true:

- `male_image_path` + `male_image_reviewed = true`
- `female_image_path` + `female_image_reviewed = true`

This prevents an accidental draft, watermarked image, or unreviewed technique image from becoming the final exercise demonstration.

## Source folder

Create this folder locally at the project root. It is intentionally ignored by Git so large/source media does not get committed accidentally.

```text
exercise_media_source/
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

Accepted formats: `.webp`, `.png`, `.jpg`, `.jpeg`.

Recommended production format: WebP, landscape, enough resolution for a large live-workout card, with START and FINISH positions visible in one branded LeanEat image when the movement benefits from two positions.

## Media standard

Each image should be:

1. Original to LeanEat, commissioned for LeanEat, or licensed for redistribution inside the app.
2. Free from third-party watermarks.
3. Reviewed for exercise technique before being marked publishable.
4. Consistent in background, camera angle, lighting and LeanEat branding where practical.
5. Gender-matched where the app has male/female variants.
6. Clear enough to understand on a phone without reading tiny text inside the image.

## Secure uploader

The repository contains `tools/exercise_media_import.py`.

It requires these variables in the **local terminal only**:

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="YOUR_LOCAL_SERVICE_ROLE_KEY"
```

Never paste the service-role key into Flutter source code, GitHub, screenshots, issues or chat.

### Validate first

```powershell
python tools\exercise_media_import.py
```

No upload happens without `--apply`.

### Upload drafts

```powershell
python tools\exercise_media_import.py --apply
```

Drafts are uploaded but remain hidden as final production media until reviewed.

### Upload already reviewed media

Only after technique and rights review:

```powershell
python tools\exercise_media_import.py --apply --reviewed
```

### Upload one exercise

```powershell
python tools\exercise_media_import.py --exercise dumbbell_bench_press --apply --reviewed
```

The script uploads to the public `exercise-media` bucket and updates the matching `exercises` row. It never prints the service-role key.

## Database coverage tracking

Supabase now exposes `exercise_media_coverage`, which reports:

- active exercises
- male images
- female images
- reviewed male images
- reviewed female images
- fully publishable male/female pairs

The target for release is that `fully_publishable_exercises` equals `active_exercises`.
