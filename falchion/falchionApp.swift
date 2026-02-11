//
//  falchionApp.swift
//  falchion
//
//  Created by Jo Walsh on 2/11/26.
//

import SwiftUI

@main
struct falchionApp: App {
    @StateObject private var appState = FalchionAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
