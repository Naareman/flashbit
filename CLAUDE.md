# Flashbit - Claude Code Project Context

## Project Overview

Flashbit is an iOS news reader app with Instagram Stories-style swipeable news cards from RSS feeds (BBC, Guardian, NPR News, TechCrunch). Built with SwiftUI, targeting iOS 17+.

## Build & Run

- Open `Flashbit.xcodeproj` in Xcode
- Build: Cmd+B
- Run: Cmd+R (simulator or device)
- No third-party dependencies

## Architecture

MVVM with feature-based folder organization:

- **Models**: `Bit` (article with `stableIdentifier`), `BitCategory` (8 categories), `Tab` (navigation)
- **ViewModels**: `FeedViewModel` (feed state), `SavedViewModel` (saved filters), `SettingsViewModel` (settings)
- **Views**: Organized by feature (Feed/, Saved/, Settings/, Components/)
- **Services**: `NewsService` (RSS fetching, actor-based), `StorageService` (UserDefaults persistence, singleton), `RSSParser` (XML parsing)
- **Core**: `AppConstants` (centralized constants), extensions (Date, String, URL), protocols (NewsServiceProtocol, StorageServiceProtocol)

## Key Files

| File | Purpose |
|------|---------|
| `App/FlashbitApp.swift` | App entry point, background task registration |
| `Views/ContentView.swift` | Root TabView (Bits, Saved, Settings) |
| `Views/Feed/SwipeableFeedView.swift` | Main feed with tap + swipe navigation, onboarding |
| `Views/Feed/BitCardView.swift` | Individual news card display |
| `Views/Saved/BookmarksView.swift` | Saved articles with filtering/sorting |
| `ViewModels/FeedViewModel.swift` | Feed state management, unseen bit filtering |
| `Services/NewsService.swift` | RSS feed orchestration with progressive loading |
| `Services/StorageService.swift` | Persistence, caching, seen tracking |
| `Core/Constants/AppConstants.swift` | All magic numbers centralized |

## RSS Feed Sources

| Source | URL | Category |
|--------|-----|----------|
| BBC News | `feeds.bbci.co.uk/news/rss.xml` | world |
| The Guardian | `theguardian.com/world/rss` | world |
| NPR News | `feeds.npr.org/1001/rss.xml` | world |
| TechCrunch | `techcrunch.com/feed/` | tech |

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
- ViewModels use dependency injection with optional params: `init(storage: StorageService? = nil)` + `storage ?? .shared` in body (avoids strict concurrency errors with default params)
- `os.Logger` for production logging (not `print()`)
- All interactive elements have accessibility labels/hints
- Text opacity minimum 0.7 for WCAG contrast compliance
- `OnboardingStep` enum for type-safe onboarding state
- `@ScaledMetric` for Dynamic Type font scaling
- `@Environment(\.accessibilityReduceMotion)` for animation control
- Batched `seenBitIds` persistence (debounced 1s via `Task.sleep`) with pruning
- `Task.sleep` over `DispatchQueue.main.asyncAfter` for async sequences
- `Bit.stableIdentifier` for deduplication/seen-tracking (single source of truth)
- Persistence failures logged via `os.Logger` (not silent `try?`)

## Navigation

- **Tap**: left half = previous, right half = next (instant transition)
- **Swipe**: horizontal DragGesture with simultaneous tap support — both cards slide as a pair using `dragOffset` + adjacent card rendering, `withAnimation { } completion: { }` for seamless index update
- **Double-tap**: save/unsave with toast notification
- **Swipe threshold**: `AppConstants.swipeThreshold` (50pt)

## Pending Tasks

None — all tasks completed.
