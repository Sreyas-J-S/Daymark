import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Bindable var task: TaskItem
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Custom edit state properties
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: Priority = .medium
    @State private var selectedCategory: Category?
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasDueTime = false
    @State private var dueTime = Date()
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    @State private var isIntervalReminder = false
    @State private var intervalStartTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var intervalEndTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderInterval = 30
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurrencePattern = .none
    
    // Subtask adder inline state
    @State private var newSubtaskTitle = ""
    
    var body: some View {
        Form {
            // Task details section
            Section {
                TextField("Task Name", text: $title)
                    .font(.headline)
                
                TextField("Notes", text: $notes, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...5)
            } header: {
                Text("Content")
            }
            
            // Subtasks checklist & progress
            Section {
                if !task.subtasks.isEmpty {
                    // Subtask Progress bar
                    VStack(alignment: .leading, spacing: 6) {
                        let completedCount = task.subtasks.filter { $0.isCompleted }.count
                        let totalCount = task.subtasks.count
                        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
                        
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(completedCount)/\(totalCount) Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(Theme.successGradient)
                                    .frame(width: geo.size.width * CGFloat(progress), height: 8)
                                    .animation(.spring(), value: progress)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }
                
                // Add subtask inline
                HStack {
                    TextField("Add subtask...", text: $newSubtaskTitle)
                        .font(.subheadline)
                    Button(action: addSubtask) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.brandPrimary)
                            .font(.title3)
                    }
                    .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ForEach(task.subtasks) { subtask in
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                subtask.isCompleted.toggle()
                            }
                        }) {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(subtask.isCompleted ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        
                        Text(subtask.title)
                            .font(.body)
                            .strikethrough(subtask.isCompleted)
                            .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                        
                        Spacer()
                        
                        Button(action: {
                            deleteSubtask(subtask)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Subtasks Checklist")
            }
            
            // Priority & Category
            Section {
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(Category?.none)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(Category?.some(cat))
                    }
                }
            } header: {
                Text("Classification")
            }
            
            // Schedule & Reminders
            Section {
                Toggle("Due Date", isOn: $hasDueDate.animation())
                
                if hasDueDate {
                    DatePicker("Select Date", selection: $dueDate, displayedComponents: .date)
                    
                    Toggle("Set Time", isOn: $hasDueTime.animation())
                    
                    if hasDueTime {
                        DatePicker("Select Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Toggle("Reminder", isOn: $hasReminder.animation())
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
                }
                
                Toggle("Interval Reminders", isOn: $isIntervalReminder.animation())
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
                Text("Date & Time Settings")
            }
            
            // Recurrence
            Section {
                Toggle("Repeat Task", isOn: $isRecurring.animation())
                
                if isRecurring {
                    Picker("Repeat Cycle", selection: $recurrencePattern) {
                        ForEach(RecurrencePattern.allCases.filter { $0 != .none }) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }
            } header: {
                Text("Recurrence Options")
            }
            
            // Completion Status Action Button
            Section {
                Button(action: {
                    withAnimation(.spring()) {
                        task.isCompleted.toggle()
                        task.completionDate = task.isCompleted ? Date() : nil
                        
                        // Handle recurrence upon completion
                        if task.isCompleted && task.isRecurring {
                            handleRecurringCompletion()
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                        Text(task.isCompleted ? "Mark as Incomplete" : "Mark as Completed")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .frame(height: 48)
                    .background(task.isCompleted ? Theme.warningGradient : Theme.successGradient)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .fontWeight(.bold)
            }
        }
        .onAppear(perform: loadTaskInfo)
    }
    
    private func loadTaskInfo() {
        title = task.title
        notes = task.notes
        priority = task.priority
        selectedCategory = task.category
        
        hasDueDate = (task.dueDate != Date.distantFuture)
        if hasDueDate {
            dueDate = task.dueDate
            hasDueTime = task.hasTime
            if hasDueTime {
                dueTime = task.dueDate
            }
        }
        
        hasReminder = (task.reminderTime != nil)
        if hasReminder {
            reminderTime = task.reminderTime!
        }
        
        isIntervalReminder = task.isIntervalReminder ?? false
        intervalStartTime = task.intervalStartTime ?? (Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        intervalEndTime = task.intervalEndTime ?? (Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date())
        reminderInterval = task.reminderInterval ?? 30
        
        isRecurring = task.isRecurring
        recurrencePattern = task.recurrencePattern
    }
    
    private func addSubtask() {
        let clean = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            let sub = Subtask(title: clean, isCompleted: false)
            task.subtasks.append(sub)
            modelContext.insert(sub)
            newSubtaskTitle = ""
        }
    }
    
    private func deleteSubtask(_ subtask: Subtask) {
        if let idx = task.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            task.subtasks.remove(at: idx)
            modelContext.delete(subtask)
        }
    }
    
    private func handleRecurringCompletion() {
        // Calculate the next due date based on pattern
        let calendar = Calendar.current
        var nextDate: Date? = nil
        let baseDate = task.dueDate == Date.distantFuture ? Date() : task.dueDate
        
        switch task.recurrencePattern {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: baseDate)
        case .weekdays:
            // Calculate next weekday (Mon-Fri)
            var current = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? Date()
            while calendar.component(.weekday, from: current) == 1 || calendar.component(.weekday, from: current) == 7 {
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? Date()
            }
            nextDate = current
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: baseDate)
        case .none:
            break
        }
        
        // Calculate next reminder date, preserving original reminder time
        var nextReminder: Date? = nil
        if let currentReminder = task.reminderTime {
            switch task.recurrencePattern {
            case .daily:
                nextReminder = calendar.date(byAdding: .day, value: 1, to: currentReminder)
            case .weekdays:
                var current = calendar.date(byAdding: .day, value: 1, to: currentReminder) ?? Date()
                while calendar.component(.weekday, from: current) == 1 || calendar.component(.weekday, from: current) == 7 {
                    current = calendar.date(byAdding: .day, value: 1, to: current) ?? Date()
                }
                nextReminder = current
            case .weekly:
                nextReminder = calendar.date(byAdding: .weekOfYear, value: 1, to: currentReminder)
            case .monthly:
                nextReminder = calendar.date(byAdding: .month, value: 1, to: currentReminder)
            case .none:
                break
            }
        }
        
        if let next = nextDate {
            // Create a new future instance of the task
            let nextTask = TaskItem(
                title: task.title,
                notes: task.notes,
                dueDate: next,
                hasTime: task.hasTime,
                priority: task.priority,
                isCompleted: false,
                isRecurring: true,
                recurrencePattern: task.recurrencePattern,
                reminderTime: nextReminder,
                category: task.category,
                isIntervalReminder: task.isIntervalReminder ?? false,
                intervalStartTime: task.intervalStartTime,
                intervalEndTime: task.intervalEndTime,
                reminderInterval: task.reminderInterval
            )
            
            // Add clean subtasks to the new recurring task copy
            for sub in task.subtasks {
                let nextSub = Subtask(title: sub.title, isCompleted: false)
                nextTask.subtasks.append(nextSub)
                modelContext.insert(nextSub)
            }
            
            modelContext.insert(nextTask)
            
            // Schedule notification for the next task
            if nextTask.reminderTime != nil || (nextTask.isIntervalReminder ?? false) {
                notificationManager.scheduleNotification(for: nextTask)
            }
        }
    }
    
    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority = priority
        task.category = selectedCategory
        
        if hasDueDate {
            var finalDueDate = dueDate
            if hasDueTime {
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
            }
            task.dueDate = finalDueDate
            task.hasTime = hasDueTime
        } else {
            task.dueDate = Date.distantFuture
            task.hasTime = false
        }
        
        task.isIntervalReminder = isIntervalReminder
        task.intervalStartTime = isIntervalReminder ? intervalStartTime : nil
        task.intervalEndTime = isIntervalReminder ? intervalEndTime : nil
        task.reminderInterval = isIntervalReminder ? reminderInterval : nil
        
        if hasReminder || isIntervalReminder {
            task.reminderTime = hasReminder ? reminderTime : nil
            notificationManager.scheduleNotification(for: task)
        } else {
            task.reminderTime = nil
            notificationManager.cancelNotification(for: task)
        }
        
        task.isRecurring = isRecurring
        task.recurrencePattern = isRecurring ? recurrencePattern : .none
        
        dismiss()
    }
}
