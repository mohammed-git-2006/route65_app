flutter build apk --release
adb uninstall com.route65.route_65
adb install build\app\outputs\flutter-apk\app-release.apk
