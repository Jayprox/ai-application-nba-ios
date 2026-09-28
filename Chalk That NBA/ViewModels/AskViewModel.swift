//
//  AskViewModel.swift
//  Chalk That NBA
//
//  Plain-English search (the web's pages/Ask.jsx). A question is sent as
//  `{ q }`; removing a chip or picking a clarification re-sends the
//  edited plan as `{ plan }` (no model call, free). 429 / 503 / 422 come
//  back with a message the error card shows.
//
import Foundation
import Combine

@MainActor
final class AskViewModel: ObservableObject {
    enum Request: Hashable {
        case question(String)
        case plan(JSONValue)
    }

    @Published var text = ""
    @Published private(set) var request: Request?
    @Published private(set) var answer: AskAnswer?
    @Published private(set) var plan: JSONValue?
    @Published private(set) var answeredRequest: Request?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    var isCurrent: Bool { request != nil && answeredRequest == request }

    func ask(_ question: String? = nil) {
        let q = (question ?? text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return }
        text = q
        request = .question(String(q.prefix(300)))
    }

    func removeChip(_ chip: AskChip) {
        guard let plan else { return }
        request = .plan(plan.removing(chip.key))
    }

    func pick(_ option: AskClarify.Option, field: String) {
        guard let plan else { return }
        request = .plan(plan.setting(field, to: option.name))
    }

    /// The view's `.task(id: request)`.
    func load() async {
        guard let requested = request else { return }
        isLoading = true
        error = nil
        do {
            let body: Data
            switch requested {
            case .question(let q): body = try JSONEncoder().encode(["q": q])
            case .plan(let p): body = try JSONEncoder().encode(["plan": p])
            }
            let data = try await APIClient.shared.requestData(path: Endpoints.ask, method: "POST", bodyData: body)
            let decoded: AskAnswer
            let raw: AskRawPlan
            do {
                decoded = try JSONDecoder.chalkThatNBA.decode(AskAnswer.self, from: data)
                raw = try JSONDecoder().decode(AskRawPlan.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
            guard requested == request else { return }
            answer = decoded
            plan = raw.plan
            answeredRequest = requested
        } catch {
            guard requested == request else { return }
            if !Task.isCancelled { self.error = error }
        }
        isLoading = false
    }
}
