# AuthKit integration — 31 October 2026

AuthKit and AuthKitUI 0.2.3 are linked to the app target. AppAuthGate owns auth
observation at the app root; each bundle has a distinct Keychain session key and
callback scheme. The client-public Supabase URL and publishable key are in Info.plist.
No test account email/password or service-role key is included.

Email/password login and signup are enabled. Account provides local-only sign-out.
Password recovery routes before normal authenticated content. AuthGate rejects
callbacks whose scheme, host or path differs from this app's configured endpoint.

Google and GitHub are enabled in Supabase (verified via the public auth settings API).
AUTH_PROVIDERS is google,github; Apple remains disabled pending developer setup.
The following exact callback URLs are allowlisted in Supabase:

- mytv-auth://auth/callback
- showbook-auth://auth/callback
- motivationdaily-auth://auth/callback

Provider configuration requires a signed-in Supabase dashboard plus OAuth credentials
from Google Cloud, GitHub and Apple Developer. A publishable key cannot change it.

ShowBook binds its existing bookmark email namespace only after cloud authentication;
legacy local credentials are not uploaded or automatically converted into cloud accounts.
MyTV/Motivation Daily favourites remain local device data; account-specific cloud sync
is outside this integration. Production authentication cannot be bypassed. Motivation
Daily's existing Debug-only -UITestMode feature journeys run with offline fixtures.

Validation: all three Debug simulator builds passed using isolated source copies
(byte-identical production sources), exact dependency pins verified. Live AuthKit
sign-in/session/refresh/local-sign-out tests passed. Motivation Daily's Back-button
UI journey passed. ShowBook account-scope/logout unit tests passed.

The apps are installed on iPhone 11 / iOS 27.0 for manual testing. Host integration changes are tracked on the milestone completion branch.
The app dependency record pins AuthKit 0.2.5.

Google/GitHub browser sign-in and email recovery still require end-to-end simulator validation.

Account now offers Reset password with the account email prefilled, plus Sign out.
Forgot password requests a recovery link while signed out. The email link opens the
new-password/confirmation form on the requesting device. Google/GitHub are enabled.

## Developer-first launch and auth rollout — 1 November 2026

ShowBook Debug opens Developer settings before AuthKit/session restoration.
Authentication · AuthKit defaults off (developer.authentication). Open ShowBook
applies the selected flag. Shake to reopen settings and Apply and close to remount
the app with the changed configuration. Turning it off preserves the cloud session.
Release ignores developer preferences and reads only bundled AUTHKIT_ENABLED,
currently false. Production rollout must deliberately enable that setting.

With AuthKit off, ShowBook retains its local-account flow. Cloud identity is cleared
from the view model before legacy screens mount; stored Supabase tokens are retained.

Validation: targeted AuthenticationFlagTests passed; signed Debug and Release
simulator builds passed. Manually checked developer-first launch, AuthKit-on
sign-in route and AuthKit-off existing content route on iPhone 11 / iOS 27.0.
Logs: /tmp/showbook-developer-flag-test.log and /tmp/showbook-developer-flag-release.log.

## UUID Bookmark Migration and Safe Local Account Linking — 3 November 2026

ShowBook transitions bookmark ownership from mutable email strings to stable user UUIDs
introduced in the ShowBookV5 Core Data model:

- **Entity Updates**: `userUUID: UUID?` is added to both `BookEntity` and `UserEntity`.
  Lightweight migration preserves all existing records (`BookEntity` and `UserEntity`) from
  previous schema versions (`ShowBook`, `ShowBookV2`, `ShowBookV3`, `ShowBookV4`).
- **Explicit Local-Account Linking**: When a user signs in via cloud authentication, any matching
  local account record (`UserEntity` matching the authenticated email) is explicitly linked to the
  cloud UUID. Legacy `passwordHash` and local credentials are preserved intact, enabling seamless
  fallback if the developer authentication flag is switched back to local mode.
- **Transactional Migration & Rollback**: Bookmark migration (`PersistenceController.migrateBookmarks`)
  assigns the user's UUID to matching email bookmarks in an isolated transaction. In-flight errors
  automatically roll back mutations. Explicit rollback (`PersistenceController.rollbackBookmarkMigration`)
  is supported to unbind UUIDs while preserving all bookmark contents and email attributes.
- **User Scoping**: Queries and bookmark mutations scope by `userUUID` when present, with fallback to
  `email` for legacy records (`userUUID == currentUUID OR (userUUID == nil AND email == currentUserEmail)`).
  This ensures strict account isolation across switching accounts and preserves access across email changes.
- **Recoverable Store-Load Failures**: Persistent store loading captures errors in `PersistenceController.storeLoadError`
  and presents a recoverable `StoreLoadErrorRecoveryView` in `ShowBookApp`. The app avoids calling `fatalError`
  or automatically deleting the underlying SQLite database file.

