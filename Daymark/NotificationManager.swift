import Foundation
import Combine
import UserNotifications

public class NotificationManager: ObservableObject {
    @Published public var isAuthorized = false
    
    public init() {
        checkAuthorizationStatus()
    }
    
    public func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    public func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    public func scheduleNotification(for task: TaskItem) {
        // Cancel existing notification first if any
        cancelNotification(for: task)
        
        let idString = task.id.uuidString
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.notes.isEmpty ? "Reminder for your task" : task.notes
        content.sound = .default
        content.userInfo = ["taskId": idString]
        
        // Handle interval reminders
        if task.isIntervalReminder ?? false,
           let startTime = task.intervalStartTime,
           let endTime = task.intervalEndTime,
           let interval = task.reminderInterval,
           interval > 0 {
            
            task.reminderId = idString
            
            let calendar = Calendar.current
            let currentComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            
            let startMinutes = (currentComponents.hour ?? 9) * 60 + (currentComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 21) * 60 + (endComponents.minute ?? 0)
            
            let totalDuration = startMinutes <= endMinutes ? (endMinutes - startMinutes) : (1440 - startMinutes + endMinutes)
            
            var index = 0
            for offset in stride(from: 0, through: totalDuration, by: interval) {
                let currentMinutes = (startMinutes + offset) % 1440
                let hour = currentMinutes / 60
                let minute = currentMinutes % 60
                
                var triggerComponents = DateComponents()
                triggerComponents.hour = hour
                triggerComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
                let subId = "\(idString)_interval_\(index)"
                let request = UNNotificationRequest(identifier: subId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                index += 1
            }
            return
        }
        
        // Ensure reminder is enabled, and reminder time is set in the future
        guard let reminderTime = task.reminderTime else { return }
        
        let calendar = Calendar.current
        task.reminderId = idString // Update reminderId reference
        
        // Handle recurrence patterns
        if task.isRecurring {
            switch task.recurrencePattern {
            case .none:
                scheduleOneTimeNotification(id: idString, content: content, date: reminderTime)
            case .daily:
                let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: idString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                
            case .weekdays:
                // Schedule individual notifications for Monday (2) through Friday (6)
                let weekdays = [2, 3, 4, 5, 6]
                for day in weekdays {
                    var components = calendar.dateComponents([.hour, .minute], from: reminderTime)
                    components.weekday = day
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    let subId = "\(idString)_weekday_\(day)"
                    let request = UNNotificationRequest(identifier: subId, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                }
                
            case .weekly:
                let components = calendar.dateComponents([.weekday, .hour, .minute], from: reminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: idString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                
            case .monthly:
                let components = calendar.dateComponents([.day, .hour, .minute], from: reminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: idString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        } else {
            // One-time reminder
            scheduleOneTimeNotification(id: idString, content: content, date: reminderTime)
        }
    }
    
    private func scheduleOneTimeNotification(id: String, content: UNMutableNotificationContent, date: Date) {
        guard date > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    public func cancelNotification(for task: TaskItem) {
        let idString = task.id.uuidString
        
        // Remove standard, weekday-specific repeating, and interval requests
        var identifiers = [idString]
        for day in 2...6 {
            identifiers.append("\(idString)_weekday_\(day)")
        }
        for index in 0...100 {
            identifiers.append("\(idString)_interval_\(index)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Test notification trigger helper
    public func triggerInstantTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daymark Test Notification 🔔"
        content.body = "Notifications are working perfectly! You're ready to organize your day."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier: "DaymarkTestNotificationID", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
