# Android Build Guide for DocBook

> We are currently looking for a Mac/Windows developer machine with Android SDK installed to build the APK.

## Prerequisites

### 1. Install Android Studio
- Download from: https://developer.android.com/studio
- Install and open once to complete setup wizard
- Android Studio installs the latest Android SDK by default

### 2. Install Android SDK Platform & Build-Tools
If Android Studio didn't install them automatically:

```bash
# Open Android Studio → Settings → Appearance & Behavior → 
# Android SDK → SDK Platforms → select Android 14+ (API 34)
# SDK Tools → select "Android SDK Build-Tools 34" + 
# "Android SDK Command-line Tools (latest)"
```

Or via command line (after installing command-line tools):

```bash
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
```

### 3. Set ANDROID_HOME (if not auto-detected)
Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

Then reload: `source ~/.zshrc`

## Verify Setup

```bash
flutter doctor -v
```

Ensure all checkmarks are green, especially:
- `[✓] Android toolchain` — including the correct SDK version
- `[✓] Android Studio` — installed and configured

If Android licenses are not accepted:

```bash
flutter doctor --android-licenses
```

Type `y` for all prompts.

## Build Debug APK

```bash
cd mobile

flutter build apk --debug --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1
```

### APK Output
```
build/app/outputs/flutter-apk/app-debug.apk
```

## Install APK on Phone

1. **Enable installation from unknown sources:**
   - Settings → Security → Install unknown apps → File Manager → Allow
   - (Location varies by Android version/manufacturer)

2. **Transfer APK to phone:**
   - USB cable: `adb install build/app/outputs/flutter-apk/app-debug.apk`
   - Or email/share the APK file to phone

3. **Install:**
   - Open the APK file on the phone
   - Tap "Install"
   - Open the installed DocBook app

## Build Release APK (for Play Store)

### 1. Create Keystore
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Configure Signing
Create `mobile/android/key.properties`:
```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=/Users/<you>/upload-keystore.jks
```

### 3. Build Release
```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 4. (Optional) Split APK per ABI
```bash
flutter build apk --release --split-per-abi
```

Outputs:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## Troubleshooting

| Issue | Fix |
|---|---|
| `Android license status unknown` | Run `flutter doctor --android-licenses` |
| `No Android SDK found` | Install Android Studio or set `ANDROID_HOME` |
| `gradle build failed` | Check `mobile/android/gradle.properties` for memory settings |
| `API_BASE_URL not defined` | Ensure `--dart-define=API_BASE_URL=...` is passed |

## Environment

| Tool | Version |
|---|---|
| Flutter | 3.x |
| Dart SDK | 3.x |
| Gradle | 8.x |
| Android SDK | API 34 |
| Build Tools | 34.0.0 |
| Kotlin | 1.9.x |
