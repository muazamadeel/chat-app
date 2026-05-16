# ChatBox - Professional Flutter Real-time Chat Application

![ChatBox Banner](screenshots/splash.png)

## 🚀 Overview
**ChatBox** is a feature-rich, high-performance real-time messaging application built with Flutter and Firebase. It offers a seamless communication experience with support for multimedia sharing, voice/video calls, and live location tracking, all wrapped in a modern, premium dark-themed UI.

## ✨ Key Features

- **🔐 Robust Authentication**: Secure user onboarding via Email/Password and Google Sign-in integration.
- **💬 Real-time Messaging**: Instant message delivery and synchronization using Firebase Cloud Firestore.
- **📞 Voice & Video Calls**: High-quality, low-latency real-time communication powered by WebRTC.
- **📁 Multimedia Sharing**: 
  - 📷 Images & 🎥 Videos
  - 📄 PDF Documents
  - 🎙️ Voice Notes/Audio Messages
- **📍 Live Location Tracking**: Real-time location sharing and interactive tracking on Google Maps.
- **📱 Status/Stories**: Share moments with your contacts through a dedicated status view.
- **🔒 Security First**: End-to-end message encryption and secure data handling.
- **🌓 Premium UI/UX**: A sleek, dark-themed interface with smooth animations and responsive design.
- **🔔 Push Notifications**: Stay updated with real-time alerts for new messages and calls.

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage, Messaging)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Real-time Comm**: [WebRTC](https://webrtc.org/)
- **Maps**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- **Database (Local)**: [SQFlite](https://pub.dev/packages/sqflite)

## 🌐 Live Demo

Experience the app instantly without installing anything! Try the live emulator here:

👉 **[Launch ChatBox Live Demo](https://appetize.io/embed/b_uebciv3zkvgxtqwzyf4hzmciaq)**

*(Note: The emulator may take a few seconds to boot up. Click "Tap to play" to start.)*

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
   - Create a new Firebase project.
   - Add Android/iOS apps and download `google-services.json` / `GoogleService-Info.plist`.
   - Place them in the respective `android/app` and `ios/Runner` directories.
   - Enable Auth, Firestore, and Storage in the Firebase Console.
4. **Google Maps API**:
   - Obtain an API key from the [Google Cloud Console](https://console.cloud.google.com/).
   - Add the key to `AndroidManifest.xml` and `AppDelegate.swift`.
5. **Run the App**:
   ```bash
   flutter run
   ```

## 📜 License
Distributed under the MIT License. See `LICENSE` for more information.

---
Developed with ❤️ by [Muazam Adeel](https://github.com/muazamadeel)
