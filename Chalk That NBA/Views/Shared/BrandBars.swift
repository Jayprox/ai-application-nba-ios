//
//  BrandBars.swift
//  Chalk That NBA
//
//  Nav bar styling for every tab's NavigationStack root: `card` background
//  (the web header), always visible, dark.
//
import SwiftUI

extension View {
    func brandNavigationBar() -> some View {
        self
            .toolbarBackground(Color.card, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
