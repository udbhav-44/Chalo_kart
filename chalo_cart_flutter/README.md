# Chalo Cart Flutter App

A Flutter application for the Chalo Kart golf cart transportation system.

## Getting Started

### Prerequisites
- Flutter 3.0+
- Dart SDK
- Android Studio / Xcode (for running on emulators)
- A physical device or emulator

### Setup Instructions

1. Clone the repository and navigate to this directory

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Development Notes
- The app requires the backend server to be running
- Default backend URL is http://localhost:8000
- For iOS development, run `pod install` in the ios/ directory
- For Android development, ensure you have the latest Android SDK

### Troubleshooting
- If you encounter build errors, try:
  ```bash
  flutter clean
  flutter pub get
  ```
- For iOS issues, try:
  ```bash
  cd ios
  pod install
  cd ..
  ```

## Additional Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)
