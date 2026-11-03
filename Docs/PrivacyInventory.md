# ShowBook Privacy Inventory & Manifest Declarations

Last updated: 3 November 2026

## 1. Overview & Data Philosophy
ShowBook is designed to respect user privacy by default. The application collects only the minimal data required to deliver core book discovery, search, cataloging, and personal bookmarking functionality.

- **Zero Tracking**: ShowBook does not track users across third-party websites or applications (`NSPrivacyTracking: false`).
- **No Third-Party Ad Networks or Data Brokers**: No advertising identifiers (IDFA), behavioral trackers, or data broker SDKs are embedded in the application.
- **Offline / Local by Default**: When the cloud authentication feature flag is off, user accounts and bookmarks remain strictly on the local device within the Core Data SQLite store.

---

## 2. Collected Data Categories (Apple Privacy Nutrition Label)

| Data Type | Purpose | Linked to User? | Used for Tracking? | Retention / Storage |
| :--- | :--- | :--- | :--- | :--- |
| **User ID** (`NSPrivacyCollectedDataTypeUserID`) | App Functionality (Account identity & bookmark synchronization across sessions) | Yes | No | Retained in Keychain & Core Data until account deletion or logout. |
| **Email Address** (`NSPrivacyCollectedDataTypeEmailAddress`) | App Functionality (User login, verification, and password recovery) | Yes | No | Retained in Supabase Auth & local Core Data until account deletion. |
| **Other User Content** (`NSPrivacyCollectedDataTypeOtherUserContent`) | App Functionality (Saved book bookmarks, title, author, cover ratings) | Yes | No | Stored locally in Core Data SQLite store; scoped by user UUID. |

---

## 3. Required-Reason APIs (`PrivacyInfo.xcprivacy`)

In accordance with Apple App Store review guidelines, ShowBook declares all required-reason APIs accessed by the application:

### `NSPrivacyAccessedAPICategoryUserDefaults`
- **Reason Code**: `CA92.1`
- **Declared Usage**: Accessing `UserDefaults` and `@AppStorage` solely to read and write application preferences, user interface settings, developer feature flags (`developer.authentication`, `developer.source`), and active session state indicators on device.

---

## 4. Network Endpoints & Third-Party SDKs

1. **Supabase Auth** (`AuthKit`):
   - Secure TLS 1.3 client authentication and session management.
   - Public publishable keys only; no administrative service-role keys in client bundles.
2. **Open Library API** (`https://openlibrary.org`):
   - Public read-only REST API for book search and catalog queries.
   - No user identity, tokens, or PII transmitted in query requests.

---

## 5. Storage & Sensitive Credential Logging Policy

- **Keychain**: Supabase session tokens are stored in the hardware-backed Keychain with strict access control.
- **Core Data**: Stored in application sandbox (`ShowBookV5.sqlite`). Passwords are never stored in plaintext (PBKDF2-SHA256 salted hashes only for legacy local accounts).
- **Logging Audit**: Logging audit verified that passwords, password hashes, access tokens, refresh tokens, and user email addresses are never logged to console or standard output.

---

## 6. Support & Privacy Contact
- **Privacy Policy**: [https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md](https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md)
- **Developer Support**: [mailto:anuragchourasiaios@gmail.com](mailto:anuragchourasiaios@gmail.com)
