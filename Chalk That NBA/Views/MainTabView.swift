//
//  MainTabView.swift
//  Chalk That NBA
//
//  Five tabs (kickoff decision 2026-09-28): Scores · Players · Leaders ·
//  Props · League. League holds Standings, Teams, Rankings, Guide and
//  Sign out. Ask is a nav-bar button on every tab, so the tab bar doesn't
//  depend on it. Each tab owns its NavigationStack (the NFL pattern), so
//  a push in one tab doesn't affect another.
//
//  Screens not built yet are placeholders that name their build step.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            tab { ScoreboardView() }
                .tabItem { Label("Scores", systemImage: "sportscourt") }

            tab { PlayersView() }
                .tabItem { Label("Players", systemImage: "person.2") }

            tab { LeadersView() }
                .tabItem { Label("Leaders", systemImage: "list.number") }

            tab { PropsBoardView() }
                .tabItem { Label("Props", systemImage: "chart.bar.xaxis") }

            tab { LeagueView() }
                .tabItem { Label("League", systemImage: "trophy") }
        }
        .tint(Color.accent)
    }

    /// A tab root: its own NavigationStack, the brand nav bar, and the Ask button.
    private func tab<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationStack {
            content()
                .appDestinations()
                .brandNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(value: AppRoute.ask) {
                            Image(systemName: "text.magnifyingglass")
                        }
                        .accessibilityLabel("Ask")
                    }
                }
        }
        // Tab bar styling has to sit on the tab's content, not the TabView.
        .toolbarBackground(Color.card, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
