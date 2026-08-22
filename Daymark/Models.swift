import Foundation
import SwiftData

@Model
final public class Category: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var iconName: String
    public var hexColor: String
    
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.category)
    public var tasks: [TaskItem] = []
    
    public init(id: UUID = UUID(), name: String, iconName: String, hexColor: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.hexColor = hexColor
    }
    
    // Default categories helper
    public static var defaultCategories: [Category] {
        [
            Category(name: "Personal", iconName: "person.fill", hexColor: "#4A90E2"),
            Category(name: "Work", iconName: "briefcase.fill", hexColor: "#FF5E5B"),
            Category(name: "Study", iconName: "book.fill", hexColor: "#F5A623"),
            Category(name: "Shopping", iconName: "cart.fill", hexColor: "#2ECC71")
        ]
    }
}

@Model
final public class Subtask: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var task: TaskItem?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

@Model
final public class TaskItem: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String
    public var dueDate: Date
    public var hasTime: Bool
    public var priorityRaw: String
    public var isCompleted: Bool
    public var completionDate: Date?
    public var isRecurring: Bool
    public var recurrencePatternRaw: String
    public var reminderTime: Date?
    public var reminderId: String?
    public var createdAt: Date
    public var isIntervalReminder: Bool? = false
    public var intervalStartTime: Date?
    public var intervalEndTime: Date?
    public var reminderInterval: Int?
    
    public var category: Category?
    
    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    public var subtasks: [Subtask] = []
    
    // Computed property for priority
    public var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    // Computed property for recurrence pattern
    public var recurrencePattern: RecurrencePattern {
        get { RecurrencePattern(rawValue: recurrencePatternRaw) ?? .none }
        set { recurrencePatternRaw = newValue.rawValue }
    }
    
    // Computed helper to check if task is overdue
    public var isOverdue: Bool {
        guard !isCompleted else { return false }
        
        let now = Date()
        if hasTime {
            return dueDate < now
        } else {
            // If it doesn't have a specific time, it is overdue if the due date day has passed.
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let startOfDueDate = calendar.startOfDay(for: dueDate)
            return startOfDueDate < startOfToday
        }
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date = Date(),
        hasTime: Bool = false,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        completionDate: Date? = nil,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern = .none,
        reminderTime: Date? = nil,
        reminderId: String? = nil,
        category: Category? = nil,
        createdAt: Date = Date(),
        isIntervalReminder: Bool = false,
        intervalStartTime: Date? = nil,
        intervalEndTime: Date? = nil,
        reminderInterval: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.priorityRaw = priority.rawValue
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.isRecurring = isRecurring
        self.recurrencePatternRaw = recurrencePattern.rawValue
        self.reminderTime = reminderTime
        self.reminderId = reminderId
        self.category = category
        self.createdAt = createdAt
        self.isIntervalReminder = isIntervalReminder
        self.intervalStartTime = intervalStartTime
        self.intervalEndTime = intervalEndTime
        self.reminderInterval = reminderInterval
    }
    
    // Computed property to calculate the next upcoming interval reminder time
    public var nextIntervalReminderTime: Date? {
        guard let isInterval = isIntervalReminder, isInterval,
              let startTime = intervalStartTime,
              let endTime = intervalEndTime,
              let interval = reminderInterval,
              interval > 0 else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        let currentComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (currentComponents.hour ?? 9) * 60 + (currentComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 21) * 60 + (endComponents.minute ?? 0)
        
        let totalDuration = startMinutes <= endMinutes ? (endMinutes - startMinutes) : (1440 - startMinutes + endMinutes)
        
        let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        
        var candidateDates: [Date] = []
        
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return nil }
        
        for offset in stride(from: 0, through: totalDuration, by: interval) {
            let itemMinutes = (startMinutes + offset) % 1440
            let hour = itemMinutes / 60
            let minute = itemMinutes % 60
            
            if let dateToday = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) {
                candidateDates.append(dateToday)
            }
            if let dateTomorrow = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfTomorrow) {
                candidateDates.append(dateTomorrow)
            }
        }
        
        let futureCandidates = candidateDates.filter { $0 > now }.sorted()
        return futureCandidates.first
    }
    
    // Helper to format countdown display
    public func formattedCountdown(from nextTime: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if !calendar.isDate(nextTime, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let timeString = formatter.string(from: nextTime)
            return "Tom \(timeString)"
        }
        
        let seconds = nextTime.timeIntervalSince(now)
        if seconds <= 0 {
            return "Due"
        }
        
        let minutes = Int(ceil(seconds / 60))
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

public enum Priority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    public var id: String { rawValue }
    
    public var colorHex: String {
        switch self {
        case .low: return "#8E8E93" // Apple Grey
        case .medium: return "#FF9500" // Apple Orange
        case .high: return "#FF3B30" // Apple Red
        }
    }
}

public enum RecurrencePattern: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .none: return "Don't Repeat"
        case .daily: return "Daily"
        case .weekdays: return "Every Weekday"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
