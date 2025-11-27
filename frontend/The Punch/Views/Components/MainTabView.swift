//
//  MainTabView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var showComposer = false
    @State private var selectedTab = 0
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var uiState: UIState

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem { Label("Feed", systemImage: "house.fill") }
                    .tag(0)

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(1)

                if let user = auth.currentUser {
//                    UserProfileView(userId: user.id)
//                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
//                        .tag(2)
                    NavigationStack {
                        UserProfileView(userId: user.id)
                    }
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(2)
                }
            }
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)

            if uiState.showFloatingButton {
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
                                .accessibilityLabel("Create post")
                        }
                        Spacer()
                    }
                }
                .padding(.bottom, 60)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .sheet(isPresented: $showComposer) {
            CreatePunchView(onPosted: { _ in /* refresh feed if needed */ })
        }
    }
}
