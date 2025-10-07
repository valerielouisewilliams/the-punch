//
//  SearchView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 The view that allows users to search for people that they want to follow.
 */
struct SearchView: View {
    @State private var query = ""
    @State private var results: [User] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Search Bar
                    HStack {
                        Button(action: {
                            // back navigation (if needed)
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        SearchBar(text: $query, placeholder: "Search for friends")
                            .focused($isFocused)
                            .onSubmit { Task { await performSearch() } }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Results Section
                    if results.isEmpty {
                        Text("Recent")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                    } else {
                        ScrollView {
                            ForEach(results) { user in
                                UserRow(user: user)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
        .onChange(of: query) { _ in
            Task { await performSearch() }
        }
    }
    
    // TODO: implement this when we connect the backend
    func performSearch() async {

    }
}
