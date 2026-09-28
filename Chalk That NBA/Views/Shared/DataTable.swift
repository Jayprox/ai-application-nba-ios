//
//  DataTable.swift
//  Chalk That NBA
//
//  A stats table with the first column pinned while the rest scrolls
//  sideways (the web's `sticky left-0` tables): career and game logs, and
//  later leaders/rankings. A row can link somewhere (its pinned cell
//  turns link-blue, like the web's date links), and an optional footer
//  row (Career / All seasons) sits under a heavy rule.
//
//  VoiceOver reads each row once, from the pinned cell's label; the
//  scrolling grid is hidden from it.
//
import SwiftUI

struct DataTable: View {
    struct Column {
        let title: String
        let width: CGFloat
        var leading = false
        var bold = false
        var muted = false
    }

    struct Row: Identifiable {
        let id: String
        let pinned: String
        let cells: [String]
        var route: AppRoute?
        var spoken: String
        /// Muted text before the pinned text (a rank: "1  Celtics").
        var prefix: String?
        /// Accent text after it (a clinch mark: "Celtics x").
        var suffix: String?
        /// Whole row muted (below the play-in line).
        var muted = false
        /// Faint band (play-in seeds).
        var shaded = false
        /// Heavy rule under the row (a playoff / play-in cut line).
        var heavyBottom = false
        /// A small muted second line under each cell (a rank, a z-score).
        var subcells: [String]?
        /// Muted text after the pinned text (a team: "Nikola Jokić DEN").
        var detail: String?
    }

    let pinnedTitle: String
    var pinnedWidth: CGFloat = 96
    let columns: [Column]
    let rows: [Row]
    var footer: Row?

    @ScaledMetric(relativeTo: .subheadline) private var baseRowHeight: CGFloat = 36

    /// Rows grow to fit a second line when any row has one.
    private var rowHeight: CGFloat {
        rows.contains { $0.subcells != nil } || footer?.subcells != nil ? baseRowHeight * 1.45 : baseRowHeight
    }
    @ScaledMetric(relativeTo: .subheadline) private var unit: CGFloat = 1

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            pinnedColumn
                .frame(width: pinnedWidth * unit)
                .overlay(alignment: .trailing) { Rectangle().fill(Color.line).frame(width: 1) }
            ScrollView(.horizontal, showsIndicators: false) {
                grid
            }
            .accessibilityHidden(true)
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var pinnedColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(pinnedTitle, leading: true)
                .padding(.horizontal, 12)
                .overlay(alignment: .bottom) { heavyRule }
            ForEach(rows) { row in
                pinnedCell(row, bold: false)
                    .background(row.shaded ? Color.rule.opacity(0.4) : Color.clear)
                    .overlay(alignment: .bottom) { row.heavyBottom ? AnyView(heavyRule) : AnyView(rule) }
            }
            if let footer {
                pinnedCell(footer, bold: true)
                    .overlay(alignment: .top) { heavyRule }
            }
        }
    }

    @ViewBuilder
    private func pinnedCell(_ row: Row, bold: Bool) -> some View {
        let color: Color = row.route != nil ? .link : (row.muted ? .muted : .ink)
        let text = HStack(spacing: 6) {
            if let prefix = row.prefix {
                Text(prefix)
                    .foregroundStyle(Color.muted)
                    .frame(minWidth: 18, alignment: .leading)
            }
            Text(row.pinned)
                .fontWeight(bold ? .semibold : (row.prefix != nil ? .medium : .regular))
                .foregroundStyle(color)
                .lineLimit(1)
            if let detail = row.detail {
                Text(detail)
                    .font(.brandBody(.caption))
                    .foregroundStyle(Color.muted)
            }
            if let suffix = row.suffix {
                Text(suffix)
                    .font(.brandBody(.caption, weight: .semibold))
                    .foregroundStyle(Color.accent)
            }
        }
        .font(.brandBody(.subheadline))
        .monospacedDigit()
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
        if let route = row.route {
            NavigationLink(value: route) {
                text.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(row.spoken)
            .accessibilityAddTraits(.isButton)
        } else {
            text
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.spoken)
        }
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    header(column.title, leading: column.leading)
                        .frame(width: column.width * unit, alignment: column.leading ? .leading : .trailing)
                        .padding(.horizontal, 6)
                }
            }
            .padding(.trailing, 6)
            .overlay(alignment: .bottom) { heavyRule }

            ForEach(rows) { row in
                cells(row, bold: false)
                    .background(row.shaded ? Color.rule.opacity(0.4) : Color.clear)
                    .overlay(alignment: .bottom) { row.heavyBottom ? AnyView(heavyRule) : AnyView(rule) }
            }
            if let footer {
                cells(footer, bold: true)
                    .overlay(alignment: .top) { heavyRule }
            }
        }
    }

    private func cells(_ row: Row, bold: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                VStack(alignment: column.leading ? .leading : .trailing, spacing: 1) {
                    Text(index < row.cells.count ? row.cells[index] : "")
                        .font(column.muted ? .brandBody(.footnote) : .brandBody(.subheadline, weight: bold || column.bold ? .semibold : .regular))
                        .foregroundStyle(column.muted || row.muted ? Color.muted : Color.ink)
                    if let sub = row.subcells, index < sub.count, !sub[index].isEmpty {
                        Text(sub[index])
                            .font(.brandBody(.caption2))
                            .foregroundStyle(Color.muted)
                    }
                }
                .monospacedDigit()
                .lineLimit(1)
                .frame(width: column.width * unit, alignment: column.leading ? .leading : .trailing)
                .padding(.horizontal, 6)
            }
        }
        .padding(.trailing, 6)
        .frame(height: rowHeight)
    }

    private func header(_ title: String, leading: Bool) -> some View {
        Text(title.uppercased())
            .font(.brandBody(.caption, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.muted)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: leading ? .leading : .trailing)
    }

    private var rule: some View { Rectangle().fill(Color.rule).frame(height: 1) }
    private var heavyRule: some View { Rectangle().fill(Color.strong).frame(height: 2) }
}
