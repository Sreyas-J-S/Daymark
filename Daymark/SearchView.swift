import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var selectedSort: SearchSort = .dueDate
    
    enum SearchFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case highPriority = "High Priority"
        case completed = "Completed"
        
        var id: String { rawValue }
    }
    
    enum SearchSort: String, CaseIterable, Identifiable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case creationDate = "Date Created"
        case alphabetical = "A-Z"
        
        var id: String { rawValue }
    }
    
    // Core search & filter logic
    private var filteredAndSortedTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        
        // 1. Search Query Filter
        var result = tasks
        if !searchText.isEmpty {
            result = result.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.notes.localizedCaseInsensitiveContains(searchText) ||
                (task.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // 2. Category/Status Filters
        switch selectedFilter {
        case .all:
            break
        case .today:
            result = result.filter { task in
                !task.isCompleted && task.dueDate != Date.distantFuture && calendar.isDate(task.dueDate, inSameDayAs: today)
            }
        case .upcoming:
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) {
                result = result.filter { task in
                    !task.isCompleted && task.dueDate >= tomorrow && task.dueDate != Date.distantFuture
                }
            }
        case .overdue:
            result = result.filter { $0.isOverdue }
        case .highPriority:
            result = result.filter { !$0.isCompleted && $0.priority == .high }
        case .completed:
            result = result.filter { $0.isCompleted }
        }
        
        // 3. Sorting
        switch selectedSort {
        case .dueDate:
            result.sort { lhs, rhs in
                if lhs.dueDate == Date.distantFuture { return false }
                if rhs.dueDate == Date.distantFuture { return true }
                return lhs.dueDate < rhs.dueDate
            }
        case .priority:
            // High -> Medium -> Low
            result.sort { lhs, rhs in
                let lVal = priorityWeight(lhs.priority)
                let rVal = priorityWeight(rhs.priority)
                return lVal > rVal
            }
        case .creationDate:
            result.sort { $0.createdAt > $1.createdAt }
        case .alphabetical:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return result
    }
    
    private func priorityWeight(_ p: Priority) -> Int {
        switch p {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Picker ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SearchFilter.allCases) { filter in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedFilter = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Theme.brandPrimary : Color.gray.opacity(0.15))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .background(Color(UIColor.systemBackground))
                    
                    // Sort Options bar
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Sort", selection: $selectedSort) {
                            ForEach(SearchSort.allCases) { sortOpt in
                                Text(sortOpt.rawValue).tag(sortOpt)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        
                        Spacer()
                        
                        Text("\(filteredAndSortedTasks.count) tasks found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // Results List
                    if filteredAndSortedTasks.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.4))
                            
                            Text("No Tasks Found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try adjusting your search queries or filters.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 48)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(filteredAndSortedTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        HStack(spacing: 12) {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(task.isCompleted ? .green : Color(hex: task.priority.colorHex))
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.title)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .strikethrough(task.isCompleted)
                                                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                                                
                                                if task.dueDate != Date.distantFuture {
                                                    Text(task.dueDate.formatted(date: .abbreviated, time: task.hasTime ? .shortened : .omitted))
                                                        .font(.caption)
                                                        .foregroundColor(task.isOverdue ? .red : .secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if let category = task.category {
                                                Text(category.name)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color(hex: category.hexColor).opacity(0.15))
                                                    .foregroundColor(Color(hex: category.hexColor))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(.vertical, 2)
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
            .navigationTitle("Search Tasks")
            .searchable(text: $searchText, prompt: "Search by title, notes, or category...")
        }
    }
}
