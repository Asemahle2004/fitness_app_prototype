# LeanIt free exercise database import

LeanIt can bootstrap its exercise catalogue from the public `yuhonas/free-exercise-db` repository without paying for an exercise-image API.

## Source

- Repository: `yuhonas/free-exercise-db`
- Published size: 800+ exercises
- Data: JSON
- Media: exercise JPG images
- Repository licence: Unlicense / public-domain dedication

The importer records the source and licence in every imported exercise row.

## Why LeanIt uses this as a bootstrap source

The current LeanIt architecture already keeps exercise data in Supabase and separates exercise metadata from production media. This means we do not need to commit hundreds of images into the Flutter `assets/` folder.

The source dataset can provide:

- exercise names
- difficulty
- equipment
- primary muscles
- secondary muscles
- category
- instructions
- generic exercise images

LeanIt keeps its own programme engine, safety rules, substitutions, workout prescriptions, progress tracking and future coaching logic on top of this catalogue.

## Important media rule

Imported generic images are not automatically treated as production-approved demonstrations.

The importer writes one of these markers into `media_review_notes`:

- `[pending-generic]` — imported but still hidden from production exercise media
- `[approved-generic]` — manually reviewed and allowed as a generic fallback image

Sex-specific reviewed LeanIt media remains preferred. If a user has selected a male or female demonstration preference, LeanIt first tries the matching reviewed image, then an approved generic image, then the opposite reviewed sex-specific image as the final fallback.

## Dry run

From the project root:

```powershell
python .\tools\import_free_exercise_db.py
```

The default dry run prepares up to 300 exercises and makes no database changes.

To preview all available source exercises:

```powershell
python .\tools\import_free_exercise_db.py --limit 0
```

To restrict the source categories:

```powershell
python .\tools\import_free_exercise_db.py --categories strength,stretching
```

## Import into LeanIt Supabase

Set the privileged values only in your local terminal session. Never commit the service-role key.

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="YOUR_LOCAL_SERVICE_ROLE_KEY"
```

Then import:

```powershell
python .\tools\import_free_exercise_db.py --apply
```

By default existing LeanIt exercise IDs are left untouched.

To deliberately update matching existing exercise rows:

```powershell
python .\tools\import_free_exercise_db.py --apply --update-existing
```

## Approving generic images

Do not use this option blindly across the dataset. Review exercise technique and suitability first.

After review, approved imports can be written with:

```powershell
python .\tools\import_free_exercise_db.py --apply --reviewed
```

That writes the `[approved-generic]` marker that the Flutter client understands.

## Production recommendation

The GitHub-hosted source image URLs are useful for a zero-cost bootstrap and review workflow. For long-term production, approved images can later be copied into LeanIt's `exercise-media` Supabase Storage bucket using the existing media upload tools. This avoids depending permanently on GitHub raw hosting and lets LeanIt replace generic demonstrations with its own male/female reviewed media over time.

## What this does not replace

The imported exercise catalogue is not the LeanIt programme engine. It is a source library. LeanIt should continue deciding:

- which exercises suit the user's goal
- which exercises fit available equipment
- sets, reps and rest
- substitutions
- session length
- training frequency
- progression
- limitations and safety adaptations
- workout history and future programme adaptation
