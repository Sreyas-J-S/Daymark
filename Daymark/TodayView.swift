import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    
    // Fetch all active tasks
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var quickTaskTitle = ""
    @State private var isShowingAddTask = false
    @State private var selectedPriorityFilter: Priority?
    @State private var selectedCategoryFilter: Category?
    
    // Current date helpers
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // Core filters for "Today"
    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        
        return tasks.filter { task in
            guard !task.isCompleted else { return false }
            
            // Exclude distantFuture (unsorted Inbox)
            guard task.dueDate != Date.distantFuture else { return false }
            
            // Check if it is due today
            let isSameDay = calendar.isDate(task.dueDate, inSameDayAs: today)
            
            // Apply filtering options
            if let pFilter = selectedPriorityFilter, task.priority != pFilter {
                return false
            }
            if let cFilter = selectedCategoryFilter, task.category?.id != cFilter.id {
                return false
            }
            
            return isSameDay
        }
    }
    
    // Overdue tasks filter
    private var overdueTasks: [TaskItem] {
        tasks.filter { $0.isOverdue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Date Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedDate.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        
                        HStack {
                            Text("Today's Tasks")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Spacer()
                            
                            // Task Counter Badge
                            Text("\(todayTasks.count) left")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.primaryGradient)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Filter chip bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Clear filters
                            if selectedPriorityFilter != nil || selectedCategoryFilter != nil {
                                Button(action: {
                                    withAnimation {
                                        selectedPriorityFilter = nil
                                        selectedCategoryFilter = nil
                                    }
                                }) {
                                    Text("Reset Filters")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.brandPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Theme.brandPrimary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Priority Filters
                            ForEach(Priority.allCases) { prio in
                                Button(action: {
                                    withAnimation {
                                        selectedPriorityFilter = (selectedPriorityFilter == prio) ? nil : prio
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: prio.colorHex))
                                            .frame(width: 8, height: 8)
                                        Text("\(prio.rawValue)")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedPriorityFilter == prio ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedPriorityFilter == prio ? Color(hex: prio.colorHex) : Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Category Filters
                            ForEach(categories) { cat in
                                Button(action: {
                                    withAnimation {
                                        selectedCategoryFilter = (selectedCategoryFilter?.id == cat.id) ? nil : cat
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.iconName)
                                            .font(.caption2)
                                        Text(cat.name)
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategoryFilter?.id == cat.id ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryFilter?.id == cat.id ? Color(hex: cat.hexColor) : Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    
                    // Task Lists Area
                    List {
                        // Overdue Tasks Warning Banner
                        if !overdueTasks.isEmpty {
                            Section {
                                NavigationLink(destination: OverdueTasksDetailView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Overdue Tasks")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                            Text("You have \(overdueTasks.count) tasks past their due date.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .listRowBackground(Color.red.opacity(0.08))
                        }
                        
                        // Today's Active Tasks
                        if todayTasks.isEmpty {
                            Section {
                                VStack(spacing: 16) {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Theme.primaryGradient)
                                        .shadow(color: Theme.brandPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
                                    
                                    Text("You're all caught up!")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Any tasks you schedule for today will appear here.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, minHeight: 220)
                                .listRowBackground(Color.clear)
                            }
                        } else {
                            Section {
                                ForEach(todayTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskRowView(task: task)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation(.spring()) {
                                                task.isCompleted = true
                                                task.completionDate = Date()
                                                
                                                // Handle recurrence
                                                if task.isRecurring {
                                                    handleRecurringCompletion(for: task)
                                                }
                                            }
                                        } label: {
                                            Label("Complete", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTask(task)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            rescheduleToTomorrow(task)
                                        } label: {
                                            Label("Tomorrow", systemImage: "arrow.right.circle.fill")
                                        }
                                        .tint(.orange)
                                    }
                                    .contextMenu {
                                        Button(action: { rescheduleToTomorrow(task) }) {
                                            Label("Reschedule for Tomorrow", systemImage: "calendar.badge.clock")
                                        }
                                        Button(role: .destructive, action: { deleteTask(task) }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    // Quick Task Input Bar
                    HStack(spacing: 12) {
                        TextField("Quick Add to Today...", text: $quickTaskTitle, onCommit: addQuickTask)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        Button(action: addQuickTask) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.primaryGradient)
                        }
                        .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -4)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingAddTask = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Theme.primaryGradient)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $isShowingAddTask) {
                AddTaskSheet()
            }
        }
    }
    
    private func addQuickTask() {
        let cleanTitle = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        
        let newTask = TaskItem(
            title: cleanTitle,
            dueDate: Date(), // Scheduled for today
            hasTime: false,
            priority: .medium
        )
        
        modelContext.insert(newTask)
        quickTaskTitle = ""
    }
    
    private func rescheduleToTomorrow(_ task: TaskItem) {
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            withAnimation(.spring()) {
                task.dueDate = tomorrow
                // Reschedule notifications too if any
                notificationManager.scheduleNotification(for: task)
            }
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        notificationManager.cancelNotification(for: task)
        modelContext.delete(task)
    }
    
    private func handleRecurringCompletion(for task: TaskItem) {
        let calendar = Calendar.current
        var nextDate: Date? = nil
        
        switch task.recurrencePattern {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: task.dueDate)
        case .weekdays:
            var current = calendar.date(byAdding: .day, value: 1, to: task.dueDate) ?? Date()
            while calendar.component(.weekday, from: current) == 1 || calendar.component(.weekday, from: current) == 7 {
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? Date()
            }
            nextDate = current
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: task.dueDate)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: task.dueDate)
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
            
            for sub in task.subtasks {
                let nextSub = Subtask(title: sub.title, isCompleted: false)
                nextTask.subtasks.append(nextSub)
                modelContext.insert(nextSub)
            }
            
            modelContext.insert(nextTask)
            
            if nextTask.reminderTime != nil || (nextTask.isIntervalReminder ?? false) {
                notificationManager.scheduleNotification(for: nextTask)
            }
        }
    }
}

// Single Row View component for listing tasks
struct TaskRowView: View {
    let task: TaskItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button (purely indicator, tap row to open details and complete, or swipe to complete)
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : Color(hex: task.priority.colorHex))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Due time indicator
                    if task.hasTime {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Subtasks count indicator
                    if !task.subtasks.isEmpty {
                        let completedCount = task.subtasks.filter { $0.isCompleted }.count
                        HStack(spacing: 2) {
                            Image(systemName: "checklist")
                                .font(.caption2)
                            Text("\(completedCount)/\(task.subtasks.count)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Reminder active indicator
                    if task.reminderTime != nil || (task.isIntervalReminder ?? false) {
                        HStack(spacing: 3) {
                            Image(systemName: task.isIntervalReminder ?? false ? "timer" : "bell.fill")
                                .font(.caption2)
                            
                            if task.isIntervalReminder ?? false {
                                TimelineView(.periodic(from: .now, by: 60)) { context in
                                    if let nextTime = task.nextIntervalReminderTime {
                                        Text(task.formattedCountdown(from: nextTime))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .foregroundColor(.orange)
                    }
                    
                    // Recurrence indicator
                    if task.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Category badge
                    if let category = task.category {
                        HStack(spacing: 3) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 8))
                            Text(category.name)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: category.hexColor).opacity(0.15))
                        .foregroundColor(Color(hex: category.hexColor))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Priority Tag Icon
            Circle()
                .fill(Color(hex: task.priority.colorHex))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

// Subview showing full list of overdue tasks
struct OverdueTasksDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    private var overdueTasks: [TaskItem] {
        tasks.filter { $0.isOverdue }
    }
    
    var body: some View {
        List {
            ForEach(overdueTasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.title)
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                            Circle()
                                .fill(Color(hex: task.priority.colorHex))
                                .frame(width: 8, height: 8)
                        }
                        
                        HStack(spacing: 8) {
                            Text("Was due: \(task.dueDate.formatted(date: .abbreviated, time: task.hasTime ? .shortened : .omitted))")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            if let category = task.category {
                                Text(category.name)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color(hex: category.hexColor).opacity(0.15))
                                    .foregroundColor(Color(hex: category.hexColor))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        withAnimation {
                            task.isCompleted = true
                            task.completionDate = Date()
                        }
                    } label: {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        notificationManager.cancelNotification(for: task)
                        modelContext.delete(task)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Overdue Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
