import SwiftUI

struct ContentView: View {
    @ObservedObject private var storage = StorageService.shared
    @State private var selectedTab: Tab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeableFeedView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Bits", systemImage: "bolt.fill")
                }
                .tag(Tab.feed)

            BookmarksView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(Tab.saved)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.white)
        .onChange(of: storage.shouldNavigateToFeed) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = .feed
                storage.shouldNavigateToFeed = false
            }
        }
    }
}

#Preview {
    ContentView()
}
