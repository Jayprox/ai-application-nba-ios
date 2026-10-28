import XCTest
import SwiftUI
import Vision
@testable import Chalk_That_NBA

/// Pilot 001: real player-detail views with fail-closed, in-process responses.
/// No published statistics are synthesized; every query has an empty sample.
final class EmptyStatePilotTests: XCTestCase {
    @MainActor
    func testE03Rookie() async throws {
        try await render("E-03", name: "Pilot Rookie", seasons: [], filters: ExplorerFilters())
    }

    @MainActor
    func testE05ZeroMatchingSplits() async throws {
        var filters = ExplorerFilters()
        filters.season = "2025-26"; filters.b2b = "2"; filters.alt = "yes"; filters.venue = "home"
        try await render("E-05", name: "Pilot Player", seasons: ["2025-26"], filters: filters)
    }

    @MainActor
    func testE06SeasonTypeNotPlayed() async throws {
        var filters = ExplorerFilters()
        filters.season = "2025-26"; filters.seasonType = "playoffs"
        try await render("E-06", name: "Stephen Curry", seasons: ["2025-26"], filters: filters)
    }

    @MainActor
    func testE07CupBeforeIntroduction() async throws {
        var filters = ExplorerFilters()
        filters.season = "2019-20"; filters.seasonType = "cup"
        try await render("E-07", name: "Pilot Player", seasons: ["2019-20"], filters: filters)
    }

