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
        
        NavigationView {
            
            VStack(alignment: .center, spacing: 0){
                
                headerView
                
                Spacer()
                
                logoView
                
                Spacer()
                
                navigationButtons
                
            }
            .navigationBarBackButtonHidden()
            .navigationViewStyle(StackNavigationViewStyle())
        }
       
    }

    private var headerView: some View {
        HStack {
            Spacer()
            VStack{
                Text("Show Book")
                    .font(.largeTitle)
            }
            Spacer()
        }
        .padding(.top, 50)
    }

    private var logoView: some View {
        GeometryReader { geo in
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geo.size.width - 80, 400), height: geo.size.height)
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
                    .font(.headline)
                    .frame(width: 80)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            NavigationLink(destination: LoginView()) {
                Text("Login")
                    .font(.headline)
                    .frame(width: 80)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.bottom, 50)
    }
}

#Preview {
    LandingView()
        .environmentObject(UserViewModel())
        .navigationViewStyle(StackNavigationViewStyle())
}
