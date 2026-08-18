import Foundation

enum AppLaunchEnvironment {
    static func prepare() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-testing-reset") else { return }

        let defaults = UserDefaults.standard
        [
            "echo.profile.v10", "echo.profile.v10.backup",
            "echo.profile.v6", "echo.profile.v6.backup",
            "echo.profile.v5", "echo.profile.v5.backup",
            "echo.profile.v4", "echo.profile.v4.backup",
            "echo.profile.v3", "echo.profile.v2"
        ].forEach { defaults.removeObject(forKey: $0) }
        defaults.set(true, forKey: "echo.settings.onboardingCompleted")
        defaults.set(false, forKey: "echo.settings.reducedMotion")
        defaults.set(true, forKey: "echo.settings.autoPerformance")
        defaults.set(true, forKey: "echo.settings.tutorialHints")
        defaults.synchronize()
        #endif
    }
}
