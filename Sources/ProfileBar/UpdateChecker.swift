import AppKit

struct AppVersion: Comparable {
    private let parts: [Int]

    init?(_ value: String) {
        let number = value.hasPrefix("v") ? value.dropFirst() : Substring(value)
        let components = number.split(separator: ".", omittingEmptySubsequences: false)
        let parts = components.compactMap { Int($0) }
        guard
            !parts.isEmpty,
            parts.count == components.count,
            parts.allSatisfy({ $0 >= 0 })
        else { return nil }
        self.parts = parts
    }

    static func < (left: AppVersion, right: AppVersion) -> Bool {
        let count = max(left.parts.count, right.parts.count)
        for index in 0..<count {
            let leftPart = index < left.parts.count ? left.parts[index] : 0
            let rightPart = index < right.parts.count ? right.parts[index] : 0
            if leftPart != rightPart { return leftPart < rightPart }
        }
        return false
    }

    static func == (left: AppVersion, right: AppVersion) -> Bool {
        !(left < right) && !(right < left)
    }
}

enum UpdateCheckPolicy {
    static let interval: TimeInterval = 24 * 60 * 60
    static let launchDelay: TimeInterval = 10

    static func delay(lastCheck: Date?, now: Date) -> TimeInterval {
        guard let lastCheck else { return launchDelay }
        let due = lastCheck.addingTimeInterval(interval).timeIntervalSince(now)
        return min(interval, max(launchDelay, due))
    }
}

struct GitHubRelease: Decodable {
    let tagName: String
    let pageURL: URL

    var version: AppVersion? { AppVersion(tagName) }
    var versionText: String { tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case pageURL = "html_url"
    }
}

@MainActor
final class UpdateChecker {
    private static let latestReleaseURL = URL(
        string: "https://api.github.com/repos/afrojun/profilebar/releases/latest")!
    private static let lastCheckKey = "lastUpdateCheck"

    private let currentVersion: AppVersion
    private let currentVersionText: String
    private let appName: String
    private let defaults: UserDefaults
    private let session: URLSession
    private var timer: Timer?
    private(set) var isChecking = false

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        guard
            let versionText = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let version = AppVersion(versionText)
        else { fatalError("CFBundleShortVersionString must be a numeric version") }

        currentVersion = version
        currentVersionText = versionText
        appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "ProfileBar"
        self.defaults = defaults

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
    }

    func start() {
        let lastCheck = defaults.object(forKey: Self.lastCheckKey) as? Date
        schedule(after: UpdateCheckPolicy.delay(lastCheck: lastCheck, now: Date()))
    }

    func checkNow() {
        check(manual: true)
    }

    private func schedule(after delay: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.check(manual: false)
            }
        }
    }

    private func check(manual: Bool) {
        guard !isChecking else { return }
        isChecking = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let release = try await fetchLatestRelease()
                finish(release, manual: manual)
            } catch {
                finish(error: error, manual: manual)
            }
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: Self.latestReleaseURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("ProfileBar/\(currentVersionText)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw UpdateCheckError.badResponse
        }
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard
            release.version != nil,
            release.pageURL.scheme == "https",
            release.pageURL.host == "github.com"
        else { throw UpdateCheckError.badVersion }
        return release
    }

    private func finish(_ release: GitHubRelease, manual: Bool) {
        isChecking = false
        guard let latestVersion = release.version else {
            if manual { show(error: UpdateCheckError.badVersion) }
            return
        }
        defaults.set(Date(), forKey: Self.lastCheckKey)
        schedule(after: UpdateCheckPolicy.interval)
        if currentVersion < latestVersion {
            show(release: release)
        } else if manual {
            showCurrentVersion()
        }
    }

    private func finish(error: Error, manual: Bool) {
        isChecking = false
        schedule(after: UpdateCheckPolicy.interval)
        if manual { show(error: error) }
    }

    private func show(release: GitHubRelease) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "\(appName) \(release.versionText) is available"
        alert.informativeText = "You’re using version \(currentVersionText). Download the update from GitHub."
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.pageURL)
        }
    }

    private func showCurrentVersion() {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "\(appName) is up to date"
        alert.informativeText = "You’re using the latest version, \(currentVersionText)."
        alert.runModal()
    }

    private func show(error: Error) {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t check for updates"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

private enum UpdateCheckError: LocalizedError {
    case badResponse
    case badVersion

    var errorDescription: String? {
        switch self {
        case .badResponse:
            "GitHub didn’t return a valid release. Try again later."
        case .badVersion:
            "The latest release has an invalid version number."
        }
    }
}
