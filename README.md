# Daymark 🔔

Daymark is a premium, modern daily task planner for iOS, built with SwiftUI, SwiftData, and the native UserNotifications framework. It helps you schedule your day, manage recurring habits, and track subtask progress with a beautiful, responsive user interface.

## Features

- **SwiftData Persistence**: Offline-first task management and categories database.
- **Categorization & Priorities**: Organize tasks with icons, custom hex colors, and Low/Medium/High priority tags.
- **Subtasks Checklist**: Complete subtasks inline and track completion progress with an animated visual progress bar.
- **Standard Recurrence**: Supports Daily, Weekdays, Weekly, and Monthly recurrence.
- **Interval Reminders (Drink Water & Hydration)**:
  - Set a custom daily window (e.g. 9:00 AM to 9:00 PM).
  - Schedule notifications at regular intervals (e.g. every 15 mins, 30 mins, 45 mins, 1 hour, or 2 hours).
  - Features midnight-wrapping support for night shifts.
- **Dynamic Countdown Tracker**: Task rows display active timer badges showing a live countdown to the next scheduled interval reminder using SwiftUI `TimelineView`.

---

## Screenshots

<p align="center">
  <img src="Screenshots/today_view.png" width="45%" alt="Today Tasks View" />
  <img src="Screenshots/dashboard_view.png" width="45%" alt="Dashboard Statistics" />
</p>
<p align="center">
  <img src="Screenshots/search_view.png" width="45%" alt="Search Tasks View" />
  <img src="Screenshots/settings_view.png" width="45%" alt="Settings and Preferences" />
</p>

---

## Tech Stack

- **UI**: SwiftUI (built for iOS 15+)
- **Storage**: SwiftData
- **Notifications**: Local UserNotifications (UNCalendarNotificationTrigger)
- **Architecture**: MVVM with SwiftData `@Model` classes

## How to Run

1. Open `Daymark.xcodeproj` in Xcode.
2. Select your target device or simulator (iOS 15.0+).
3. Click the **Run** button (or press `Cmd + R`).
