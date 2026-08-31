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

## Publishing rule

Do not ship third-party watermarked fitness-guide images without a licence. Production media should be created for LeanEat, commissioned, or licensed for app redistribution and should be reviewed for exercise technique before publication.

Until an exercise has approved photo media, the app shows an explicit branded photo-pending state rather than presenting a generic stick-figure diagram as final exercise media.
