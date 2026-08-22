import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    private var inboxCount: Int {
        tasks.filter { !$0.isCompleted && $0.dueDate == Date.distantFuture }.count
    }
    
    private var todayCount: Int {
        let calendar = Calendar.current
        return tasks.filter { !$0.isCompleted && $0.dueDate != Date.distantFuture && calendar.isDateInToday($0.dueDate) }.count
    }
    
    private var upcomingCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            return tasks.filter { !$0.isCompleted && $0.dueDate >= tomorrow && $0.dueDate != Date.distantFuture }.count
        }
        return 0
    }
    
    private var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Header
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Grid layout of default lists (Today, Upcoming, Inbox, Completed)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            // 1. Today Tile
                            NavigationLink(destination: SectionTasksListView(sectionType: .today)) {
                                DashboardTile(
                                    title: "Today",
                                    count: todayCount,
                                    iconName: "calendar.badge.clock",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // 2. Upcoming Tile
                            NavigationLink(destination: SectionTasksListView(sectionType: .upcoming)) {
                                DashboardTile(
                                    title: "Upcoming",
                                    count: upcomingCount,
                                    iconName: "calendar",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // 3. Inbox Tile
                            NavigationLink(destination: SectionTasksListView(sectionType: .inbox)) {
                                DashboardTile(
                                    title: "Inbox",
                                    count: inboxCount,
                                    iconName: "tray.fill",
                                    color: .gray
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // 4. Completed Tile
                            NavigationLink(destination: SectionTasksListView(sectionType: .completed)) {
                                DashboardTile(
                                    title: "Completed",
                                    count: completedCount,
                                    iconName: "checkmark.circle.fill",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
                        // Visual Section for Category Summaries
                        CategoryDashboardSection()
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Custom Dashboard Tile Component
struct DashboardTile: View {
    let title: String
    let count: Int
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}

// Lists details view based on Dashboard Tile click
enum DashboardSectionType {
    case inbox
    case today
    case upcoming
    case completed
    
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }
}

struct SectionTasksListView: View {
    let sectionType: DashboardSectionType
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    private var sectionTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch sectionType {
        case .inbox:
            return tasks.filter { !$0.isCompleted && $0.dueDate == Date.distantFuture }
        case .today:
            return tasks.filter { !$0.isCompleted && $0.dueDate != Date.distantFuture && calendar.isDateInToday($0.dueDate) }
        case .upcoming:
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
                return tasks.filter { !$0.isCompleted && $0.dueDate >= tomorrow && $0.dueDate != Date.distantFuture }
            }
            return []
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if sectionTasks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No tasks found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        // Grouping Upcoming tasks by date for readability
                        if sectionType == .upcoming {
                            let grouped = Dictionary(grouping: sectionTasks) { task in
                                Calendar.current.startOfDay(for: task.dueDate)
                            }
                            let sortedKeys = grouped.keys.sorted()
                            
                            ForEach(sortedKeys, id: \.self) { date in
                                Section(header: Text(date.formatted(date: .long, time: .omitted))) {
                                    ForEach(grouped[date] ?? []) { task in
                                        NavigationLink(destination: TaskDetailView(task: task)) {
                                            TaskRowView(task: task)
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
                            }
                        } else {
                            // Standard listing
                            Section {
                                ForEach(sectionTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskRowView(task: task)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation {
                                                task.isCompleted.toggle()
                                                task.completionDate = task.isCompleted ? Date() : nil
                                            }
                                        } label: {
                                            Label(task.isCompleted ? "Incomplete" : "Complete", systemImage: task.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                        }
                                        .tint(task.isCompleted ? .orange : .green)
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
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(sectionType.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Category Section layout for Dashboard View
struct CategoryDashboardSection: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var tasks: [TaskItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            if categories.isEmpty {
                VStack(spacing: 8) {
                    Text("No custom categories yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Create ones in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                VStack(spacing: 10) {
                    ForEach(categories) { category in
                        let activeCount = tasks.filter { !$0.isCompleted && $0.category?.id == category.id }.count
                        let completedCount = tasks.filter { $0.isCompleted && $0.category?.id == category.id }.count
                        let total = activeCount + completedCount
                        let pct = total > 0 ? Double(completedCount) / Double(total) : 0.0
                        
                        NavigationLink(destination: CategoryDetailListView(category: category)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: category.hexColor).opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: category.iconName)
                                        .foregroundColor(Color(hex: category.hexColor))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(category.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    // Progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.gray.opacity(0.15))
                                            Capsule()
                                                .fill(Color(hex: category.hexColor))
                                                .frame(width: geo.size.width * CGFloat(pct))
                                        }
                                    }
                                    .frame(height: 4)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(activeCount)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("active")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// Category Detail Task List
struct CategoryDetailListView: View {
    let category: Category
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    private var categoryTasks: [TaskItem] {
        tasks.filter { $0.category?.id == category.id }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if categoryTasks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: category.iconName)
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: category.hexColor).opacity(0.5))
                        
                        Text("No tasks in \(category.name)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        Section {
                            ForEach(categoryTasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    TaskRowView(task: task)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        withAnimation {
                                            task.isCompleted.toggle()
                                            task.completionDate = task.isCompleted ? Date() : nil
                                        }
                                    } label: {
                                        Label(task.isCompleted ? "Incomplete" : "Complete", systemImage: task.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                    }
                                    .tint(task.isCompleted ? .orange : .green)
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
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
