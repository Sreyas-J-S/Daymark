import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Core parameters
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: Priority = .medium
    @State private var selectedCategory: Category?
    
    // Date & Time parameters
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasDueTime = false
    @State private var dueTime = Date()
    
    // Reminder parameters
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    
    // Interval parameters
    @State private var isIntervalReminder = false
    @State private var intervalStartTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var intervalEndTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderInterval = 30
    
    // Recurrence
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurrencePattern = .none
    
    // Subtasks
    @State private var subtaskTitle = ""
    @State private var subtaskTitles: [String] = []
    
    // Notification manager access
    @EnvironmentObject var notificationManager: NotificationManager
    
    // Query existing categories
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Suggestions list
    private let suggestions = [
        TaskSuggestion(title: "Drink Water 💧", categoryName: "Personal", priority: .medium),
        TaskSuggestion(title: "Workout 🏋️‍♂️", categoryName: "Personal", priority: .medium),
        TaskSuggestion(title: "Read Book 📚", categoryName: "Study", priority: .low),
        TaskSuggestion(title: "Check Emails ✉️", categoryName: "Work", priority: .medium),
        TaskSuggestion(title: "Groceries 🛒", categoryName: "Shopping", priority: .low)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 0: Quick Suggestions
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions) { sugg in
                                Button(action: {
                                    title = sugg.title
                                    priority = sugg.priority
                                    if let cat = categories.first(where: { $0.name.lowercased() == sugg.categoryName.lowercased() }) {
                                        selectedCategory = cat
                                    }
                                }) {
                                    Text(sugg.title)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.12))
                                        .foregroundColor(Theme.brandPrimary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Quick Suggestions")
                }
                
                // Section 1: Task Title & Notes
                Section {
                    TextField("Task Name", text: $title)
                        .font(.headline)
                    TextField("Notes & description (optional)", text: $notes, axis: .vertical)
                        .font(.body)
                        .lineLimit(3...5)
                } header: {
                    Text("Basic Info")
                }
                
                // Section 2: Category and Priority
                Section {
                    // Category selector (Horizontal scrolling cards)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // 'None' Option
                                Button(action: { selectedCategory = nil }) {
                                    HStack {
                                        Image(systemName: "tag.slash.fill")
                                        Text("None")
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == nil ? Theme.brandPrimary : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .cornerRadius(12)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                .buttonStyle(.plain)
                                
                                ForEach(categories) { category in
                                    Button(action: { selectedCategory = category }) {
                                        HStack {
                                            Image(systemName: category.iconName)
                                            Text(category.name)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory?.id == category.id ? Color(hex: category.hexColor) : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedCategory?.id == category.id ? .white : .primary)
                                        .cornerRadius(12)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Priority segmented picker
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { priorityOpt in
                            Text(priorityOpt.rawValue).tag(priorityOpt)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Classification")
                }
                
                // Section 3: Date, Time & Reminders
                Section {
                    Toggle(isOn: $hasDueDate.animation()) {
                        Label("Due Date", systemImage: "calendar")
                    }
                    
                    if hasDueDate {
                        DatePicker("Select Date", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        Toggle(isOn: $hasDueTime.animation()) {
                            Label("Set Time", systemImage: "clock")
                        }
                        
                        if hasDueTime {
                            DatePicker("Select Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                        }
                    }
                    
                    Toggle(isOn: $hasReminder.animation()) {
                        Label("Reminder Alert", systemImage: "bell")
                    }
                    .onChange(of: hasReminder) { _, newValue in
                        if newValue {
                            notificationManager.requestAuthorization()
                            if isIntervalReminder {
                                isIntervalReminder = false
                            }
                        }
                    }
                    
                    if hasReminder {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                    
                    Toggle(isOn: $isIntervalReminder.animation()) {
                        Label("Interval Reminders", systemImage: "timer")
                    }
                    .onChange(of: isIntervalReminder) { _, newValue in
                        if newValue {
                            notificationManager.requestAuthorization()
                            if hasReminder {
                                hasReminder = false
                            }
                        }
                    }
                    
                    if isIntervalReminder {
                        DatePicker("Start Time", selection: $intervalStartTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                        
                        DatePicker("End Time", selection: $intervalEndTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                        
                        Picker("Notification Interval", selection: $reminderInterval) {
                            Text("Every 15 minutes").tag(15)
                            Text("Every 30 minutes").tag(30)
                            Text("Every 45 minutes").tag(45)
                            Text("Every 1 hour").tag(60)
                            Text("Every 2 hours").tag(120)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Schedule")
                }
                
                // Section 4: Recurrence
                Section {
                    Toggle(isOn: $isRecurring.animation()) {
                        Label("Repeat Task", systemImage: "repeat")
                    }
                    
                    if isRecurring {
                        Picker("Repeat Cycle", selection: $recurrencePattern) {
                            ForEach(RecurrencePattern.allCases.filter { $0 != .none }) { pattern in
                                Text(pattern.displayName).tag(pattern)
                            }
                        }
                    }
                } header: {
                    Text("Recurrence")
                }
                
                // Section 5: Subtasks
                Section {
                    HStack {
                        TextField("Add subtask...", text: $subtaskTitle)
                        Button(action: addSubtask) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Theme.brandPrimary)
                                .font(.title3)
                        }
                        .disabled(subtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !subtaskTitles.isEmpty {
                        List {
                            ForEach(subtaskTitles, id: \.self) { title in
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                    Text(title)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(action: {
                                        if let idx = subtaskTitles.firstIndex(of: title) {
                                            subtaskTitles.remove(at: idx)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(minHeight: CGFloat(subtaskTitles.count * 40))
                    }
                } header: {
                    Text("Subtasks (\(subtaskTitles.count))")
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func addSubtask() {
        let clean = subtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty && !subtaskTitles.contains(clean) {
            subtaskTitles.append(clean)
            subtaskTitle = ""
        }
    }
    
    private func saveTask() {
        // Construct final due date
        var finalDueDate = dueDate
        if hasDueDate && hasDueTime {
            let cal = Calendar.current
            let dateComponents = cal.dateComponents([.year, .month, .day], from: dueDate)
            let timeComponents = cal.dateComponents([.hour, .minute], from: dueTime)
            
            var mergedComponents = DateComponents()
            mergedComponents.year = dateComponents.year
            mergedComponents.month = dateComponents.month
            mergedComponents.day = dateComponents.day
            mergedComponents.hour = timeComponents.hour
            mergedComponents.minute = timeComponents.minute
            
            finalDueDate = cal.date(from: mergedComponents) ?? dueDate
        } else if !hasDueDate {
            // Unsorted Inbox items standard fallback
            finalDueDate = Date.distantFuture
        }
        
        let newTask = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: finalDueDate,
            hasTime: hasDueTime,
            priority: priority,
            isCompleted: false,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : .none,
            reminderTime: hasReminder ? reminderTime : nil,
            category: selectedCategory,
            isIntervalReminder: isIntervalReminder,
            intervalStartTime: isIntervalReminder ? intervalStartTime : nil,
            intervalEndTime: isIntervalReminder ? intervalEndTime : nil,
            reminderInterval: isIntervalReminder ? reminderInterval : nil
        )
        
        // Add subtasks
        for subTitle in subtaskTitles {
            let sub = Subtask(title: subTitle, isCompleted: false)
            newTask.subtasks.append(sub)
            modelContext.insert(sub)
        }
        
        modelContext.insert(newTask)
        
        // Schedule notification if reminder or interval set
        if hasReminder || isIntervalReminder {
            notificationManager.scheduleNotification(for: newTask)
        }
        
        dismiss()
    }
}

struct TaskSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let categoryName: String
    let priority: Priority
}
