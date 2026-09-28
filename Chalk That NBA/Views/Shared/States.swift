//
//  States.swift
//  Chalk That NBA
//
//  Port of the web's components/States.jsx: one loading block, one error
//  block (with "Try again"), one empty block, so every screen handles all
//  three the same way. Empty states are designed, never a blank screen
//  (ios-kickoff.md §1.5).
//
import SwiftUI

struct LoadingCard: View {
    var label = "Loading…"

    var body: some View {
        HStack(spacing: 10) {
            ProgressView().tint(Color.muted)
            Text(label)
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}

struct ErrorCard: View {
    let error: Error
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.message(for: error))
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.ink)
            if let onRetry {
                Button("Try again", action: onRetry)
                    .font(.brandBody(.subheadline, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.field, lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accent.opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Same wording as States.jsx `ErrorBox`.
    static func message(for error: Error) -> String {
        switch error {
        case APIError.server(404, _, _):
            return "Not found."
        case APIError.server(let status, _, _) where status >= 500:
            return "The server hit an error. Try again in a moment."
        case APIError.networkError:
            return "Can't reach the server. Check your connection."
        default:
            return (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
        }
    }

    static func isNotFound(_ error: Error) -> Bool {
        if case APIError.server(404, _, _) = error { return true }
        return false
    }
}

struct EmptyCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .font(.brandBody(.subheadline))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.field, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Small uppercase label above a title (the web's `.eyebrow`).
struct Eyebrow: View {
    let text: String
    var color: Color = .muted

    var body: some View {
        Text(text.uppercased())
            .font(.brandBody(.caption, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(color)
    }
}

/// A rounded tag (the web's `rounded-full bg-rule px-2.5 py-1` chips).
struct Chip: View {
    let text: String
    var highlighted = false

    var body: some View {
        Text(text)
            .font(.brandBody(.footnote))
            .foregroundStyle(highlighted ? Color.altInk : Color.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(highlighted ? Color.altBg : Color.rule)
            .clipShape(Capsule())
    }
}
