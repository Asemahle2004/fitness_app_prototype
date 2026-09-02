# LeanIt exercise media provider

LeanIt uses one canonical exercise catalogue and keeps provider-specific identifiers separate from LeanIt exercise IDs.

## Production provider

MuscleWiki is the intended standardized demonstration provider for the master Exercise Library because its API provides male/female and multiple-angle exercise demonstrations.

Required legal disclosure when provider media is enabled:

> Exercise data and videos provided by MuscleWiki.com

## Security and licensing rules

- `MUSCLEWIKI_API_KEY` is server-side only and must never be included in the Flutter application.
- LeanIt stores provider exercise IDs and mapping status only.
- LeanIt must never download or permanently store MuscleWiki videos, preview images, thumbnails or bodymaps in Supabase Storage, local app storage, GitHub or a CDN.
- Short-lived tokenized media URLs are credentials and must not be logged, persisted, included in analytics or crash reports, or shared.
- Videos are streamed from MuscleWiki. Existing legacy LeanIt visuals remain fallback media until provider coverage has been verified.
- Do not remove, crop or obscure branding embedded in provider videos.

## Mapping lifecycle

1. LeanIt asks the `musclewiki-media` Supabase Edge Function for a canonical exercise name and visual sex.
2. The function looks up `exercise_provider_mappings`.
3. If unmapped, it searches MuscleWiki and accepts only an exact normalized exercise-name match automatically.
4. Non-exact matches remain `unmatched` for manual review rather than risking the wrong demonstration.
5. The server fetches the requested gender variant and mints a short-lived media token.
6. Flutter displays the provider preview in-memory; if unavailable, LeanIt uses the old reviewed/reference visual as migration fallback.
7. Old mixed media can be retired only after coverage auditing confirms that the master catalogue is mapped and reviewed.

## Required external configuration

Add a TESTING-or-higher MuscleWiki API key to Supabase Edge Function secrets as `MUSCLEWIKI_API_KEY`. BASIC keys are playground-only and cannot mint production media tokens.
