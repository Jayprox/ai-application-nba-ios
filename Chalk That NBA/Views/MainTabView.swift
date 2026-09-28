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
//  Step 1: every screen is a placeholder that names its build step.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            tab { ComingSoonView(title: "Scores", step: "step 2") }
                .tabItem { Label("Scores", systemImage: "sportscourt") }

            tab { ComingSoonView(title: "Players", step: "step 3") }
                .tabItem { Label("Players", systemImage: "person.2") }

            tab { ComingSoonView(title: "Leaders", step: "step 5") }
                .tabItem { Label("Leaders", systemImage: "list.number") }

            tab { ComingSoonView(title: "Props", step: "step 6") }
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
                .brandNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            ComingSoonView(title: "Ask", step: "step 7")
                        } label: {
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
