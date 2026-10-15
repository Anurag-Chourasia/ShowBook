# Integration validation

Run `python3 TestSupport/run-networking-tests.py` from the repository root with Xcode 27.1 selected. It copies the actual NetworkClass and DTOs into a disposable package and runs eight offline tests with session-scoped URLProtocol classes. It does not use live APIs or alter app file membership.

Tests cover callback count/off-main completion, headers, search query/pagination (including reserved characters and Unicode), region round-tripping, DTOs, success/non-2xx, malformed/empty JSON, and cancellation/offline error propagation. Search URLs use URLComponents and query items; country requests preserve their transport errors. No cancellation handle is added. Existing app tests still include live image downloads; their results are reported separately.

FoundationKit trims the hex helper exactly as before. LocalizationKit remains linked but unused: the app's literal Text localization has no validated equivalent use in the package; package-owned demo strings would change wording/fallback. No empty formatting calls or unused import is added.

Dashboard regressions cover out-of-order searches, clearing searches, and retrying a failed page without skipping offsets. Signup regressions cover failed/missing IP responses and empty country responses. Some legacy tests still depend on live image downloads.

Run `bash TestSupport/run-app-tests.sh DERIVED_DATA` for the existing ShowBookTests target on a prebooted iPhone 18 Pro simulator. The scheme has a stale ShowBookUITests reference; this command explicitly selects the real unit-test target.


## Versioned Core Data schema

ShowBookV3 is the current model; it adds the optional passwordHash field while preserving V1 and V2 for automatic migration. `CountryEntity.data` and `DatumEntity.region` now have optional Nullify inverses. The original ShowBook model remains byte-for-byte intact so existing SQLite stores can migrate automatically.

The app target suppresses only momc's inverse-relationship warning category because the bundled historical V1 schema intentionally lacks those inverses. `PersistenceRelationshipTests` validates reciprocal inverses on **every current-model relationship**, inverse maintenance/deletion, and automatic SQLite migration preserving countries, shared regions and bookmarks. Other Core Data warning categories remain enabled. Do not remove the old model or weaken these tests to silence warnings.


## Credential storage and migration

New accounts store a versioned PBKDF2-HMAC-SHA256 verifier (600,000 iterations, 16 random salt bytes, 32 derived bytes) in UserEntity.passwordHash. UserEntity.password is retained only to read legacy schemas and is cleared when migration commits. There is no fallback to plaintext if a hash exists but is corrupt or incorrect.

The production persistence controller migrates legacy accounts after opening its store. Registration, login verification, and startup migration run serially on background Core Data contexts. A failed account transaction is rolled back and retried on a later launch/login; other accounts can still migrate. Published UI state and completion callbacks return to the main queue. Synchronous saveUser is retained for existing test fixtures and also stores only hashes; app signup uses registerUser.

CredentialStorageTests covers an independently computed PBKDF2 vector (Unicode and embedded NUL), random salts, wrong passwords, malformed records, duplicate signup, legacy login, idempotence, hashing/save failures, a corrupt account beside a valid one, read-only SQLite failures, and V1/V2 SQLite upgrades preserving existing accounts. Existing schema tests also validate V1 bookmark/country migration into the current model.

Migration clears logical plaintext values in the active store. It cannot revoke passwords already exposed or rewrite prior backups, and does not claim forensic erasure of historical SQLite/WAL pages. This remains a local-account app, not server-backed authentication.

## Shared catalog design

CatalogTile and CatalogLayoutMenu come from UIComponentsKit 1.2.0; their metrics, colors and typography come from DesignTokensKit 1.2.0. Run `python3 Scripts/check_design_tokens.py` before submitting UI changes. CI rejects raw visual literals and implicit padding in application Swift sources. Numeric business data and conversion algorithms remain local. The scan is a source-pattern guard, not a Swift type checker.
