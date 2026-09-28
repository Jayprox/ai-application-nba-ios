//
//  AskView.swift
//  Chalk That NBA
//
//  Plain-English search (the web's pages/Ask.jsx), opened from the
//  magnifier in every tab's nav bar. Eyebrow "Plain English · verified
//  numbers"; a search box with example questions; the answer = sentence
//  (from the API's template, never the model) + clarify buttons +
//  removable filter chips + a view by `view.type` + "Open the full view"
//  mapped to the native screen.
//
import SwiftUI

struct AskView: View {
    @StateObject private var vm = AskViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Plain English · verified numbers")
                    Text("Ask")
                        .font(.brandDisplay(32, weight: .bold, relativeTo: .largeTitle))
                        .foregroundStyle(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                searchBox
                content
            }
            .padding(16)
        }
        .background(Color.paper)
        .navigationTitle("Ask")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task(id: vm.request) { await vm.load() }
        .onAppear { if vm.request == nil { focused = true } }
    }

    private var searchBox: some View {
        HStack(spacing: 8) {
            TextField("", text: $vm.text, prompt: Text("Ask anything: \"Jokić on back-to-backs\"…").foregroundColor(.faint))
                .font(.brandBody(.body))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($focused)
                .onSubmit { vm.ask() }
                .onChange(of: vm.text) { if $0.count > 300 { vm.text = String($0.prefix(300)) } }
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(focused ? Color.link : Color.field, lineWidth: focused ? 2 : 1))
                .accessibilityLabel("Ask a stats question")
            Button {
                focused = false
                vm.ask()
            } label: {
                Text("Ask")
                    .font(.brandBody(.body, weight: .semibold))
                    .foregroundStyle(Color.onAccent)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 48)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(vm.text.trimmingCharacters(in: .whitespaces).count < 2)
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.request == nil {
            examples
        } else if vm.isCurrent, let answer = vm.answer {
            AnswerView(answer: answer, vm: vm, examples: examples)
        } else if let error = vm.error {
            ErrorCard(error: error) { Task { await vm.load() } }
        } else {
            LoadingCard(label: "Looking it up…")
        }
    }

    private var examples: some View {
        EmptyCard {
            Text("Try:")
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(AskText.examples, id: \.self) { example in
                    Button {
                        focused = false
                        vm.ask(example)
                    } label: {
                        Text(example)
                            .font(.brandBody(.subheadline))
                            .foregroundStyle(Color.link)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .overlay(Capsule().stroke(Color.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AnswerView<Examples: View>: View {
    let answer: AskAnswer
    @ObservedObject var vm: AskViewModel
    let examples: Examples

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(answer.sentence)
                .font(.brandDisplay(26, weight: .bold, relativeTo: .title))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let clarify = answer.clarify {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(clarify.options, id: \.self) { option in
                        Button { vm.pick(option, field: clarify.field) } label: {
                            Text(option.name)
                                .font(.brandBody(.body, weight: .medium))
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 40)
                                .background(Color.card)
                                .overlay(Capsule().stroke(Color.field, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let chips = answer.chips, !chips.isEmpty {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(chips, id: \.self) { chip in chipView(chip) }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Filters used")
            }

            if let display = answer.view {
                AskDisplayView(display: display, season: answer.season, examples: examples)
            }

            VStack(alignment: .leading, spacing: 8) {
                Rectangle().fill(Color.line).frame(height: 1)
                Text("Numbers from Chalk That's database (NBA.com box scores\(isProps ? ", DraftKings lines" : "")). Claude only picked the query\(answer.cached == true ? " (cached)" : "").")
                    .font(.brandBody(.footnote))
                    .foregroundStyle(Color.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let route = WebLink.route(answer.link) {
                    NavigationLink(value: route) {
                        Text("Open the full view →")
                            .font(.brandBody(.subheadline, weight: .semibold))
                            .foregroundStyle(Color.link)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isProps: Bool {
        if case .props = answer.view { return true }
        return false
    }

    private func chipView(_ chip: AskChip) -> some View {
        HStack(spacing: 4) {
            Text(chip.label)
                .font(.brandBody(.subheadline))
                .foregroundStyle(Color.ink)
            if chip.removable != false {
                Button { vm.removeChip(chip) } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.muted)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(chip.label)")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, chip.removable != false ? 4 : 12)
        .frame(minHeight: 32)
        .background(Color.card)
        .overlay(Capsule().stroke(Color.line, lineWidth: 1))
    }
}
