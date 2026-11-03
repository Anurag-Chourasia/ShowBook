# ShowBook Test Lanes & Execution Budgets

Last updated: 3 November 2026  
Milestone: **M5 Test lanes** (Ticket IOS-22)

## 1. Overview & Lane Architecture
ShowBook organizes testing into four distinct lanes to maximize developer feedback velocity on pull requests while guaranteeing comprehensive regression, performance, and persistence safety on merge and scheduled builds.

```
       ┌─────────────────────────────────────────────────────────────┐
       │                       Pull Request                          │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │       Fast Lane        │  │      UI Smoke Lane     │   │
       │    │   Unit tests & tokens  │  │ Core search/nav flows  │   │
       │    │     (< 200s budget)    │  │     (< 60s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └──────────────────────────────┬──────────────────────────────┘
                                      │
                                      ▼  Merge to main
       ┌─────────────────────────────────────────────────────────────┐
       │                Integration & Scheduled Deep Lanes           │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │    Integration Lane    │  │    Performance Lane    │   │
       │    │ Core Data V1-V5, UUID  │  │  Disk & Cache metrics  │   │
       │    │     (< 60s budget)     │  │     (< 45s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └─────────────────────────────────────────────────────────────┘
```

---

## 2. Lane Mapping & Measured Durations

| Lane | Scope & Test Classes | Trigger | Measured Duration | Budget Target | Artifact Generated |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Fast Lane** | • Pinned checks (`verify_pins.py`)<br>• Design tokens audit (`check_design_tokens.py`)<br>• Networking adapter (`run-networking-tests.py`)<br>• Fast unit tests: `BookItemViewModelTests`, `BookmarkButtonViewModelTests`, `TextFieldObserverTests`, `PrivacyManifestTests`, `LoginViewModelTests`, `CredentialStorageTests`, `SignUpViewModelTests`, `UserViewModelTests`, `AuthenticationFlagTests` | Every PR & Push | ~45s (warm) / ~180s (cold) | < 200s | `ShowBookFast.xcresult` |
| **UI Smoke Lane** | • Core navigation & search rendering (`SearchNavigationRenderingTests`)<br>• Search state machine & pagination (`DashboardViewModelTests`) | Every PR & Push | ~37s | < 60s | `ShowBookSmoke.xcresult` |
| **Integration Lane** | • Core Data V1–V5 migrations & UUID linking (`BookmarkUUIDMigrationTests`)<br>• Entity relationships & inverse nullification (`PersistenceRelationshipTests`)<br>• Offline search cache & service (`DiscoverServiceTests`, `BookmarkViewModelTests`) | Merge to `main`, Scheduled, Dispatch | ~33s | < 60s | `ShowBookIntegration.xcresult` |
| **Performance Lane** | • Catalog cache disk serialization throughput (`testBookCatalogCacheThroughput`)<br>• Core Data batch insertion & retrieval (`testBookmarkBatchPersistenceThroughput`)<br>• Search response JSON decode throughput (`testSearchResponseDecodingThroughput`) | Merge to `main`, Scheduled, Dispatch | ~38s | < 45s | `ShowBookPerformance.xcresult` |

---

## 3. CLI Script Entry Points
Developers can run any lane independently or all lanes together locally:

- **Fast Lane**: `bash Scripts/test-fast.sh`
- **UI Smoke Lane**: `bash Scripts/test-smoke.sh`
- **Integration Lane**: `bash Scripts/test-integration.sh`
- **Performance Lane**: `bash Scripts/test-performance.sh`
- **All Lanes Combined**: `bash Scripts/test-all-lanes.sh`

---

## 4. Artifact Retention & CI Diagnostics
- All test runs capture standard Xcode result bundles (`.xcresult`) via `-resultBundlePath`.
- In GitHub Actions CI, all `.xcresult` files are uploaded as run artifacts (`showbook-test-results`) using `actions/upload-artifact@v7`.
- On test failure, engineers can download the bundle and inspect failure traces, screenshots, and logs in Xcode Organizer with one click.
