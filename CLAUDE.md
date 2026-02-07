# Flashbit - Claude Code Project Context

## Project Overview

Flashbit is an iOS news reader app with Instagram Stories-style swipeable news cards from RSS feeds (BBC, Guardian, Reuters, TechCrunch). Built with SwiftUI, targeting iOS 17+.

## Build & Run

- Open `Flashbit.xcodeproj` in Xcode
- Build: Cmd+B
- Run: Cmd+R (simulator or device)
- No third-party dependencies

## Architecture

MVVM with feature-based folder organization:

- **Models**: `Bit` (article), `BitCategory` (8 categories), `Tab` (navigation)
- **ViewModels**: `FeedViewModel` (feed state), `SavedViewModel` (saved filters), `SettingsViewModel` (settings)
- **Views**: Organized by feature (Feed/, Saved/, Settings/, Components/)
- **Services**: `NewsService` (RSS fetching, actor-based), `StorageService` (UserDefaults persistence, singleton), `RSSParser` (XML parsing)
- **Core**: `AppConstants` (centralized constants), extensions (Date, String), protocols (NewsServiceProtocol, StorageServiceProtocol)

## Key Files

| File | Purpose |
|------|---------|
| `App/FlashbitApp.swift` | App entry point, background task registration |
| `Views/ContentView.swift` | Root TabView (Bits, Saved, Settings) |
| `Views/Feed/SwipeableFeedView.swift` | Main feed with tap navigation, onboarding |
| `Views/Feed/BitCardView.swift` | Individual news card display |
| `Views/Saved/BookmarksView.swift` | Saved articles with filtering/sorting |
| `ViewModels/FeedViewModel.swift` | Feed state management, unseen bit filtering |
| `Services/NewsService.swift` | RSS feed orchestration with progressive loading |
| `Services/StorageService.swift` | Persistence, caching, seen tracking |
| `Core/Constants/AppConstants.swift` | All magic numbers centralized |

## Conventions

- Dark mode only (set in FlashbitApp)
- All constants go in `AppConstants.swift`
- Extensions go in `Core/Extensions/`
- Reusable components go in `Views/Components/`
- Each screen gets its own ViewModel
- Services have protocol definitions for testability
- Category appearance (color, icon, gradient) is on the `BitCategory` enum
- `@MainActor` on StorageService — all UI state is main-thread isolated
- `@EnvironmentObject` for StorageService in views (not `@ObservedObject`)
- ViewModels use dependency injection with default parameter values
- `os.Logger` for production logging (not `print()`)
- All interactive elements have accessibility labels/hints
- Text opacity minimum 0.7 for WCAG contrast compliance
- `OnboardingStep` enum for type-safe onboarding state
- `@ScaledMetric` for Dynamic Type font scaling
- `@Environment(\.accessibilityReduceMotion)` for animation control
- Batched `seenBitIds` persistence (debounced 1s) for performance
- `Task.sleep` over `DispatchQueue.main.asyncAfter` for async sequences

## Pending Tasks

None — all tasks completed.
