//
//  SpotifySearchView.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/20/26.
//


import SwiftUI

struct SpotifySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SpotifySearchViewModel()

    let onSelect: (SpotifyTrack) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Search for a song", text: $viewModel.query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            Task {
                                await viewModel.search()
                            }
                        }

                    Button("Search") {
                        Task {
                            await viewModel.search()
                        }
                    }
                }
                .padding()

                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List(viewModel.tracks) { track in
                    Button {
                        onSelect(track)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: track.album_image ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(track.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}