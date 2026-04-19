# 🚗 CarSync - Car Workshop Management System

A cross-platform mobile app for car workshop management built with **Flutter** and **Firebase**.

---

## 🎯 Overview

| | |
|---|---|
| **Platform** | Android & iOS |
| **Framework** | Flutter (Dart) |
| **Backend** | Firebase |
| **Features** | Booking, Chat, E-commerce, Maps |

---

## ✨ Features

### Customer
- 🔐 Login with Email/Google
- 🚗 Manage vehicles
- 📍 Find workshops on map
- 📅 Book service appointments
- 💬 Real-time chat with technician
- 🛒 Buy spare parts
- 🔔 Push notifications
- 🌙 Dark/Light theme
- 🌐 English & Chinese

### Technician
- 📋 View assigned jobs
- 💬 Chat with customers
- 📦 Manage inventory

### Admin
- 📊 Dashboard overview
- 🏪 Manage workshops
- 👨‍🔧 Manage technicians
- ✅ Approve bookings
- 📦 Manage stock & orders
- ⭐ View ratings

---

## 🛠 Tech Stack

- **Flutter** - Cross-platform UI
- **Firebase Auth** - Email & Google Sign-In
- **Cloud Firestore** - NoSQL Database
- **Firebase Storage** - File uploads
- **Firebase Cloud Messaging** - Push notifications
- **Cloud Functions** - Serverless backend
- **Google Maps** - Location services

---

## 🏗 Architecture

```
lib/
├── core/
│   ├── constants/      # Colors, configs
│   ├── localization/   # EN, ZH
│   ├── services/       # Business logic
│   └── theme/          # Theme management
└── features/
    ├── auth/           # Login, Signup
    ├── customer/       # Customer pages
    ├── technician/     # Technician pages
    └── admin/          # Admin pages
```

---

## 🔥 Key Implementations

### Push Notifications
```
New Booking → Cloud Function Trigger → FCM → Admin receives notification
```

### Real-time Chat
- Firestore streams for live messages
- Support text, image, file

### Booking System
- Slot availability checking
- Status: Requested → Confirmed → In Progress → Completed

### Role-based Navigation
```dart
if (role == 'admin') → AdminHome
if (role == 'technician') → TechnicianHome
if (role == 'customer') → CustomerHome
```