    /// Run only with an operator present; interact through Device Hub.
    @MainActor
    func testInteractiveRecoveries() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["PILOT_INTERACTIVE"] == "1",
                          "Operator-only check: run with TEST_RUNNER_PILOT_INTERACTIVE=1")
        var split = ExplorerFilters()
        split.season = "2025-26"; split.b2b = "2"; split.alt = "yes"; split.venue = "home"
        try await render("E-05", name: "Pilot Player", seasons: ["2025-26"], filters: split, interactive: true)
        var type = ExplorerFilters()
        type.season = "2025-26"; type.seasonType = "playoffs"
        try await render("E-06", name: "Stephen Curry", seasons: ["2025-26"], filters: type, interactive: true)
    }

    @MainActor
    private func render(_ id: String, name: String, seasons: [String], filters: ExplorerFilters, interactive: Bool = false) async throws {
        XCTAssertEqual(URL(string: Endpoints.baseURL)?.host, "127.0.0.1", "Run with API_BASE_URL=http://127.0.0.1:9")
        let previous = APIClient.shared.session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [EmptyStatePilotProtocol.self]
        APIClient.shared.session = URLSession(configuration: config)
        EmptyStatePilotProtocol.resetQueries()
        EmptyStatePilotProtocol.name = name
        EmptyStatePilotProtocol.seasons = seasons
        defer { APIClient.shared.session.invalidateAndCancel(); APIClient.shared.session = previous }

        let host = UIHostingController(rootView:
            NavigationStack {
                PlayerDetailView(playerId: "pilot", filters: filters)
            }.preferredColorScheme(.dark))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        // Give SwiftUI's .task and layout transactions time to settle.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        host.view.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = id; attachment.lifetime = .keepAlways
        add(attachment)
        let recognition = VNRecognizeTextRequest()
        recognition.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: try XCTUnwrap(image.cgImage)).perform([recognition])
        let text = (recognition.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        let normalized = text.replacingOccurrences(of: "’", with: "'")
        let textAttachment = XCTAttachment(string: text)
        textAttachment.name = id + " recognized text"; textAttachment.lifetime = .keepAlways; add(textAttachment)
        XCTAssertFalse(text.contains("Crunching"), "Loading must settle")
        let expected: String
        switch id {
        case "E-03": expected = "No games for Pilot Rookie since 2003-04 (where our stats begin)."
        case "E-05": expected = "None of Pilot Player's 2025-26 regular season games match these splits."
        case "E-06": expected = "Stephen Curry didn't play in the 2025-26 playoffs. Games that season: regular season."
        default: expected = "The NBA Cup started in 2023-24, so there are no Cup games in 2019-20."
        }
        XCTAssertTrue(normalized.contains(expected), "Expected rendered message; recognized text: \(text)")
        if interactive {
            let before = XCTAttachment(image: image)
            before.name = id + " before tap"; before.lifetime = .keepAlways; add(before)
            // Yield to the main actor while the operator taps the real control.
            // A new request must contain the recovered filters, not just new text.
            var recovered = false
            for _ in 0..<180 {
                let queries = EmptyStatePilotProtocol.queries()
                if queries.count >= 2, let last = queries.last,
                   (last["season_type"] as? String) == "regular",
                   let splits = last["splits"] as? [String: Any], splits.isEmpty {
                    recovered = true; break
                }
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            XCTAssertTrue(recovered, "Expected a fresh query after the actual recovery tap")
            try await Task.sleep(nanoseconds: 500_000_000)
            host.view.layoutIfNeeded()
            let after = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
            let capture = XCTAttachment(image: after)
            capture.name = id + " after tap"; capture.lifetime = .keepAlways; add(capture)
            let read = VNRecognizeTextRequest(); read.recognitionLevel = .accurate
            try VNImageRequestHandler(cgImage: try XCTUnwrap(after.cgImage)).perform([read])
            let afterText = (read.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            XCTAssertTrue(afterText.contains("No games for \(name) in the 2025-26 regular season."), afterText)
            XCTAssertFalse(afterText.contains("Crunching"))
            let evidence = XCTAttachment(string: "Recovered request: regular season, no splits. " + afterText)
            evidence.name = id + " recovery result"; evidence.lifetime = .keepAlways; add(evidence)
            // Keep the recovered screen visible briefly for operator inspection.
            try await Task.sleep(nanoseconds: 3_000_000_000)
            return
        }
        if id == "E-05" || id == "E-06" {
            let title = id == "E-05" ? "Clear splits" : "Show Regular season"
            XCTAssertTrue(text.contains(title), "Recovery button must be visible")
            // This verifies the model transitions used by ResultView's callbacks,
            // not a tap. Simulator UI interaction remains a manual check.
            let vm = StatExplorerViewModel(entity: .player, id: "pilot", name: name,
                seasons: seasons, seasonTypes: Dictionary(uniqueKeysWithValues: seasons.map { ($0, ["regular"]) }),
                lines: nil, startFilters: filters)
            await vm.load()
            XCTAssertTrue(vm.isCurrent)
            XCTAssertNil(vm.error)
            let oldQuery = vm.currentQuery
            if id == "E-05" { vm.filters.clearSplits() } else { vm.filters.seasonType = "regular" }
            XCTAssertNotEqual(oldQuery, vm.currentQuery)
            XCTAssertFalse(vm.isCurrent, "Old response must not be shown under changed controls")
            await vm.load()
            XCTAssertTrue(vm.isCurrent)
            XCTAssertFalse(vm.isLoading)
            XCTAssertNil(vm.error)
            let recovered = NoGamesMessage.make(name: name, filters: vm.filters, played: vm.playedTypes)
            XCTAssertEqual(recovered.text, "No games for \(name) in the 2025-26 regular season.")
            XCTAssertTrue(recovered.actions.isEmpty)
        }
    }

}

private final class EmptyStatePilotProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var queryLog: [[String: Any]] = []
    static func resetQueries() { lock.lock(); defer { lock.unlock() }; queryLog = [] }
    static func queries() -> [[String: Any]] { lock.lock(); defer { lock.unlock() }; return queryLog }
    private static func record(_ data: Data) {
        lock.lock(); defer { lock.unlock() }
        if let query = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { queryLog.append(query) }
    }
    private func requestBody() -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open(); defer { stream.close() }
        var data = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }; data.append(buffer, count: count)
        }
        return data
    }
    static var name = "Pilot Player"
    static var seasons: [String] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let object: [String: Any]
        switch (request.httpMethod, request.url?.path) {
        case ("GET", "/players/pilot"):
            object = ["data": ["id": "pilot", "full_name": Self.name, "is_active": true,
                               "seasons": Self.seasons,
                               "season_types": Dictionary(uniqueKeysWithValues: Self.seasons.map { ($0, ["regular"]) })], "meta": [:]]
        case ("GET", "/players/pilot/props"):
            object = ["data": ["upcoming": NSNull(), "record": [:]], "meta": [:]]
        case ("POST", "/query"):
            Self.record(requestBody())
            object = ["data": NSNull(), "meta": ["sample_size": 0, "record": "0-0", "notes": []]]
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        guard let url = request.url, url.host == "127.0.0.1" else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: object))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
