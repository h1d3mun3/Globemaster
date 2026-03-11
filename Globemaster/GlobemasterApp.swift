//
//  GlobemasterApp.swift
//  Globemaster
//
//  Created by hidemune on 3/11/26.
//

import SwiftUI

@main
struct GlobemasterApp: App {
    private let remapper = KeyRemapper()

    init() {
        if !remapper.start() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Text("左⌘ → 英数 / 右⌘ → かな")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("終了") {
                remapper.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "command.circle.fill")
        }
    }
}
