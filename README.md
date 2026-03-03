# Focus or Else (FoE)

A social accountability mobile app built with Flutter. Stay accountable to your goals with friends as verifiers and real consequences.

## 🚀 Features

- **Social Accountability**: Create pacts with friends as verifiers
- **Real Consequences**: Set meaningful consequences for failed goals
- **Evidence Submission**: Photo, video, and text proof of completion
- **Live Countdown Timers**: Track deadlines in real-time
- **Social Feed**: See friends' pact completions and consequences
- **Google OAuth**: Secure authentication
- **Push Notifications**: Stay on track with timely reminders

## 📋 Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Firebase account
- Android Studio / Xcode (for mobile development)
- Git

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/kevj-github/focusorelse.git
cd focusorelse
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

**IMPORTANT**: This project uses environment variables for Firebase configuration.

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Fill in your Firebase configuration in the `.env` file:
   - Get these values from your Firebase Console
   - See [SECURITY.md](SECURITY.md) for detailed instructions

3. **Never commit the `.env` file** - it contains sensitive API keys

### 4. Firebase Setup

The project requires the following Firebase services:

- **Firebase Auth** (Google Sign-In)
- **Cloud Firestore** (Database)
- **Firebase Storage** (Media storage)
- **Firebase Cloud Messaging** (Push notifications)

Configuration files needed (not committed to git):

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Download these from your Firebase Console and place them in the correct directories.

### 5. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── providers/                # State management (Provider)
├── screens/                  # UI screens
│   ├── auth/                # Authentication screens
│   ├── home/                # Home/Feed screen
│   ├── pacts/               # Pact management screens
│   └── profile/             # Profile screens
├── services/                 # Business logic services
└── widgets/                  # Reusable UI components
```

## 🔒 Security

- All API keys are stored in `.env` file (not committed)
- Firebase configuration uses environment variables
- See [SECURITY.md](SECURITY.md) for security guidelines

## 📚 Documentation

- [Product Requirements Document](iter1/FoE_Product_Requirements_Document.md)
- [Flutter Implementation Plan](iter1/Flutter_Implementation_Plan.md)
- [Backend Setup Guide](BACKEND_SETUP_COMPLETE.md)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage, FCM)
- **Authentication**: Google OAuth
- **UI**: Material Design 3, Custom dark theme

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is private and not licensed for public use.

## 🐛 Issues

Found a bug? Please create an issue on GitHub with:

- Description of the bug
- Steps to reproduce
- Expected behavior
- Screenshots (if applicable)

## 📞 Contact

For questions or support, please open an issue on GitHub.

---

**⚠️ Important**: Never commit `.env`, `google-services.json`, or `GoogleService-Info.plist` files to version control.
