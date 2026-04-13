//
//  MnemosyneApp.swift
//  Mnemosyne
//
//  Created by Hamann, Falko on 13.04.26.
//

import SwiftUI

@main
struct MnemosyneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
