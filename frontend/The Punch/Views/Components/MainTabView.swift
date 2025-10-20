//
//  MainTabView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var showComposer = false
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            TabView {
                FeedView()
                    .tabItem { Label("Feed", systemImage: "house.fill") }

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }

                if let user = auth.currentUser {
                    UserProfileView(userId: user.id)
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                }
                    
            }
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)

            // Floating Create button for posts
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showComposer = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(red: 0.95, green: 0.60, blue: 0.20))
                            .clipShape(Circle())
                            .shadow(radius: 8, y: 4)
                    }
                    Spacer()
                }
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showComposer) {
            CreatePunchView(onPosted: { _ in
                //TODO: add code to refresh feed here
            })
        }
        
    }

}
