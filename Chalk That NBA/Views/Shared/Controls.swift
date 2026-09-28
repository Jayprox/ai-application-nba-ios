//
//  Controls.swift
//  Chalk That NBA
//
//  The web's components/Controls.jsx: toggle pills (one value selected)
//  and underlined tabs (the scope switcher). Selected = accent fill /
//  accent underline, as on the web.
//
import SwiftUI

/// A row of toggle pills; scrolls sideways when it doesn't fit.
struct Pills: View {
    let label: String
    let options: [(value: String, label: String)]
    let selected: String
    var small = false
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.value) { option in
                    let on = option.value == selected
                    Button {
                        onSelect(option.value)
                    } label: {
                        Text(option.label)
                            .font(.brandBody(small ? .subheadline : .body, weight: .medium))
                            .foregroundStyle(on ? Color.onAccent : Color.ink)
                            .padding(.horizontal, small ? 12 : 16)
                            .frame(minHeight: small ? 36 : 40)
                            .background(on ? Color.accent : Color.card)
                            .overlay(Capsule().stroke(on ? Color.accent : Color.field, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label): \(option.label)")
                    .accessibilityAddTraits(on ? [.isSelected] : [])
                }
            }
            .padding(.vertical, 1)
        }
    }
}

/// Underlined tabs; scrolls sideways on small phones.
struct UnderlineTabs: View {
    let options: [(value: String, label: String)]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(options, id: \.value) { option in
                    let on = option.value == selected
                    Button {
                        onSelect(option.value)
                    } label: {
                        Text(option.label)
                            .font(.brandBody(.body, weight: .semibold))
                            .foregroundStyle(on ? Color.ink : Color.muted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(on ? Color.accent : Color.clear).frame(height: 3)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? [.isSelected, .isButton] : [.isButton])
                }
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Color.line).frame(height: 1) }
    }
}

/// Section label the web writes as `<h3 className="eyebrow">`.
struct SectionLabel: View {
    let text: String
    var body: some View { Eyebrow(text: text).accessibilityAddTraits(.isHeader) }
}
