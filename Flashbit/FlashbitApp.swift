import SwiftUI
import BackgroundTasks

@main
struct FlashbitApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.flashbit.app.refresh",
            using: nil
        ) { task in
            Self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                scheduleBackgroundRefresh()
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.flashbit.app.refresh")
        // Schedule to run in 15 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        let request = BGAppRefreshTaskRequest(identifier: "com.flashbit.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)

        // Create a task to fetch new articles
        let fetchTask = Task {
            do {
                let newsService = NewsService()
                _ = try await newsService.fetchBits()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            fetchTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
