import SwiftUI
import SwiftData

@main
struct DaymarkApp: App {
    @StateObject private var notificationManager = NotificationManager()
    
    // Configure SwiftData Container
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                TaskItem.self,
                Category.self,
                Subtask.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not initialize SwiftData Container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(notificationManager)
        }
        .modelContainer(container)
    }
}
