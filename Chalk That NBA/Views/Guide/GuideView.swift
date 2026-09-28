//
//  GuideView.swift
//  Chalk That NBA
//
//  The in-app user guide (GuideContent), with jump links to each section
//  like the web's Guide page. Reached from the League tab.
//
import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "How to use Chalk That NBA")
                        Text("Guide")
                            .font(.brandDisplay(32, weight: .bold, relativeTo: .largeTitle))
                            .foregroundStyle(Color.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(GuideContent.intro)
                        .font(.brandBody(.subheadline))
                        .foregroundStyle(Color.muted)

                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(GuideContent.sections) { section in
                            Button {
                                withAnimation { proxy.scrollTo(section.id, anchor: .top) }
                            } label: {
                                Text(section.title)
                                    .font(.brandBody(.footnote, weight: .medium))
                                    .foregroundStyle(Color.muted)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.card)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)

                    ForEach(GuideContent.sections) { section in
                        sectionView(section).id(section.id)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.paper)
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(_ section: GuideSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(Color.line).frame(height: 1).padding(.bottom, 8)
            Text(section.title)
                .font(.brandDisplay(24, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let text):
                    Self.markdown(text)
                case .terms(let items):
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(items, id: \.term) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.term)
                                    .font(.brandBody(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.ink)
                                Self.markdown(item.definition)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    /// Muted body text with **bold** in ink, as the web's <B>.
    static func markdown(_ text: String) -> some View {
        var attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.stronglyEmphasized) {
                attributed[run.range].foregroundColor = .ink
            }
        }
        return Text(attributed)
            .font(.brandBody(.subheadline))
            .foregroundStyle(Color.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}
