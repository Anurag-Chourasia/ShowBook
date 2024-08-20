//
//  ContentView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    var body: some View {
            if userViewModel.isLoggedIn {
                DashboardView()
                    .tag(1)
                    .environmentObject(userViewModel)
                    .environmentObject(DashboardViewModel())
            } else {
                LandingView()
                    .tag(2)
                    .environmentObject(userViewModel)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserViewModel())
            .navigationViewStyle(StackNavigationViewStyle())
    }
}
