# SwiftLint policy

ShowBook and MyTV share an explicit 24-rule policy, pinned to SwiftLint 0.65.1. The checked-in `.swiftlint.yml` is the source of truth; update both repositories together when changing rules. `only_rules` keeps upgrades from silently enabling unrelated rules.

| Area | Rules |
|---|---|
| Unsafe operations | `force_cast`, `force_try`, `force_unwrapping` |
| Duplicate patterns | `duplicate_imports`, `duplicate_conditions`, `duplicate_enum_cases` |
| Unused values | `unused_closure_parameter`, `unused_optional_binding`, `unused_setter_value` |
| Intent and readability | `empty_count`, `fatal_error_message`, `syntactic_sugar`, `void_return` |
| Formatting | `colon`, `comma`, `opening_brace`, `closing_brace`, `return_arrow_whitespace`, `statement_position`, `trailing_comma`, `trailing_newline`, `trailing_semicolon`, `trailing_whitespace`, `vertical_whitespace` |

All warnings fail through `--strict`; CI never auto-corrects code. The scan includes app code, existing/future app tests, and TestSupport. Generated localization files and third-party code are excluded. There are no blanket test-target exemptions. File-length, identifier-length, and complexity limits are intentionally not imposed in this first rollout; these need a separate architectural decision, especially for SwiftUI views. Accessibility-specific lint rules will be evaluated with the accessibility work rather than mistaken for runtime VoiceOver coverage.

## Local use

Select a full Xcode installation first (`DEVELOPER_DIR` can override the system selection), then:

```sh
bash Scripts/install-swiftlint.sh /tmp/project-swiftlint
SWIFTLINT_BIN=/tmp/project-swiftlint/swiftlint bash Scripts/lint.sh
```

An already installed SwiftLint of the exact version also works with `bash Scripts/lint.sh`. The installer pins the upstream release URL and SHA256; the runner refuses a version mismatch. Installation is explicit and does not modify Xcode projects, package dependencies, or your global PATH.

## Existing debt

`.swiftlint-baseline.json` records violations already present when this policy was introduced. A passing result means no violations beyond that baseline, not that the legacy code is free of violations. Baseline entries include source text and locations, so editing an affected line may make its existing violation visible again. Fix it instead of reflexively regenerating the baseline.

New code must comply. Prefer safe optional handling and `XCTUnwrap` in tests. A genuine exception needs a narrowly scoped rule suppression with a reason and normal PR approval. Baseline growth, exclusions, suppressions, and rule changes are policy changes requiring explicit review. CI never rewrites the baseline. Remove resolved entries during deliberate cleanup; do not use the baseline as a hiding place for new issues.

## CI and merge gate

The dedicated `swiftlint` job runs on every PR, including forks, before the existing `build-and-test` job. It requires no repository secrets or private package access. There are no changed-file filters, `continue-on-error`, or automatic fixes. The existing build/test pipeline remains intact and starts only after lint succeeds.

The repository's server-side branch protection must require both `swiftlint` and `build-and-test`, plus the existing approval requirements. YAML alone cannot block merges. Keep the required check names stable. An administrator can still deliberately change repository protection settings; this setup does not claim otherwise.

Upstream configuration reference: https://github.com/realm/SwiftLint#configuration
