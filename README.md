# LifeZen
<p align="center">
  <img src="assets\images\zenlife icon.png" width="120" alt="LifeZen Icon">
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Android-API%2021%2B-green?logo=android" alt="Android">
  <img src="https://img.shields.io/github/v/release/hyklfaiq/LifeZen" alt="Latest Release">
</p>

<p align="center">
  <strong>A student-focused mobile application for managing daily activities, schedules, well-being, and finances.</strong>
</p>

<p align="center">
  <a href="https://github.com/hyklfaiq/LifeZen/releases">Download</a>
  ·
  <a href="https://github.com/hyklfaiq/LifeZen/issues">Issues</a>
  ·
  <a href="https://github.com/hyklfaiq/LifeZen/releases">Releases</a>
</p>

---

## Table of Contents

* [About](#about)
* [Features](#features)
* [Getting Started](#getting-started)
* [Installation](#installation)
* [Development Setup](#development-setup)
* [Building the APK](#building-the-apk)
* [Project Structure](#project-structure)
* [Technology](#technology)
* [Data Storage](#data-storage)
* [Notifications](#notifications)
* [i-Ma'luum Integration](#i-maluum-integration)
* [Schedule export](#schedule-export)
* [Releases](#releases)
* [Current Version](#current-version)
* [License](#license)
* [Purpose](#purpose)
* [Author](#author)

---

## About

LifeZen is a Flutter mobile application designed to help students manage their daily activities, schedules, personal well-being, and finances in one place.

The application combines task planning, timetable management, sleep tracking, expense tracking, savings, reminders, and i-Ma'luum schedule integration into a single mobile application.

---

# Features

### 📋 Task Planner

* Create and manage daily tasks.
* Mark tasks as completed.
* Delete tasks with swipe actions.
* Assign tasks to specific dates.
* View tasks directly from the calendar.
* Receive reminders for upcoming tasks.

### 📅 Schedule

* Create weekly recurring schedules.
* View schedules in a timetable.
* Choose between different timetable viewing modes.
* Use compact schedule viewing for a more condensed timetable.
* Zoom and drag the timetable to view schedules more easily.
* Assign custom colors to subjects.
* View a live current-time indicator across the timetable.
* Manage scheduled activities.
* Receive notifications for upcoming scheduled activities.
* Export schedules in multiple formats.

### 🕌 i-Ma'luum Integration

* Import timetable information from i-Ma'luum.
* Automatically integrate imported schedules into LifeZen.
* Reduce the need to manually enter recurring academic schedules.
* Manage imported schedules alongside manually created schedules.

> i-Ma'luum integration is available in the current version of LifeZen.

### 😴 Sleep Tracker

* Record sleep and wake times.
* Automatically calculate sleep duration.
* View previous sleep records.
* Track sleep patterns over time.

### 🎯 Sleep Goal

* Set a personal sleep goal.
* Choose a goal between 5 and 10 hours.
* Compare recorded sleep duration with your target.

### 💰 Expense Tracker

* Record daily expenses.
* Categorize expenses.
* View recent expenses.
* Delete expenses with swipe actions.
* Monitor monthly spending.

### 💵 Budget

* Set a monthly budget.
* Automatically calculate a weekly budget.
* Track spending against your budget.

### 🏦 Savings

* Create a savings goal.
* Set a target amount.
* Add money to your savings.
* Remove money from your savings.
* Track savings progress.
* Add an image to a savings goal.

### 🔔 Reminders

* Receive notifications for upcoming tasks.
* Receive reminders for scheduled activities.
* Configure reminder timing.

### 🌙 Dark Mode

* Switch between light and dark themes.
* Theme preference is saved locally.

### 💾 Local Storage

User data is stored locally on the device using Shared Preferences.

No account or online database is required for the core application.

---

# Getting Started

## Requirements

Before installing or developing LifeZen, make sure you have the following.

### For Android Users

* Android device
* Android 5.0 (API 21) or higher
* APK file from the GitHub Releases page

### For Development

* Flutter SDK
* Dart SDK
* Android Studio or another Flutter-compatible IDE
* Android device or emulator

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

## Clone the Repository

```bash
git clone https://github.com/hyklfaiq/LifeZen.git
```

Open the project folder:

```bash
cd LifeZen
```

## Check Flutter Environment

Run:

```bash
flutter doctor
```

Make sure your Flutter environment is properly configured before continuing.

## Install Dependencies

```bash
flutter pub get
```

## Run the Application

Connect an Android device or start an Android emulator.

Then run:

```bash
flutter run
```

---

# Building the APK

To build a release APK:

```bash
flutter build apk --release
```

The generated APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can then install the APK on a compatible Android device.

---

# Project Structure

```text
LifeZen/
├── android/
├── ios/
├── lib/
│ ├── main.dart
│ │
│ ├── models/
│ │ ├── expense.dart
│ │ ├── models.dart
│ │ ├── savings_goal.dart
│ │ ├── schedule_item.dart
│ │ ├── sleep_record.dart
│ │ └── task.dart
│ │
│ ├── pages/
│ │ ├── health_page.dart
│ │ ├── home_page.dart
│ │ ├── money_page.dart
│ │ ├── planner_page.dart
│ │ ├── schedule_page.dart
│ │ └── imaluum_import_page.dart
│ │
│ ├── services/
│ │ ├── imaluum/
│ │ │ └── imaluum_timetable.dart
│ │ └── schedule_export/
│ │ └── schedule_export.dart
│ │
│ ├── utils/
│ │ └── app_helpers.dart
│ │ └── schedule_colors.dart
│ │
│ │
│ ├── notification_service.dart
│ │
│ └── storage/
│ └── app_storage.dart
│
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

# Technology

LifeZen is built using:

* [Flutter](https://flutter.dev/)
* [Dart](https://dart.dev/)
* [Shared Preferences](https://pub.dev/packages/shared_preferences)
* [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
* [Flutter Timezone](https://pub.dev/packages/flutter_timezone)
* [Image Picker](https://pub.dev/packages/image_picker)

---

# Data Storage

LifeZen uses local storage to save application data on the user's device.

Stored data includes:

* Tasks
* Schedules
* Sleep records
* Expenses
* Monthly budget
* Savings goals
* Theme preferences
* Reminder settings

The core application does not require an online account or cloud database.

---

# Notifications

LifeZen uses local notifications to remind users about upcoming activities.

Notifications can be used for:

* Upcoming tasks
* Scheduled activities
* Configured reminders

Reminder timing can be configured from the application settings.

---

# i-Ma'luum Integration

The current version of LifeZen includes i-Ma'luum timetable integration.

Users can import timetable information and add it to their LifeZen schedule, reducing the need to manually create recurring academic schedules.

Imported schedules can be managed alongside regular LifeZen schedules.

---

> **Disclaimer:** LifeZen is an independent student project and is **not affiliated with, endorsed by, sponsored by, or officially connected to the International Islamic University Malaysia (IIUM) or i-Ma'luum.** The i-Ma'luum integration is provided solely as a convenience for users and does not represent an official IIUM service.
# Schedule Export

LifeZen supports exporting schedule information for use outside the application.

Supported export formats include:

ICS for calendar applications and timetable imports.
CSV for spreadsheet and data processing applications.
PNG for sharing or saving a visual copy of the timetable.

Exported schedules contain the relevant timetable information available in LifeZen.


# Releases

Stable versions of LifeZen are available through the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.

Each release may include:

* Android APK
* Release notes
* New features
* Bug fixes
* Improvements

For detailed information about changes in a specific version, see the release notes for that version.

---

# Current Version

**Version: 2.0.0**

For the latest changes, improvements, and bug fixes, see the [GitHub Releases](https://github.com/hyklfaiq/LifeZen/releases) page.

---

---

# License

LifeZen is publicly available for portfolio and educational purposes.
All rights reserved. No permission is granted to copy, modify,
distribute, or use this software commercially without prior written
permission.

---

# Purpose

LifeZen was developed as a student-focused mobile application to provide a simple way to organize everyday activities in one place.

The application brings together:

* Daily tasks
* Academic schedules
* Sleep tracking
* Expenses
* Budgeting
* Savings
* Reminders

The goal is to provide students with a simple and practical tool for managing their daily routines and personal well-being.

---

# Author

**hyklfaiq**

GitHub: [@hyklfaiq](https://github.com/hyklfaiq)

---

<p align="center">
  Made with Flutter and Dart
</p>
