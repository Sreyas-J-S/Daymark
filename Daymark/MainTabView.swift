import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredAppearance") private var preferredAppearance = "System"
    
    // Check and pre-populate default categories if empty
    @Query private var categories: [Category]
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                TabView {
                    TodayView()
                        .tabItem {
                            Label("Today", systemImage: "calendar.badge.clock")
                        }
                    
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "square.grid.2x2.fill")
                        }
                    
                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .tint(Theme.brandPrimary)
            }
        }
        .preferredColorScheme(colorSchemeOverride)
        .onAppear(perform: checkAndPopulateDefaultCategories)
    }
    
    private var colorSchemeOverride: ColorScheme? {
        switch preferredAppearance {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // System default
        }
    }
    
    private func checkAndPopulateDefaultCategories() {
        if categories.isEmpty {
            let personal = Category(name: "Personal", iconName: "person.fill", hexColor: "#4A90E2")
            let work = Category(name: "Work", iconName: "briefcase.fill", hexColor: "#FF5E5B")
            let study = Category(name: "Study", iconName: "book.fill", hexColor: "#F5A623")
            let shopping = Category(name: "Shopping", iconName: "cart.fill", hexColor: "#2ECC71")
            
            modelContext.insert(personal)
            modelContext.insert(work)
            modelContext.insert(study)
            modelContext.insert(shopping)
            
            // Add default tasks to Personal Category
            let waterTask = TaskItem(
                title: "Drink Water 💧",
                notes: "Stay hydrated throughout the day.",
                dueDate: Date(),
                hasTime: false,
                priority: .medium,
                category: personal
            )
            let wSub1 = Subtask(title: "Morning glass 🥛", isCompleted: false)
            let wSub2 = Subtask(title: "Afternoon glass 🥛", isCompleted: false)
            let wSub3 = Subtask(title: "Evening glass 🥛", isCompleted: false)
            waterTask.subtasks.append(wSub1)
            waterTask.subtasks.append(wSub2)
            waterTask.subtasks.append(wSub3)
            
            let workoutTask = TaskItem(
                title: "Workout 🏋️‍♂️",
                notes: "30-minute cardio or strength session.",
                dueDate: Date(),
                hasTime: false,
                priority: .medium,
                category: personal
            )
            
            modelContext.insert(waterTask)
            modelContext.insert(wSub1)
            modelContext.insert(wSub2)
            modelContext.insert(wSub3)
            modelContext.insert(workoutTask)
            
            try? modelContext.save()
        }
    }
}
