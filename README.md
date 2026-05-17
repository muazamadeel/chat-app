# ChatBox - Professional Offline-First Flutter Calling & Messaging Application

## 🚀 Overview
**ChatBox** is a high-performance, production-ready real-time communication platform built with Flutter and Firebase. Engineered with a hybrid offline-first database sync model, end-to-end encryption, and low-latency peer-to-peer WebRTC voice/video calling, ChatBox offers a reliable, enterprise-grade messaging experience wrapped in a modern, premium Blue-White theme.

---

## ✨ Advanced Features

* **🎨 Premium Blue-White UI/UX**:
  * Sleek brand design system based on a high-fidelity Blue palette (`#246BFD`) with top curved sheet panels and smooth fluid layouts.
  * Modern card-based listing style with custom drop-shadow containers for all chat items.
  * Animated pill-highlight active indicator in the bottom navigation bar.
* **📞 Real-time Voice & Video Calls (WebRTC)**:
  * Low-latency peer-to-peer communication using `RTCPeerConnection` with STUN/TURN server signaling.
  * Custom slide-up caller notification action sheet sheet with gorgeous visual controls and instant accept/decline flows.
* **🔄 Hybrid Database Sync (Offline-First)**:
  * Combines Firebase Cloud Firestore with an optimized local SQLite cache (`SQFlite`).
  * Integrates real-time connectivity status listeners (`connectivity_plus`) to detect internet changes.
  * Automated queue-based message push to seamlessly sync offline pending messages as soon as connectivity resumes.
* **🔐 Robust Cryptographic Protection**:
  * Custom end-to-end encrypted payload encryption engine.
  * Secure on-device hashing of passwords using PBKDF2/SHA-256 equivalent standard algorithms.
* **🌍 Global Localization (l10n Engine)**:
  * Full application internationalization supporting **English**, **Urdu**, and **French** out-of-the-box.
* **📁 Diverse Multimedia Sharing**:
  * 📷 Images & 🎥 Videos
  * 📄 PDF Documents
  * 🎙️ Voice Notes/Audio Messages
* **📍 Live Location Sharing**: Real-time location sharing and interactive tracking using high-fidelity Google Maps layers.

---

## 🛠️ Technology Stack

* **Frontend**: [Flutter](https://flutter.dev/) (Dart)
* **Backend Database & Storage**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage)
* **Real-time Communication**: [WebRTC](https://webrtc.org/) (Custom signaling architecture)
* **Local Database**: [SQFlite](https://pub.dev/packages/sqflite) (Offline cache)
* **State Management & Helpers**: [GetX](https://pub.dev/packages/get) & SharedPreferences
* **Maps Integration**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

## 🌐 Live Demo

Experience the app instantly inside an interactive web emulator! Try the live demo here:

👉 **[Launch ChatBox Live Demo](https://appetize.io/embed/b_uebciv3zkvgxtqwzyf4hzmciaq)**

*(Note: Click "Tap to play" inside the window to boot the virtual emulator.)*

---

## ⚙️ Installation & Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/muazamadeel/chat-app.git
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration**:
   - Create a Firebase Project in the [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS platforms and download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Place them in `android/app/` and `ios/Runner/` directories respectively.
   - Enable Email/Password Auth, Cloud Firestore, and Cloud Storage.
4. **Google Maps API Setup**:
   - Obtain a Maps API key from the [Google Cloud Console](https://console.cloud.google.com/).
   - Inject the key into `AndroidManifest.xml` (Android) and `AppDelegate.swift` (iOS).
5. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📜 License
Distributed under the MIT License. See `LICENSE` for more information.

---
Developed with ❤️ by [Muazam Adeel](https://github.com/muazamadeel)
