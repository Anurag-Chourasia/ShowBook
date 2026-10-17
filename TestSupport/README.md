# Integration validation

Run `python3 TestSupport/run-networking-tests.py` from the repository root with Xcode 27.1 selected. It copies the actual NetworkClass and DTOs into a disposable package and runs eight offline tests with session-scoped URLProtocol classes. It does not use live APIs or alter app file membership.

Tests cover callback count/off-main completion, headers, search query/pagination (including reserved characters and Unicode), region round-tripping, DTOs, success/non-2xx, malformed/empty JSON, and cancellation/offline error propagation. Search URLs use URLComponents and query items; country requests preserve their transport errors. No cancellation handle is added. Existing app tests still include live image downloads; their results are reported separately.

FoundationKit trims the hex helper exactly as before. LocalizationKit remains linked but unused: the app's literal Text localization has no validated equivalent use in the package; package-owned demo strings would change wording/fallback. No empty formatting calls or unused import is added.

Dashboard regressions cover out-of-order searches, clearing searches, and retrying a failed page without skipping offsets. Signup regressions cover failed/missing IP responses and empty country responses. Some legacy tests still depend on live image downloads.

Run `bash TestSupport/run-app-tests.sh DERIVED_DATA` for the existing ShowBookTests target on a prebooted iPhone 18 Pro simulator. The scheme has a stale ShowBookUITests reference; this command explicitly selects the real unit-test target.


## Versioned Core Data schema

ShowBookV4 is the current model; it adds optional BookEntity.workKey while preserving V1, V2 and V3 for automatic migration. V3 introduced the optional passwordHash field. `CountryEntity.data` and `DatumEntity.region` now have optional Nullify inverses. The original ShowBook model remains byte-for-byte intact so existing SQLite stores can migrate automatically.

The app target suppresses only momc's inverse-relationship warning category because the bundled historical V1 schema intentionally lacks those inverses. `PersistenceRelationshipTests` validates reciprocal inverses on **every current-model relationship**, inverse maintenance/deletion, and automatic SQLite migration preserving countries, shared regions and bookmarks. Other Core Data warning categories remain enabled. Do not remove the old model or weaken these tests to silence warnings.


## Credential storage and migration

New accounts store a versioned PBKDF2-HMAC-SHA256 verifier (600,000 iterations, 16 random salt bytes, 32 derived bytes) in UserEntity.passwordHash. UserEntity.password is retained only to read legacy schemas and is cleared when migration commits. There is no fallback to plaintext if a hash exists but is corrupt or incorrect.

The production persistence controller migrates legacy accounts after opening its store. Registration, login verification, and startup migration run serially on background Core Data contexts. A failed account transaction is rolled back and retried on a later launch/login; other accounts can still migrate. Published UI state and completion callbacks return to the main queue. Synchronous saveUser is retained for existing test fixtures and also stores only hashes; app signup uses registerUser.

CredentialStorageTests covers an independently computed PBKDF2 vector (Unicode and embedded NUL), random salts, wrong passwords, malformed records, duplicate signup, legacy login, idempotence, hashing/save failures, a corrupt account beside a valid one, read-only SQLite failures, and V1/V2/V3 SQLite upgrades preserving existing accounts. Existing schema tests also validate V1/V2/V3 bookmark/country migration into the current model.

Migration clears logical plaintext values in the active store. It cannot revoke passwords already exposed or rewrite prior backups, and does not claim forensic erasure of historical SQLite/WAL pages. This remains a local-account app, not server-backed authentication.

## Shared catalog design

CatalogTile and CatalogLayoutMenu come from UIComponentsKit 1.2.0; their metrics, colors and typography come from DesignTokensKit 1.2.0. Run `python3 Scripts/check_design_tokens.py` before submitting UI changes. CI rejects raw visual literals and implicit padding in application Swift sources. Numeric business data and conversion algorithms remain local. The scan is a source-pattern guard, not a Swift type checker.

## Book and edition details

Search results retain their Open Library work key. Tapping artwork or text in either catalog layout opens work details; the bookmark action remains separate. Details include description, subjects and first publication date when available, followed by paginated editions and individual edition metadata. Missing fields and covers have fallbacks. Older bookmarks without keys remain usable but require a fresh search for online details; titles are never guessed into identifiers.

