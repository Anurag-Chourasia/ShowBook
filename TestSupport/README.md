# Integration validation

Run `python3 TestSupport/run-networking-tests.py` from the repository root with Xcode 27.0 selected. It copies the actual NetworkClass and DTOs into a disposable package and runs six offline tests with session-scoped URLProtocol classes. It does not use live APIs or alter app file membership.

Tests cover callback count/off-main completion, headers, search query/pagination, DTOs, success/non-2xx, malformed/empty JSON, cancellation and country-specific error mapping. The app retains its original URL interpolation, counter, JSONDecoder and callback API. No cancellation handle is added. Existing app tests still include live image downloads; their results are reported separately.

FoundationKit trims the hex helper exactly as before. LocalizationKit remains linked but unused: the app's literal Text localization has no validated equivalent use in the package; package-owned demo strings would change wording/fallback. No empty formatting calls or unused import is added.

Known pre-existing issues remain out of scope: query encoding of reserved characters, signup loading after IP failure, incomplete Region enum, weak/live-network legacy tests.

Run `bash TestSupport/run-app-tests.sh DERIVED_DATA` for the existing ShowBookTests target on a prebooted iPhone 18 Pro simulator. The scheme has a stale ShowBookUITests reference; this command explicitly selects the real unit-test target.
