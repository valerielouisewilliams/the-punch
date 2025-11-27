//
//  NotificationManager.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/26/25.
//


import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    // Keys for UserDefaults
    private let punchTimeKey = "punchTimeDate"
    private let punchTimeIdKey = "punchTimeId"
    private let punchDayKey = "punchDay"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("Permission error:", error.localizedDescription)
            } else {
                print("Notifications permission granted:", granted)
            }
        }
    }
    
    // MARK: - Random Punch Time Generator
    func generateRandomPunchTime() -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        
        // Random time between 9am and 11pm
        let randomHour = Int.random(in: 9...23)
        let randomMinute = Int.random(in: 0..<60)
        
        components.hour = randomHour
        components.minute = randomMinute
        
        // Next instance of that time (today or tomorrow if past)
        let nextDate = Calendar.current.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )!
        
        return nextDate
    }
    
    // MARK: - Schedule Today’s Punch
    func scheduleTodayPunch(forceNew: Bool = false) {
        
        let today = Calendar.current.component(.day, from: Date())
        let savedDay = UserDefaults.standard.integer(forKey: punchDayKey)
        
        // If we already scheduled for today and not forcing a new one, skip
        if savedDay == today && !forceNew {
            print("Already scheduled today's Punch notification")
            return
        }
        
        // Generate a new punch time
        let punchDate = generateRandomPunchTime()
        let id = UUID().uuidString
        
        print("Scheduled Punch at:", punchDate)
        
        // Store metadata
        UserDefaults.standard.set(punchDate, forKey: punchTimeKey)
        UserDefaults.standard.set(id, forKey: punchTimeIdKey)
        UserDefaults.standard.set(today, forKey: punchDayKey)
        
        // Schedule local notification
        scheduleLocalNotification(at: punchDate)
    }
    
    // MARK: - Scheduling Local Notifications
    func scheduleLocalNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        
        // Remove previous Punch notifications
        center.removePendingNotificationRequests(withIdentifiers: ["dailyPunch"])
        
        let content = UNMutableNotificationContent()
        content.title = "It’s Punch Time! 🥊"
        content.body = "Share your moment with everyone right now!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "dailyPunch",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { err in
            if let err = err {
                print("Failed to schedule punch:", err.localizedDescription)
            } else {
                print("Daily Punch notification scheduled!")
            }
        }
    }
    
    // MARK: - Debug Helpers
    func scheduleTestNotification(seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "TEST PUNCH 🔥"
        content.body = "This is a 5-second test notification."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "testPunch", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(req)
        print("🧪 Test notification scheduled for \(seconds)s")
    }
    
    // MARK: - Getters
    func getTodayPunchTime() -> Date? {
        return UserDefaults.standard.object(forKey: punchTimeKey) as? Date
    }
    
    func getTodayPunchId() -> String? {
        return UserDefaults.standard.string(forKey: punchTimeIdKey)
    }
    
    // MARK: - Notification Tapped / Delivered
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.identifier == "dailyPunch" {
            NotificationCenter.default.post(name: .punchTimeTriggered, object: nil)
        }
        
        completionHandler()
    }
}

// MARK: - NotificationCenter Support
extension Notification.Name {
    static let punchTimeTriggered = Notification.Name("punchTimeTriggered")
}
