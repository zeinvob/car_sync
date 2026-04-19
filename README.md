# 🚗 CarSync - Car Workshop Management System

A full-featured cross-platform mobile application for managing car workshop operations, built with **Flutter** and **Firebase**. The app connects customers, technicians, and administrators in a seamless ecosystem for vehicle service booking, real-time communication, and spare parts e-commerce.

---

## 📱 Screenshots

> 💡 **To add screenshots:** Take screenshots of your app and save them to a `screenshots/` folder, then update the paths below.

| Customer Home | Workshop Map | Booking Details | Spare Parts Shop |
|:-------------:|:------------:|:---------------:|:----------------:|
| ![Home](screenshots/customer_home.png) | ![Map](screenshots/workshop_map.png) | ![Booking](screenshots/booking_details.png) | ![Shop](screenshots/spare_parts.png) |

| Admin Dashboard | Technician Jobs | Real-time Chat | Dark Mode |
|:---------------:|:---------------:|:--------------:|:---------:|
| ![Admin](screenshots/admin_dashboard.png) | ![Jobs](screenshots/technician_jobs.png) | ![Chat](screenshots/chat.png) | ![Dark](screenshots/dark_mode.png) |

---

## 🎯 Project Highlights

| Metric | Details |
|--------|---------|
| **Platform** | Android & iOS (Cross-platform) |
| **Architecture** | Feature-based modular architecture |
| **Backend** | Serverless (Firebase) |
| **Authentication** | Multi-provider (Email, Google) |
| **Real-time Features** | Chat, Notifications, Live Updates |
| **Localization** | English, Chinese |
| **Theme** | Light & Dark mode support |

---

## ✨ Features

### 👤 Customer Module
- **Authentication** - Email/Password & Google Sign-In
- **Vehicle Management** - Add, edit, and manage multiple vehicles
- **Workshop Discovery** - Find nearby workshops with Google Maps integration
- **Service Booking** - Book appointments with real-time slot availability
- **Booking Tracking** - Track service status with step-by-step progress
- **Real-time Chat** - Communicate with technicians and admin
- **Spare Parts Shop** - Browse, add to cart, and purchase spare parts
- **Order Management** - Track spare parts orders
- **Push Notifications** - Receive updates on booking status changes
- **Multi-language Support** - English & Chinese (中文)
- **Dark/Light Theme** - Toggle between appearance modes

### 🔧 Technician Module
- **Job Dashboard** - View and manage assigned service jobs
- **Job Details** - Access customer info, vehicle details, and service requirements
- **Real-time Chat** - Communicate with customers about their vehicles
- **Inventory Management** - Track and manage spare parts inventory
- **Profile Management** - Update technician profile and settings

### 🛠 Admin Module
- **Dashboard Overview** - Monitor bookings, orders, and notifications at a glance
- **Workshop Management** - CRUD operations for workshop locations
- **Technician Management** - Add, edit, and assign technicians
- **Booking Management** - Approve, assign, and track all bookings
- **Stock Management** - Manage spare parts inventory across workshops
- **Parts Orders** - Process and fulfill customer spare parts orders
- **Ratings & Reviews** - Monitor customer feedback and ratings
- **Chat Inbox** - Respond to customer support inquiries
- **Push Notifications** - Receive alerts for new bookings and orders

---

## 🏗 Architecture

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── core/                        # Shared utilities
│   ├── constants/               # App colors, strings
│   ├── localization/            # Multi-language support (EN/ZH)
│   ├── services/                # Business logic services
│   ├── theme/                   # Theme controllers
│   └── widgets/                 # Reusable UI components
└── features/                    # Feature-based modules
    ├── auth/                    # Authentication flows
    ├── customer/                # Customer-facing features
    │   ├── model/               # Data models
    │   ├── pages/               # UI screens
    │   └── widgets/             # Feature-specific widgets
    ├── technician/              # Technician portal
    ├── admin/                   # Admin dashboard
    └── splash/                  # Splash screen
```

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter (Dart) |
| **Backend** | Firebase (BaaS) |
| **Authentication** | Firebase Auth (Email + Google Sign-In) |
| **Database** | Cloud Firestore (NoSQL) |
| **Storage** | Firebase Storage |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Serverless Functions** | Firebase Cloud Functions (Node.js) |
| **Maps & Location** | Google Maps API, Geolocator |
| **State Management** | ValueNotifier, StreamBuilder |

---

## 🔥 Firebase Services Used

### Cloud Firestore Collections
```
├── users/                 # User profiles (customers, technicians, admins)
├── workshops/             # Workshop locations and details
├── bookings/              # Service booking records
│   └── {bookingId}/
│       └── messages/      # Real-time chat messages
├── vehicles/              # Customer vehicles
├── spareparts/            # Spare parts inventory
├── notifications/         # In-app notifications
└── orders/                # Spare parts orders
```

### Cloud Functions
- **onBookingCreatedCreateNotificationAndPush** - Triggers when a new booking is created, sends push notification to admins

---

## 🚀 Key Technical Implementations

### 1. Role-Based Authentication & Navigation
```dart
// Automatically routes users based on their role after login
if (role == 'admin') → AdminHomeScreen
if (role == 'technician') → TechnicianMainLayout  
if (role == 'customer') → CustomerHomePage
```

### 2. Real-Time Push Notifications (FCM + Cloud Functions)
```
Customer creates booking → Firestore trigger → Cloud Function → FCM → Admin receives push
```

### 3. Real-Time Chat System
- Text, image, and file message support
- Read/unread status tracking per role
- Firestore real-time streams

### 4. Location-Based Workshop Discovery
- Haversine formula for distance calculation
- Google Maps integration for visual map view
- Geolocator for user's current location

### 5. Smart Booking System
- Real-time slot availability checking
- Prevents double-booking conflicts
- Step-by-step status tracking (Requested → Confirmed → In Progress → Completed)

### 6. Shopping Cart & E-commerce
- Add to cart functionality
- Quantity management with stock validation
- Order placement and tracking

### 7. Multi-Language Support
- English and Chinese localization
- Dynamic language switching without app restart

### 8. Theme Management
- Light/Dark mode toggle
- Persistent theme preference
- Consistent theming across all screens

---

## 📦 Dependencies

```yaml
# Core
flutter_localizations
google_fonts

