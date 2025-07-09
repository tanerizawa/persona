# Firebase Push Notifications Setup (Optional)

Push notifications are **optional** in Persona Assistant and are disabled by default. If you want to enable push notifications, follow this guide.

## Current Status

Push notifications are **disabled** by default via the `.env` configuration:
```properties
ENABLE_PUSH_NOTIFICATIONS=false
```

## Why Firebase is Optional

- **Core functionality works without Firebase**: All main features (AI chat, mood tracking, psychology tests) work without push notifications
- **Privacy-focused**: Users may prefer local-only operation
- **Simplified setup**: Reduces initial configuration complexity
- **Resource efficient**: Avoids unnecessary Firebase overhead when not needed

## Enabling Push Notifications (Optional)

If you want to enable push notifications, follow these steps:

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add Android and/or iOS app to your project

### 2. Download Configuration Files

**For Android:**
1. Download `google-services.json`
2. Place it in `android/app/` directory

**For iOS:**
1. Download `GoogleService-Info.plist`
2. Place it in `ios/Runner/` directory

### 3. Update Configuration

Update your `.env` file:
```properties
ENABLE_PUSH_NOTIFICATIONS=true
```

### 4. Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### Firebase Configuration Errors

If you see Firebase-related errors but have push notifications disabled:
- ✅ This is normal and expected
- ✅ The app will continue to work normally
- ✅ The error message will disappear once Firebase is properly configured or when push notifications remain disabled

### Common Error Messages

```
Failed to load FirebaseOptions from resource
```
- **Solution**: This is expected when `ENABLE_PUSH_NOTIFICATIONS=false`
- **Action**: No action needed unless you want to enable push notifications

## Firebase Configuration Files Structure

```
android/
├── app/
│   ├── google-services.json    # Firebase config for Android
│   └── ...
└── ...

ios/
├── Runner/
│   ├── GoogleService-Info.plist  # Firebase config for iOS
│   └── ...
└── ...
```

## Feature Toggle Benefits

This optional approach provides:
- **Faster development**: No Firebase setup required for core features
- **Privacy compliance**: No external dependencies for basic functionality
- **Flexible deployment**: Can enable/disable per environment
- **Resource optimization**: Smaller app size when notifications not needed
