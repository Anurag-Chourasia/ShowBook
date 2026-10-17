## ShowBook

### Overview
- **Demo App** created using **SwiftUI** and **Core Data** framework.
- **Design Pattern**: MVVM
- **Unit Testing**: Included

### Project Details
- **Xcode Version**: 15.4
- **Swift Version**: 5
- **iOS Deployment Target**: 17.0
- **Tested Simulators**: iPhone 15 Pro Max, iPhone SE (3rd Gen)

### How to Use the app
Internet is Required when navigating to sign up view and when searching books from dashboard.
1. **Sign Up**:
   - Complete all checkboxes to successfully register.
   - Sign up first before logging in; credentials stored in the database.

2. **Login**:
   - Validate and log in using credentials stored in Core Data.

3. **Dashboard**:
   - Search, filter, and bookmark books.
   - Logout and access the Bookmark view.
   - Load more books by scrolling.

4. **Bookmark View**:
   - View and reload bookmarked books.
   - Sessions and bookmarks are maintained per user.
   
### Recommended to run test cases one class after another, Testing all together might end up giving false result.

### Features
- **Sign Up View**:
  - API call to fetch and save the list of countries to Core Data.
  - Validate email and password using regex.
  - Save user details for login purpose.

- **Login View**:
  - Validate email and password using regex.
  - Check user presence in Core Data.

- **Dashboard View**:
  - Search books with debouncing textfield.
  - Add bookmarks by sliding book items and clicking the bookmark button.
  - Filter book list by title, average ratings, and hits; clear selected options.
  - Logout user and navigate to Bookmark view.
  - Load more books by stretching the bottom of the list.

- **Bookmark View**:
  - Display bookmarked books fetched from Core Data.
  - Reload bookmark list by stretching from top to bottom.
  - Maintain user sessions and privacy; users cannot view each other's bookmarks.

### Limitations
- **Saving Books**: No API-provided IDs; UUIDs used for distinction.
  - Books with the same title, author, rating, review, and cover ID are saved as a single entry.

## Future Plans

Proposed enhancements, not completed features. Extend existing implementations where applicable.

| Enhance engineering skills | Enhance user experience |
|---|---|
| **Offline-first library:** local persistence, cache expiry, background refresh, and data migrations | Open saved books without internet and clearly identify outdated information. |
| **Reliable search pipeline:** strengthen cancellation, request deduplication, pagination, and stale-response protection | Faster search, recent searches, and fewer loading interruptions. |
| **Reading-progress model:** validated state transitions and persistent progress | Want to Read, Reading, Finished, and a Continue Reading section. |
| **Cross-device sync:** conflict resolution, retry handling, and deletion tracking | Keep reading lists and progress consistent across devices. |
| **Resilient image loading:** memory/disk caches, request coalescing, and cancellation | Faster covers, fewer blank images, and lower data usage. |
| **Accessibility validation:** automated checks plus VoiceOver and Dynamic Type testing | Comfortable browsing with large text and assistive technologies. |
| **Performance measurement:** launch benchmarks, scrolling analysis, and memory profiling | Smooth browsing as the saved library grows. |

First priority: the offline-first reading library. Preserve search, filters, layout,
and scroll position when returning from book details wherever that state currently resets.
