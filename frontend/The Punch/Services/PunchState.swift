//
//  PunchState.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/26/25.
//


import Foundation

class PunchState: ObservableObject {
    @Published var isPunchTimeActive = false
    @Published var punchTime: Date? = nil
    @Published var punchId: String? = nil
}
