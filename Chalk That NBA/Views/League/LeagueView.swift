//
//  LeagueView.swift
//  Chalk That NBA
//
//  The League tab: the web sections that don't get their own tab
//  (Standings, Teams, Rankings), the Guide, and Sign out.
//
import SwiftUI

struct LeagueView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var confirmingSignOut = false

    var body: some View {
        List {
            Section {
                row("Standings", icon: "list.number") { StandingsView() }
                row("Teams", icon: "person.3") { TeamsView() }
                row("Rankings", icon: "chart.line.uptrend.xyaxis") { RankingsView() }
            }
            .listRowBackground(Color.card)

            Section {
                row("Guide", icon: "questionmark.circle") { GuideView() }
            }
            .listRowBackground(Color.card)

            Section {
                Button(role: .destructive) {
                    confirmingSignOut = true
                } label: {
                    Text("Sign out")
                        .font(.brandBody(.body, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
            } footer: {
                if let username = auth.username {
                    Text("Signed in as \(username)")
                        .font(.brandBody(.footnote))
                        .foregroundStyle(Color.muted)
                }
            }
            .listRowBackground(Color.card)
        }
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .navigationTitle("League")
        .confirmationDialog("Sign out of Chalk That Hardwood?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await auth.logout() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func row<Destination: View>(_ title: String, icon: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            Label {
                Text(title)
                    .font(.brandBody(.body))
                    .foregroundStyle(Color.ink)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(Color.muted)
            }
        }
    }
}