# Firebase
firebase_core
firebase_auth
cloud_firestore
firebase_storage
firebase_messaging

# Authentication
google_sign_in

# Maps & Location
google_maps_flutter
flutter_map
geolocator
geocoding
map_launcher

# Media
video_player
chewie
image_picker
file_picker

# UI Components
flutter_slidable

# Utilities
shared_preferences
url_launcher
intl
```

---

## 🏃‍♂️ Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Firebase project with enabled services
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/zeinvob/car_sync.git
   cd car_sync
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your project config

4. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📊 Database Schema

```
Firestore Database
│
├── users/
│   └── {userId}
│       ├── name: string
│       ├── email: string
│       ├── role: "customer" | "technician" | "admin"
│       ├── fcmToken: string
│       └── profileImageUrl: string
│
├── workshops/
│   └── {workshopId}
│       ├── name: string
│       ├── address: string
│       ├── latitude: number
│       ├── longitude: number
│       └── services: array
│
├── bookings/
│   └── {bookingId}
│       ├── customerId: string
│       ├── workshopId: string
│       ├── vehicleId: string
│       ├── serviceType: string
│       ├── bookingDate: timestamp
│       ├── status: "requested" | "confirmed" | "in_progress" | "completed" | "cancelled"
│       └── messages/ (subcollection)
│           └── {messageId}
│               ├── text: string
│               ├── senderId: string
│               ├── senderRole: string
│               └── createdAt: timestamp
│
├── vehicles/
│   └── {vehicleId}
│       ├── customerId: string
│       ├── brand: string
│       ├── model: string
│       ├── plateNumber: string
│       └── year: number
│
├── spareparts/
│   └── {partId}
│       ├── name: string
│       ├── price: number
│       ├── stock: number
│       ├── category: string
│       └── imageUrl: string
│
├── orders/
│   └── {orderId}
│       ├── customerId: string
│       ├── items: array
│       ├── totalAmount: number
│       ├── status: string
│       └── createdAt: timestamp
│
└── notifications/
    └── {notificationId}
        ├── targetRole: string
        ├── title: string
        ├── body: string
        ├── type: string
        └── createdAt: timestamp
```

---

## 🔄 App Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION                           │
├─────────────────────────────────────────────────────────────────┤
│  Splash Screen → Login/Signup → Role Check → Route to Module   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   CUSTOMER    │     │  TECHNICIAN   │     │    ADMIN      │
├───────────────┤     ├───────────────┤     ├───────────────┤
│ • Home        │     │ • Jobs List   │     │ • Dashboard   │
│ • Book Service│     │ • Job Details │     │ • Workshops   │
│ • My Bookings │     │ • Chat        │     │ • Technicians │
│ • My Vehicles │     │ • Inventory   │     │ • Bookings    │
│ • Spare Parts │     │ • Profile     │     │ • Stock       │
│ • Cart/Orders │     └───────────────┘     │ • Orders      │
│ • Workshop Map│                           │ • Ratings     │
│ • Chat Support│                           │ • Chat Inbox  │
│ • Profile     │                           │ • Profile     │
└───────────────┘                           └───────────────┘
```

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 📁 Project Structure

```
car_sync/
├── android/                 # Android native code
├── ios/                     # iOS native code
├── lib/
│   ├── main.dart           # App entry point
│   ├── firebase_options.dart
│   ├── core/
│   │   ├── constants/      # Colors, strings, configs
│   │   ├── localization/   # i18n (EN, ZH)
│   │   ├── services/       # 20+ service classes
│   │   ├── theme/          # Theme controllers
│   │   └── widgets/        # Shared UI components
│   └── features/
│       ├── auth/           # Login, Signup, Verify
│       ├── customer/       # 16 pages
│       ├── technician/     # 6 pages
│       ├── admin/          # 14 pages
│       └── splash/         # Splash screen
├── functions/              # Firebase Cloud Functions
│   ├── index.js           # FCM notification triggers
│   └── package.json
├── assets/
│   ├── images/
│   ├── logo/
│   └── video/
└── pubspec.yaml
```

---

## 🤝 Contributing

This is an internship project. For any questions, please contact the author.

---

## 👨‍💻 Author

**Stephanie** - Flutter Mobile Developer  
📧 Email: [your-email@example.com]  
🔗 LinkedIn: [your-linkedin-profile]  
💻 GitHub: [@your-github-username]

---

## 🙏 Acknowledgments

- Flutter & Dart team for the amazing framework
- Firebase for the powerful backend services
- All open-source package contributors

---

## 📄 License

This project is proprietary and confidential.
