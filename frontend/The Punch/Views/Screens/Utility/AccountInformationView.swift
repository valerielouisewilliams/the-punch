//
//  AccountInformationView.swift
//  ThePunch
//
//  Created by Valerie Williams on 4/1/26.
//


import SwiftUI

struct AccountInformationView: View {
    let user: User
    var onUserUpdated: ((User) -> Void)? = nil

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10)
                .ignoresSafeArea()

            List {
                Section("Email") {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)

                        Text(user.email ?? "Unavailable")
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                    }
                }

                Section("Phone Number") {
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.secondary)

                        Text(user.phoneNumber ?? "Unavailable")
                            .foregroundColor(.white)
                    }
                    Text("Phone number editing is temporarily unavailable.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Security") {
                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.secondary)
                            Text("Change Password")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
        }
        .navigationTitle("Account Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func normalizedPhone(_ value: String) -> String {
        value.filter(\.isNumber)
    }
}
