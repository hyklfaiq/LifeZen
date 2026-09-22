# LifeZen

LifeZen is a Flutter mobile application designed to help students manage their daily activities and personal well-being in one place.

## Features

* **Task Planner** — Create, manage, and complete daily tasks.
* **Schedule** — Create recurring weekly schedules and view them in a timetable.
* **Sleep Tracker** — Record sleep and wake times and track sleep duration.
* **Sleep Goal** — Set a personal sleep goal from 5 to 10 hours.
* **Expense Tracker** — Record and monitor daily expenses.
* **Budget** — Set a monthly budget with an automatically calculated weekly budget.
* **Savings** — Set a savings goal, add or remove savings, and track progress.
* **Reminders** — Receive notifications for upcoming tasks and scheduled activities.
* **Dark Mode** — Use the application with a dark theme.
* **Local Storage** — User data is stored locally on the device.

## Technology

* Flutter
* Dart
* Shared Preferences
* Flutter Local Notifications
* Flutter Timezone
* Image Picker

## Project Structure

```text
lib/
├── main.dart
├── models/
│   ├── expense.dart
│   ├── models.dart
│   ├── savings_goal.dart
│   ├── schedule_item.dart
│   ├── sleep_record.dart
│   └── task.dart
├── pages/
│   ├── health_page.dart
│   ├── home_page.dart
│   ├── money_page.dart
│   ├── planner_page.dart
│   └── schedule_page.dart
├── utils/
│   └── app_helpers.dart
├── notification_service.dart
└── storage/
    └── app_storage.dart
```

## Installation

LifeZen is currently distributed as an Android APK.

### Requirements

* Android device
* Android 5.0 (API 21) or higher

### Install

1. Download the latest APK from the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.
2. Open the downloaded APK on your Android device.
3. If prompted, allow installation from unknown sources for your browser or file manager.
4. Follow the installation instructions.

## Development Setup

If you want to run the project from source, you will need:

* Flutter SDK
* Dart SDK
* Android device or emulator

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

Run the application:

```bash
flutter run
```

## Releases

Stable versions of LifeZen are available through the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.

Each release may include a downloadable APK for Android devices.

## Version

Current version: **1.0.1**

## Purpose

LifeZen was developed as a student-focused mobile application to provide a simple way to organize daily tasks, schedules, sleep, expenses, and savings in one place.
