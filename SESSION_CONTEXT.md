# Flashbit Session Context

## Project Overview
Flashbit is an iOS news reader app with Instagram Stories-style swipeable news cards from RSS feeds (BBC, Guardian, Reuters, TechCrunch).

## Key Features Implemented
- Swipeable feed with tap navigation (left = previous, right = next)
- Double-tap to save articles
- Article caching (200 default, 500 max) with delta fetching
- Seen tracking (only show unseen articles on next session)
- Interactive onboarding tutorial
- In-app Safari browser for full articles (tap headline to open)
- Filter/sort saved articles by category and date
- Background refresh

## Current Task - Pending Items

### From Latest Request (8 items, 3 completed):

**Completed:**
1. ✅ Hide progress bar on "That's everything for now" card
2. ✅ Change welcome screen text to "One bit = One story"
3. ✅ Use actual app logo (AppIcon) in welcome screen

**Remaining:**
4. ⏳ Remove "One bit = one story" from onboarding article 1 summary (it's now in welcome screen)
5. ⏳ Make URL arrow not clickable during onboarding (opens example.com nonsense)
6. ⏳ Fix date format in Saved filter to use "d MMM yyyy" format (currently shows "17/12/2025" and "17 Jan 2026" inconsistently)
7. ⏳ Re-fetch RSS if user increased max cached bits and reopened app (even if 15m hasn't passed)
8. ⏳ Change "Saved" navigation title to "Saved bits"

## Key Files

- `SwipeableFeedView.swift` - Main feed, onboarding, navigation
- `BitCardView.swift` - Individual news card display
- `ContentView.swift` - Tab bar, Saved view, Settings, filters
- `StorageService.swift` - Persistence, caching, seen tracking
- `NewsService.swift` - RSS fetching
- `FeedViewModel.swift` - Feed state management

## Recent Changes Made This Session

1. Made headline clickable to open article (removed separate Read button)
2. Fixed tap zones to exclude bottom 280pt for headline tapping
3. Simplified onboarding prompts ("Next bit", "Previous bit", "Double-tap to save")
4. Changed caught up card to "That's everything for now"
5. Toast messages now say "Saved bit" / "Unsaved bit"
6. Filter chips have sharper corners (cornerRadius 6)
7. Settings button says "Show me how it works"
8. Cache setting no longer affects current session (takes effect on next refresh)
9. Welcome screen now uses app logo and "One bit = One story"
10. Progress bar hidden on caught up card

## To Continue
Run: `claude` in this directory and say "continue with the pending tasks from SESSION_CONTEXT.md"
