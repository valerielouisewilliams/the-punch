//
//  MainTabView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/6/25.
//

import SwiftUI

/**
 This is the bottom navigation bar that lets uses go to their feed, search for friends, and view their profiles.
 */
struct MainTabView: View {
    var body: some View {
        NavigationStack {
            TabView {
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "house.fill")
                    }

                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                UserProfileView(userID: UUID(), isOwnProfile: true)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar) // hides nav bar everywhere
        }
    }
}
