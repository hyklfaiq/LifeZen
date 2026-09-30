# LifeZen

LifeZen is a Flutter mobile application designed to help students manage their daily activities, schedules, personal well-being, and finances in one place.

The application combines task planning, timetable management, sleep tracking, expense tracking, savings, reminders, and i-Ma'luum schedule integration into a single mobile application.

---

## Features

### 📋 Task Planner

- Create and manage daily tasks.
- Mark tasks as completed.
- Delete tasks with swipe actions.
- Assign tasks to specific dates.
- View tasks directly from the calendar.
- Receive reminders for upcoming tasks.

### 📅 Schedule

- Create weekly recurring schedules.
- View schedules in a timetable.
- Manage scheduled activities.
- Receive notifications for upcoming scheduled activities.

### 🕌 i-Ma'luum Integration

- Import timetable information from i-Ma'luum.
- Automatically integrate imported schedules into LifeZen.
- Reduce the need to manually enter recurring academic schedules.
- Manage imported schedules alongside manually created schedules.

> i-Ma'luum integration is available in the current version of LifeZen.

### 😴 Sleep Tracker

- Record sleep and wake times.
- Automatically calculate sleep duration.
- View previous sleep records.
- Track sleep patterns over time.

### 🎯 Sleep Goal

- Set a personal sleep goal.
- Choose a goal between 5 and 10 hours.
- Compare recorded sleep duration with your target.

### 💰 Expense Tracker

- Record daily expenses.
- Categorize expenses.
- View recent expenses.
- Delete expenses with swipe actions.
- Monitor monthly spending.

### 💵 Budget

- Set a monthly budget.
- Automatically calculate a weekly budget.
- Track spending against your budget.

### 🏦 Savings

- Create a savings goal.
- Set a target amount.
- Add money to your savings.
- Remove money from your savings.
- Track savings progress.
- Add an image to a savings goal.

### 🔔 Reminders

- Receive notifications for upcoming tasks.
- Receive reminders for scheduled activities.
- Configure reminder timing.

### 🌙 Dark Mode

- Switch between light and dark themes.
- Theme preference is saved locally.

### 💾 Local Storage

User data is stored locally on the device using Shared Preferences.

No account or online database is required for the core application.

---

# Getting Started

## Requirements

Before installing or developing LifeZen, make sure you have the following:

### For Android Users

- Android device
- Android 5.0 (API 21) or higher
- APK file from the GitHub Releases page

### For Development

- Flutter SDK
- Dart SDK
- Android Studio or another Flutter-compatible IDE
- Android device or emulator

---

# Installation

LifeZen is currently distributed as an Android APK.

## Install from GitHub Releases

1. Go to the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.
2. Download the latest `.apk` file.
3. Transfer or download the APK to your Android device.
4. Open the APK.
5. If Android asks for permission, allow installation from unknown sources for your browser or file manager.
6. Follow the installation instructions.
7. Launch LifeZen.

> Only download APK files from trusted LifeZen releases.

---

# Development Setup

If you want to build and run LifeZen from source, follow the steps below.

Clone the repository:

```bash
git clone https://github.com/hyklfaiq/LifeZen.git
```

Open the project folder:

```bash
cd LifeZen
```

Install the dependencies:

```bash
flutter pub get
```

Check Your Flutter Environment

```bash
flutter doctor
```

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

Building the APK

To build a release APK:
```bash
flutter build apk --release
```

The generated APK can be found at:
```bash
build/app/outputs/flutter-apk/app-release.apk
```
```text
LifeZen/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │   ├── expense.dart
│   │   ├── models.dart
│   │   ├── savings_goal.dart
│   │   ├── schedule_item.dart
│   │   ├── sleep_record.dart
│   │   └── task.dart
│   │
│   ├── pages/
│   │   ├── health_page.dart
│   │   ├── home_page.dart
│   │   ├── money_page.dart
│   │   ├── planner_page.dart
│   │   └── schedule_page.dart
│   │
│   ├── services/
│   │   └── imaluum/
│   │       └── imaluum_timetable.dart
│   │
│   ├── utils/
│   │   └── app_helpers.dart
│   │
│   ├── notification_service.dart
│   │
│   └── storage/
│       └── app_storage.dart
│
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

# Technology

LifeZen is built using:

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
- [Shared Preferences](https://pub.dev/packages/shared_preferences)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Flutter Timezone](https://pub.dev/packages/flutter_timezone)
- [Image Picker](https://pub.dev/packages/image_picker)

---

# Data Storage

LifeZen uses local storage to save application data on the user's device.

Stored data includes:

- Tasks
- Schedules
- Sleep records
- Expenses
- Monthly budget
- Savings goals
- Theme preferences
- Reminder settings

The core application does not require an online account or cloud database.

---

# Notifications

LifeZen uses local notifications to remind users about upcoming activities.

Notifications can be used for:

- Upcoming tasks
- Scheduled activities
- Configured reminders

---

# i-Ma'luum Integration

The current version of LifeZen includes i-Ma'luum timetable integration.

Users can import timetable information and add it to their LifeZen schedule, reducing the need to manually create recurring academic schedules.

Imported schedules can be managed alongside regular LifeZen schedules.

---

# Releases

Stable versions of LifeZen are available through the:

[GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases)

Each release may include:

- Android APK
- Release notes
- New features
- Bug fixes
- Improvements

For detailed information about changes in a specific version, see the release notes for that version.

---

# Current Version

**Version: 2.0.0**

For the latest changes, improvements, and bug fixes, see the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.

---

# Purpose

LifeZen was developed as a student-focused mobile application to provide a simple way to organize everyday activities in one place.

The application brings together:

- Daily tasks
- Academic schedules
- Sleep tracking
- Expenses
- Budgeting
- Savings
- Reminders

The goal is to provide students with a simple and practical tool for managing their daily routines and personal well-being.

---

# Author

**hyklfaiq**
