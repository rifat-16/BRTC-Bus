# 🚌 BRTC Sakhipur - Official E-Ticketing & Admin Control Center

A modern, high-performance, real-time Flutter Web & Mobile application for **BRTC Sakhipur Bus Service** (Sakhipur, Borochowna, Garobazar, Sagordighi to Dhaka routes). Built with Clean Architecture, Cloud Firestore Streams, Provider State Management, Google Authentication, Material 3 Design, and Enterprise Admin Management.

---

## 🌐 Live Production Application
- **Production Web Portal:** [https://brtc-bus-sakhipur.web.app](https://brtc-bus-sakhipur.web.app)
- **Google Search Listing:** `BRTC Sakhipur - BRTC Bus Ticket Booking Portal`

---

## ✨ Key Features & Business Workflows

### 📱 Passenger App Features
- **Real-Time Seat Booking:** 4 visual seat states (`Available`, `Selected`, `Locked`, `Booked`).
- **Dynamic Station-to-Station Fares:** Fares automatically calculate based on `from ➔ to` station pairs via Firestore `route_fares`.
- **Live Seat Locking:** Seats selected during checkout are locked temporarily to prevent double-booking.
- **bKash Payment Integration:** Step-by-step Send Money guidelines with dynamic bKash Personal Number and TrxID verification.
- **Official E-Ticket Stub:** Generates E-Tickets with live status badges (`PENDING`, `PAID`, `REJECTED`), tear-off line aesthetics, and supervisor QR codes.
- **One-Click Ticket Download:** Converts verified tickets into downloadable PNG images saved directly to the device gallery or browser downloads.
- **My Tickets History:** Chronological ticket list sorted with the newest tickets at the top.

### 🎛️ Admin Control Center
- **Overview Dashboard:** Revenue analytics, pending request counters, live bus trip manifest quick links.
- **Dynamic Payment Control:** Edit bKash Personal Mobile Number live across the platform (`settings/payment_config`).
- **Route Fare Hub:** Real-time station-to-station fare management with quick adjustment increments (`-50`, `-10`, `+10`, `+50`).
- **Real-Time Seat Manager:** Manually lock/unlock seat selections for counter sales.
- **Counter Cash Sales Module:** Issue cash tickets directly at bus counters.
- **1-Page A4 PDF Webill & Trip Manifest:** Generates official A4 PDF Webills and passenger manifests for bus supervisors with one-click print/download (`PdfService`).
- **Revenue Analytics:** Time-range filters (`ALL`, `TODAY`, `WEEK`, `MONTH`) with payment breakdown charts.

---

## 🔒 Security Architecture (100% Hack-Proof Backend)

- **Firestore Security Rules (`firestore.rules`):**
  - Server-enforced authorization deployed live to Firebase (`brtc-bus-sakhipur`).
  - Read/Write privileges for admin features are guarded by checking `request.auth.token.email` against the `admins/{email}` Firestore collection.
- **Zero Hardcoded Admin Credentials:**
  - Pure dynamic RBAC: Adding or revoking an email in `admins/{email}` grants or revokes Admin privileges in real-time with zero code changes.

---

## 🏗️ Clean Architecture Directory Structure

```text
lib/
├── core/
│   ├── app_colors.dart                 # Material 3 brand colors & smooth page route builders
│   └── app_constants.dart              # Global constants & station lists
├── models/
│   ├── bus_model.dart                  # Bus service data model
│   ├── ticket_model.dart               # Ticket transaction model
│   └── route_fare_model.dart           # Station-to-station fare model
├── providers/
│   ├── auth_provider.dart              # Authentication & dynamic admin stream state
│   ├── booking_provider.dart           # Seat selection & locking state
│   └── admin_provider.dart             # Admin portal state management
├── services/
│   ├── auth_service.dart               # Google Auth & Firebase Auth integration
│   ├── firestore_service.dart          # Real-time Firestore streams & mutations
│   ├── pdf_service.dart                # Official A4 Webill PDF document generator
│   └── download_service.dart           # Cross-platform image/file downloader
├── widgets/
│   ├── admin/                          # Modular Admin Sub-Widgets
│   │   ├── admin_counter_tab.dart
│   │   ├── admin_directory_tab.dart
│   │   ├── admin_e_ticket_dialog.dart
│   │   ├── admin_overview_tab.dart
│   │   ├── admin_payment_config_card.dart
│   │   ├── admin_pending_tab.dart
│   │   ├── admin_route_fare_hub.dart
│   │   └── admin_seat_manager_tab.dart
│   ├── home/                           # Modular Home Sub-Widgets
│   │   ├── home_helpline_modal.dart
│   │   ├── home_search_card.dart
│   │   ├── home_shortcuts_section.dart
│   │   └── home_user_menu_modal.dart
│   ├── brtc_express_bus_widget.dart    # Animated Express Bus & Canvas Road Painter
│   ├── official_e_ticket_stub.dart     # Printable E-Ticket Stub component
│   └── manual_payment_verification_card.dart
└── screens/                            # Main Application Screens
    ├── admin_screen.dart               # Admin Control Center (~180 lines)
    ├── bus_list_screen.dart            # Bus Search Results
    ├── bus_manifest_screen.dart          # Trip Manifest & Webill
    ├── home_screen.dart                # Passenger Home Dashboard (~220 lines)
    ├── login_screen.dart               # Google Sign-In Screen
    ├── manual_verification_screen.dart # TrxID Submission Screen
    ├── my_tickets_screen.dart          # Ticket History
    ├── payment_screen.dart             # bKash Payment Screen
    ├── revenue_analytics_screen.dart   # Revenue Dashboard
    ├── seat_plan_screen.dart           # Seat Selection Screen
    ├── splash_screen.dart              # Animated Entrance Splash (~260 lines)
    └── ticket_screen.dart              # Live Ticket Status & Download (~260 lines)
```

---

## 🛠️ Getting Started & Local Development

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.22.0`)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/brtc.git
   cd brtc
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application locally:**
   ```bash
   flutter run
   ```

---

## 🚀 Production Build & Firebase Deployment

### 1. Build Web Release
```bash
flutter build web --release
```

### 2. Deploy to Firebase Hosting & Firestore Rules
```bash
firebase deploy
```

*(Or deploy hosting only: `firebase deploy --only hosting`)*

---

## 📄 License & Copyright

© 2026 বাংলাদেশ সড়ক পরিবহন কর্পোরেশন (বিআরটিসি). All Rights Reserved.  
Official BRTC Sakhipur Bus E-Ticketing System.
