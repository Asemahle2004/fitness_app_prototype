# LeanIt Privacy Notes

LeanIt stores account, training-profile, workout, readiness and progress information needed to provide adaptive fitness features. User-owned training data is access-controlled through the application's Supabase backend.

## Active run location

LeanIt requests precise device location only for GPS run tracking that the user explicitly starts. On Android, an active run may continue through a foreground location service when the app is in the background or the display is off. Android shows a persistent LeanIt run-tracking notification while that foreground service is active. Pausing, finishing or leaving the active run stops the location stream.

LeanIt currently calculates and saves run distance, duration and related training metadata locally. The live latitude/longitude points used to calculate distance are not intentionally written to LeanIt run history or uploaded as a route in this version.

## Exercise demonstration provider

Exercise data and videos provided by MuscleWiki.com

When MuscleWiki demonstrations are enabled, LeanIt requests short-lived demonstration media for the exercise being viewed. LeanIt does not permanently copy or re-host MuscleWiki video, thumbnail or bodymap media. Short-lived provider media URLs are treated as credentials and are not intentionally written to LeanIt databases, analytics, crash reports or shared caches.

## Health and training guidance

LeanIt provides fitness guidance and exercise adaptation. It does not diagnose injuries or replace medical assessment. Safety responses supplied during onboarding may be used to block or modify app-directed exercise suggestions.
