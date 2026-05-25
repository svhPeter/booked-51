#!/bin/bash
# [ignoring loop detection]
set -e

echo "=== DocBook Native Setup and Local Build Verification ==="
echo "[1] Resetting Flutter build caches and modules..."
flutter clean
flutter pub get

echo "[2] Synchronizing CocoaPods project files for iOS..."
cd ios
pod install --repo-update
cd ..

echo "[3] Building Flutter Web target..."
flutter build web --release --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1

echo "[4] Compiling Android target to Debug APK..."
flutter build apk --debug --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1

echo "[5] Compiling iOS target in Debug mode..."
flutter build ios --debug --no-codesign --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1

echo "=== Build compilation check completed successfully! ==="