BookDetailsService owns the Open Library endpoints and uses CommonNetworking for transport. It validates work/edition identifiers, identifies the app via User-Agent, spaces detail requests by 0.4 seconds, caches successful decoded responses for five minutes (up to 100 entries), and supports cancellation. This pacing applies to details, not the existing search service. HTTP failures and decoding failures have retry states; an editions failure preserves the loaded work and the pagination offset.

BookDetailsTests uses injected fixtures and URLProtocol to cover decoding, keys, requests, caching, HTTP failures, cancellation, pagination retries, persistence identity and phone/accessibility rendering. These tests require no live Open Library calls. Current-model bookmarks persist work keys; migration tests check that historical bookmarks survive with a nil key.

## Search states and navigation

Before searching, Dashboard displays a start-search banner. Queries under three non-whitespace characters display typing guidance and do not start requests. A successful empty first page displays “No books found”; network failures remain distinct and offer retry. Existing results remain visible when a later page is empty or fails. Tests cover initial/short/loading/empty/failure/reset states and stale callbacks. Scene-hosted captures cover start and empty banners plus native Login navigation.

Landing and Dashboard each own one NavigationStack for their authentication state. Login, Sign Up, Saved Books and details inherit their parent's stack and native back navigation. Dashboard Saved/Log Out actions and Saved Books layout selection use native toolbar items.

## Private developer profile module

DeveloperProfileKit 1.0.0 owns the developer portrait, biography, social assets/links, expandable summary and app-information/disclaimer presentation. Apps supply their own name/version/build/disclaimer and navigation. The package uses the existing exact DesignTokensKit/UIComponentsKit versions. The app dependency record and Xcode lockfile verify the package commit.

The repository is private. Local builds need an authorized GitHub account with read access; CI uses a dedicated read-only deploy key stored as DEVELOPERPROFILEKIT_DEPLOY_KEY. The existing trusted-workflow SSH configuration routes only this repository through that key and removes temporary credentials after the run. No private keys are committed.

## HTTP logging

Verbose HTTP request/response logging is compiled only in Debug and disabled by default.
To inspect full redacted bodies, set `HTTP_LOGGING=1` in Xcode's scheme → Run → Arguments → Environment Variables.
Remove or disable that variable for normal testing; no HTTP body formatting or console output occurs when logging is off. Release always uses a nil logger, even if the variable is set.

## Discover and developer launch page

Debug builds launch into Developer settings. Choose a configuration and tap **Open ShowBook**. Reopen it from **App options → Developer settings**. Applying settings rebuilds the app navigation so screens and services pick up the configuration.

- Feature flags: Discover, cover previews and ratings. Release always enables these features.
- HTTP logs: toggle full redacted console logs. The toggle takes precedence over `HTTP_LOGGING`; Release always passes a nil logger.
- Data: Live uses the existing production APIs. Stub uses isolated URLSession fixtures for Open Library, country and IP endpoints; remote cover URLs are disabled. Scenarios: success, empty results, offline failure. Accounts and bookmarks still use local storage; this is not an authentication bypass.
- A/B override: Discover A uses list, B uses grid, with the existing accessibility list fallback. This is a local test override, not a remote experiment platform.
- Version/build: simulate display metadata in Know Your Developer. These controls do not modify Info.plist, signing, installed version or App Store metadata.

Discover uses the [Open Library Subjects API](https://openlibrary.org/dev/docs/api/subjects) for fiction, mystery, science and history, loading 12 works for the selected category. JSON cache lives under `Caches/Discover-v1`; live and each stub scenario have distinct files. A fresh cache lasts 24 hours; pull-to-refresh fetches again, falling back to an existing snapshot on failure. Cached titles survive relaunch; remote artwork is not guaranteed offline.

`run-networking-tests.py` tests runtime policy in both Debug and Release. `DiscoverServiceTests` covers mapping, deduplication and persistent offline fallback; `DeveloperDiscoverRenderingTests` renders the developer launch page and Discover variants.
