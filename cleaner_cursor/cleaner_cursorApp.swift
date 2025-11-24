//
//  cleaner_cursorApp.swift
//  cleaner_cursor
//
//  Created by Nikita on 24.11.2025.
//

import SwiftUI

@main
struct cleaner_cursorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
