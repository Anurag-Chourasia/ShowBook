import DesignTokensKit
//
//  LandingView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import CoreData

struct LandingView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        
        NavigationStack {
            
            VStack(alignment: .center, spacing: DesignMetric.p0){
                
                headerView
                
                Spacer()
                
                logoView
                
                Spacer()
                
                navigationButtons
                
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ShowBookDeveloperView()) {
                        Label("Know Your Developer", systemImage: "person.crop.circle")
                    }
                }
            }
        }
       
    }

    private var headerView: some View {
        HStack {
            Spacer()
            VStack{
                Text("Show Book")
                    .font(Typography.largeTitle)
            }
            Spacer()
        }
        .padding(.top, DesignMetric.p50)
    }

    private var logoView: some View {
        GeometryReader { geo in
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geo.size.width - DesignMetric.p80, DesignMetric.p400), height: geo.size.height)
                    .clipShape(Circle())
            }
            .frame(width: geo.size.width, alignment: .center)
        }
    }


    private var navigationButtons: some View {
        HStack {
            Spacer()
            
            NavigationLink(destination: SignUpView()) {
                Text("Sign Up")
                    .font(Typography.headline)
                    .frame(minWidth: DesignMetric.p80)
                    .padding(.all, Spacing.system)
                    .background(DesignColor.blue)
                    .foregroundColor(DesignColor.white)
                    .cornerRadius(DesignMetric.p8)
            }
            
            Spacer()
            
            NavigationLink(destination: LoginView()) {
                Text("Login")
                    .font(Typography.headline)
                    .frame(minWidth: DesignMetric.p80)
                    .padding(.all, Spacing.system)
                    .background(DesignColor.green)
                    .foregroundColor(DesignColor.white)
                    .cornerRadius(DesignMetric.p8)
            }
            
            Spacer()
        }
        .padding(.bottom, DesignMetric.p50)
    }
}

#Preview {
    LandingView()
        .environmentObject(UserViewModel())
}
