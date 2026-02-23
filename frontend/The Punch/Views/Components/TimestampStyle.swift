//
//  TimestampStyle.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/23/26.
//


import Foundation

enum TimestampStyle {
    case relative   // "2m ago", "3h ago"
    case smart      // "2m ago", "Yesterday", "Feb 22"
    case full       // "Feb 22 • 4:39 PM"
}

final class TimestampFormatter {
    static let shared = TimestampFormatter()

    private let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let isoNoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated // "2m ago"
        return f
    }()

    private let full: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d • h:mm a"
        return f
    }()

    private let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    func parseISO(_ s: String) -> Date? {
        isoWithFractional.date(from: s) ?? isoNoFractional.date(from: s)
    }

    func format(_ isoString: String, style: TimestampStyle = .smart) -> String {
        guard let date = parseISO(isoString) else { return isoString }

        switch style {
        case .relative:
            return relative.localizedString(for: date, relativeTo: Date())

        case .full:
            return full.string(from: date)

        case .smart:
            let now = Date()
            let seconds = now.timeIntervalSince(date)

            if seconds < 60 * 60 * 6 { // < 6 hours → relative feels best
                return relative.localizedString(for: date, relativeTo: now)
            }

            if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            }

            if Calendar.current.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                // This week → show day + time
                return full.string(from: date)
            }

            // Older → month/day
            return dayMonth.string(from: date)
        }
    }
}
