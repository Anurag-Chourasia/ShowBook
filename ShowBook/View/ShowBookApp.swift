//
//  ShowBookApp.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

@main
struct ShowBookApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
