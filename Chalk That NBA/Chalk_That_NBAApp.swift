//
//  Chalk_That_NBAApp.swift
//  Chalk That NBA
//
//  Entry point: Login or the tab shell, off AuthViewModel.isAuthenticated.
//  Same shape as the NFL app.
//
import SwiftUI

@main
struct Chalk_That_NBAApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.isRunningUnitTests {
                    // Unit tests use this app as their host. Show nothing, so
                    // no screen makes real requests while tests stub the network.
                    Color.paper
                } else if auth.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .preferredColorScheme(.dark) // dark is the only theme, as on the web
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private static let isRunningUnitTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
