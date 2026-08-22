import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    
    @AppStorage("preferredAppearance") private var preferredAppearance = "System" // System, Light, Dark
    @AppStorage("defaultPriority") private var defaultPriority = "Medium"
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var tasks: [TaskItem]
    
    // Add Category Sheet state
    @State private var isShowingAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = "#6366F1"
    @State private var newCategoryIcon = "tag.fill"
    
    // Alert state
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    
    let colorOptions = ["#6366F1", "#A855F7", "#FF5E5B", "#F5A623", "#2ECC71", "#4A90E2", "#9B59B6", "#E74C3C"]
    
    let iconOptions = ["tag.fill", "person.fill", "briefcase.fill", "book.fill", "cart.fill", "house.fill", "heart.fill", "star.fill", "airplane", "gamecontroller.fill", "hammer.fill", "music.note"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Notifications
                Section {
                    HStack {
                        Label("Local Reminders", systemImage: "bell.badge.fill")
                        Spacer()
                        Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                            .font(.subheadline)
                            .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                    }
                    
                    if !notificationManager.isAuthorized {
                        Button("Request Notification Permission") {
                            notificationManager.requestAuthorization { granted in
                                if !granted {
                                    alertTitle = "Permission Denied"
                                    alertMessage = "Please enable notifications in iOS Settings to receive task reminders."
                                    isShowingAlert = true
                                }
                            }
                        }
                    }
                    
                    Button("Send Instant Test Notification") {
                        notificationManager.triggerInstantTestNotification()
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Section 2: Appearance
                Section {
                    Picker("Theme Style", selection: $preferredAppearance) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Appearance")
                }
                
                // Section 3: Defaults
                Section {
                    Picker("Default Priority", selection: $defaultPriority) {
                        ForEach(Priority.allCases) { p in
                            Text(p.rawValue).tag(p.rawValue)
                        }
                    }
                } header: {
                    Text("New Task Defaults")
                }
                
                // Section 4: Category Management
                Section {
                    Button(action: { isShowingAddCategory = true }) {
                        Label("Add Custom Category", systemImage: "plus.circle")
                            .foregroundColor(Theme.brandPrimary)
                    }
                    
                    ForEach(categories) { category in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.hexColor).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: category.iconName)
                                    .foregroundColor(Color(hex: category.hexColor))
                                    .font(.caption)
                            }
                            
                            Text(category.name)
                            
                            Spacer()
                            
                            // Delete Button
                            Button(action: {
                                deleteCategory(category)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Category Management (\(categories.count))")
                }
                
                // Section 5: Data Management
                Section {
                    Button("Generate Sample Tasks & Categories") {
                        generateSampleData()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All App Data", role: .destructive) {
                        clearAllData()
                    }
                } header: {
                    Text("Data Management")
                }
                
                // Section 6: App Info
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Powered by")
                        Spacer()
                        Text("SwiftUI & SwiftData")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daymark - Your day, organized.")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("An elegant productivity suite focused on helping users stay focused, calm, and structured throughout the day.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Daymark")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingAddCategory) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Category Name", text: $newCategoryName)
                        } header: {
                            Text("Name")
                        }
                        
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { colorHex in
                                        Circle()
                                            .fill(Color(hex: colorHex))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: newCategoryColor == colorHex ? 3 : 0)
                                            )
                                            .shadow(radius: 2)
                                            .onTapGesture {
                                                newCategoryColor = colorHex
                                            }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Color")
                        }
                        
                        Section {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(newCategoryIcon == icon ? Theme.brandPrimary : Color.gray.opacity(0.15))
                                            .frame(height: 44)
                                        
                                        Image(systemName: icon)
                                            .foregroundColor(newCategoryIcon == icon ? .white : .primary)
                                            .font(.body)
                                    }
                                    .onTapGesture {
                                        newCategoryIcon = icon
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Icon")
                        }
                    }
                    .navigationTitle("New Category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingAddCategory = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveCategory()
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .fontWeight(.bold)
                        }
                    }
                }
            }
            .alert(alertTitle, isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveCategory() {
        let cleanName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        let newCat = Category(name: cleanName, iconName: newCategoryIcon, hexColor: newCategoryColor)
        modelContext.insert(newCat)
        
        // Reset state
        newCategoryName = ""
        isShowingAddCategory = false
    }
    
    private func deleteCategory(_ category: Category) {
        modelContext.delete(category)
    }
    
    private func clearAllData() {
        // Clear all tasks
        for task in tasks {
            notificationManager.cancelNotification(for: task)
            modelContext.delete(task)
        }
        // Clear categories
        for cat in categories {
            modelContext.delete(cat)
        }
        
        alertTitle = "Success"
        alertMessage = "All app tasks, subtasks, and categories have been cleared."
        isShowingAlert = true
    }
    
    private func generateSampleData() {
        // Ensure default categories exist
        var workCat = categories.first(where: { $0.name == "Work" })
        var studyCat = categories.first(where: { $0.name == "Study" })
        var shoppingCat = categories.first(where: { $0.name == "Shopping" })
        var personalCat = categories.first(where: { $0.name == "Personal" })
        
        if workCat == nil {
            let cat = Category(name: "Work", iconName: "briefcase.fill", hexColor: "#FF5E5B")
            modelContext.insert(cat)
            workCat = cat
        }
        if studyCat == nil {
            let cat = Category(name: "Study", iconName: "book.fill", hexColor: "#F5A623")
            modelContext.insert(cat)
            studyCat = cat
        }
        if shoppingCat == nil {
            let cat = Category(name: "Shopping", iconName: "cart.fill", hexColor: "#2ECC71")
            modelContext.insert(cat)
            shoppingCat = cat
        }
        if personalCat == nil {
            let cat = Category(name: "Personal", iconName: "person.fill", hexColor: "#4A90E2")
            modelContext.insert(cat)
            personalCat = cat
        }
        
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // 1. Overdue Task
        let overdueTask = TaskItem(
            title: "Submit Q2 report",
            notes: "Send the final PDF draft to manager.",
            dueDate: yesterday,
            hasTime: true,
            priority: .high,
            category: workCat
        )
        modelContext.insert(overdueTask)
        
        // 2. Today's high priority task with subtasks
        let todayTask = TaskItem(
            title: "Prepare presentations slides",
            notes: "Design slides for product marketing review.",
            dueDate: today,
            hasTime: false,
            priority: .high,
            category: workCat
        )
        modelContext.insert(todayTask)
        
        let sub1 = Subtask(title: "Research competitor stats", isCompleted: true)
        let sub2 = Subtask(title: "Draft copy outlines", isCompleted: false)
        let sub3 = Subtask(title: "Choose color accents", isCompleted: false)
        
        todayTask.subtasks.append(sub1)
        todayTask.subtasks.append(sub2)
        todayTask.subtasks.append(sub3)
        
        modelContext.insert(sub1)
        modelContext.insert(sub2)
        modelContext.insert(sub3)
        
        // 3. Recurring Study Task
        let recurringTask = TaskItem(
            title: "Solve Swift coding practice",
            notes: "Do 30 mins of algorithms on Leetcode.",
            dueDate: today,
            hasTime: false,
            priority: .medium,
            isRecurring: true,
            recurrencePattern: .daily,
            category: studyCat
        )
        modelContext.insert(recurringTask)
        
        // 4. Upcoming Task (Tomorrow)
        let tomorrowTask = TaskItem(
            title: "Weekend groceries",
            notes: "Milk, almond butter, bread, avocados.",
            dueDate: tomorrow,
            hasTime: false,
            priority: .low,
            category: shoppingCat
        )
        modelContext.insert(tomorrowTask)
        
        // 5. Unsorted Inbox task
        let inboxTask = TaskItem(
            title: "Watch WWDC SwiftUI videos",
            notes: "Look up SwiftData schema migrations.",
            dueDate: Date.distantFuture,
            hasTime: false,
            priority: .medium
        )
        modelContext.insert(inboxTask)
        
        // 6. Already completed task
        let completedTask = TaskItem(
            title: "Morning run",
            notes: "Run 5k around the lake.",
            dueDate: today,
            hasTime: false,
            priority: .low,
            isCompleted: true,
            completionDate: today,
            category: personalCat
        )
        modelContext.insert(completedTask)
        
        alertTitle = "Success"
        alertMessage = "Sample tasks, subtasks, and categories generated successfully!"
        isShowingAlert = true
    }
}
