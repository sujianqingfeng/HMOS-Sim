# Repository Guidelines

## Project Structure & Module Organization

- `HMOSSimApp/`: Primary macOS app (Xcode project).
  - `HMOSSimApp/HMOSSimApp/`: SwiftUI app source.
    - `Models/`: App state and data models (e.g. `AppModel`).
    - `Services/`: Process execution and DevEco/hdc integration.
    - `Views/`: SwiftUI UI (Dashboard, Logs, menu bar, Settings).
    - `Resources/`: `Info.plist`, `Assets.xcassets`.
- Tests: none yet.

## Build, Test, and Development Commands

- Build Xcode app: `xcodebuild -project HMOSSimApp/HMOSSimApp.xcodeproj -target HMOSSimApp -configuration Debug build`
- Run locally (recommended): open `HMOSSimApp/HMOSSimApp.xcodeproj` in Xcode and Run.

The app shells out to DevEco tools (Emulator/hdc). Configure paths in Settings if autodetection fails.

## Coding Style & Naming Conventions

- Language: Swift (SwiftUI + AppKit bridging where needed).
- Indentation: follow Xcode defaults (spaces; keep diffs minimal).
- Naming:
  - Types: `UpperCamelCase` (e.g. `HdcService`), functions/vars: `lowerCamelCase`.
  - Files match primary type name (e.g. `DashboardView.swift`).
- No formatter/linter is wired up; avoid drive-by formatting.

## Testing Guidelines

No test suite is configured. When adding tests, prefer `XCTest` under `HMOSSimAppTests/` with `*Tests.swift` naming and runnable via Xcode Test.

## Commit & Pull Request Guidelines

- Commits: use short, imperative messages (e.g. `Fix hilog autoscroll`, `Add target filter`).
- PRs should include:
  - What changed + why, with screenshots for UI changes (Dashboard/Logs/menu bar).
  - Any DevEco/hdc assumptions (paths, required versions) and reproduction steps.
  - Console logs only when diagnosing issues (avoid pasting sensitive paths/keys).

## Security & Configuration Tips

- External process execution is core functionality—avoid hardcoding machine-specific paths.
- Keep defaults in `UserDefaults` keys (see `DefaultsKey`) and validate executables before running.
