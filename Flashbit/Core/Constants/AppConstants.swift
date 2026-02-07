import SwiftUI

enum AppConstants {

    // MARK: - Layout

    static let bottomExcludedTapZoneHeight: CGFloat = 280
    static let categoryBadgeTopPadding: CGFloat = 70
    static let contentTopPadding: CGFloat = 100
    static let contentBottomPadding: CGFloat = 100
    static let horizontalPadding: CGFloat = 48
    static let cardHorizontalPadding: CGFloat = 24
    static let tabBarHeight: CGFloat = 85
    static let progressBarTopPadding: CGFloat = 44
    static let welcomeIconSize: CGFloat = 100
    static let welcomeIconCornerRadius: CGFloat = 22
    static let caughtUpIconSize: CGFloat = 120
    static let caughtUpBoltSize: CGFloat = 50

    // MARK: - Typography

    static let headlineFontSize: CGFloat = 28
    static let welcomeTitleFontSize: CGFloat = 28
    static let caughtUpTitleFontSize: CGFloat = 28

    // MARK: - Feed

    static let maxProgressSegments = 20
    static let maxSummaryLines = 5
    static let smartTruncateMaxLength = 160
    static let headlineTruncateMaxLength = 90

    // MARK: - Storage

    static let maxArticlesLimit = 500
    static let minArticlesLimit = 20
    static let defaultMaxArticles = 200
    static let itemsPerSourceFirstFetch = 50

    // MARK: - Animation & Timing

    static let toastDuration: TimeInterval = 1.5
    static let onboardingDelay: TimeInterval = 0.8
    static let successToastDelay: TimeInterval = 0.8
    static let successToastDuration: TimeInterval = 2.0
    static let clearOnboardingDelay: TimeInterval = 0.4
    static let pulseAnimationDuration: TimeInterval = 0.8
    static let navigationAnimationDuration: TimeInterval = 0.2

    // MARK: - Background Tasks

    static let backgroundRefreshInterval: TimeInterval = 15 * 60
    static let backgroundTaskIdentifier = "com.flashbit.app.refresh"
}
