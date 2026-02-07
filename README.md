# Flashbit

An iOS news reader app with Instagram Stories-style swipeable news cards from RSS feeds.

## Features

- **Swipeable feed** with tap navigation (left = previous, right = next)
- **Double-tap to save** articles for later
- **Article caching** with delta fetching (200 default, 500 max)
- **Seen tracking** - only shows unseen articles on next session
- **Interactive onboarding** tutorial for first-time users
- **In-app Safari** browser for full articles (tap headline to open)
- **Filter & sort** saved articles by category and date
- **Background refresh** to keep articles up to date
- **Dark mode** interface

## RSS Sources

- BBC News
- The Guardian
- Reuters
- TechCrunch

## Architecture

Flashbit follows the **MVVM (Model-View-ViewModel)** pattern with a clean feature-based folder structure:

```
Flashbit/
├── App/                    # App entry point & lifecycle
├── Core/
│   ├── Constants/          # Centralized app constants
│   ├── Extensions/         # Date and String extensions
│   └── Protocols/          # Service protocol definitions
├── Models/                 # Data models (Bit, BitCategory, Tab)
├── Services/               # Network & persistence services
├── ViewModels/             # State management per feature
├── Views/
│   ├── Components/         # Reusable UI components
│   ├── Feed/               # Main feed views
│   ├── Saved/              # Saved articles views
│   └── Settings/           # Settings views
└── Assets.xcassets/        # App icons & colors
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5

## Getting Started

1. Clone the repository
2. Open `Flashbit.xcodeproj` in Xcode
3. Select a simulator or device
4. Build and run (Cmd+R)

No third-party dependencies required.

## Tech Stack

- **SwiftUI** - Declarative UI framework
- **Swift Concurrency** - async/await, actors
- **XMLParser** - RSS feed parsing
- **UserDefaults** - Local persistence
- **BackgroundTasks** - Background article refresh
- **SafariServices** - In-app article viewing
