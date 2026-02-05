//
//  EditProfileView.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/24/25.
//


import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    private let baseURL = URL(string: "http://3.130.171.129:3000/api")!

    let user: User
    var onProfileUpdated: ((User) -> Void)? = nil
    
    @State private var displayName: String
    @State private var bio: String
    @State private var selectedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(user: User, onProfileUpdated: ((User) -> Void)? = nil) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _bio = State(initialValue: user.bio ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Profile picture picker
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let avatarUrl = user.avatarUrl,
                              let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(user.username.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Circle()
                        .strokeBorder(Color.orange, lineWidth: 3)
                        .frame(width: 100, height: 100)
                }
            }
            .onChange(of: pickerItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    do {
                        if let data = try await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    } catch {
                        print("Image pick error:", error)
                    }
                }
            }
            
            // Display name
            TextField("Display Name", text: $displayName)
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(.white)
            
            // Bio
            TextEditor(text: $bio)
                .frame(height: 120)
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(.white)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button {
                Task { await saveChanges() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Save Changes")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.95, green: 0.60, blue: 0.20))
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(isSaving)
            
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveChanges() async {
        guard !isSaving else { return }

        await MainActor.run {
            isSaving = true
            errorMessage = nil
        }

        // New auth flow: get Firebase ID token on-demand
        let token: String
        do {
            token = try await authManager.firebaseIdToken()
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "You’re not logged in. Please sign in again."
            }
            return
        }

        var avatarURL: String? = user.avatarUrl

        // If user picked a new image, upload to S3 via presigned URL
        if let selectedImage {
            do {
                let uploadedUrl = try await S3AvatarUploader.uploadAvatar(
                    selectedImage,
                    apiBaseURL: baseURL,
                    token: token
                )
                avatarURL = uploadedUrl
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to upload image."
                }
                print("S3 upload error:", error)
                return
            }
        }

        do {
            let response = try await APIService.shared.updateUserProfile(
                displayName: displayName,
                bio: bio,
                avatarUrl: avatarURL,
                token: token
            )

            let updatedUser = response.data

            await MainActor.run {
                authManager.currentUser = updatedUser
                onProfileUpdated?(updatedUser)
                isSaving = false
                dismiss()

                NotificationCenter.default.post(
                    name: .userProfileDidUpdate,
                    object: nil,
                    userInfo: [
                        "id": updatedUser.id,
                        "displayName": updatedUser.displayName,
                        "bio": updatedUser.bio ?? "",
                        "avatarUrl": updatedUser.avatarUrl ?? ""
                    ]
                )
            }
        } catch {
            await MainActor.run {
                
                isSaving = false
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription ?? "Failed to update profile."
                } else {
                    errorMessage = "Failed to update profile."
                }
            }
            print("Update profile error:", error)
        }
    }
}
