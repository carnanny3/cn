# Car Nanny Mobile (Flutter)

Consumer app covering the MVP flows: Auth (phone OTP), Home dashboard, My
Garage (vehicle list/add/health score), Pre-Purchase Inspection (booking +
report), Services (garage search + booking), AI Assistant chat, and Profile.

## Verified

Flutter 3.44.7 (stable) was installed and used to actually verify this app:

- `flutter create --org com.carnanny --project-name car_nanny --platforms=web,android .` generated the platform folders. `android/`, `ios/`, and `web/` are committed to this repo (not gitignored) because they contain real, hand-verified fixes — see "Building and running a real Android APK" below — that a fresh `flutter create` would not reproduce; only their own build-artifact subfolders (`android/.gradle/`, `android/app/build/`, `ios/Pods/`, etc.) are ignored.
- `flutter pub get` — all 54 dependencies resolve cleanly (had to bump `intl` to `^0.20.2` to match what `flutter_localizations` pins on this SDK).
- `flutter analyze` — **zero issues** (fixed one real compile error — a final field being reassigned in `main.dart` — and several deprecation/lint warnings found on the first pass).
- `flutter test` — the smoke test passes (app boots to the auth screen when signed out).
- `flutter build web` — full production web build succeeds.
- Ran live via a static web build in a real browser and confirmed, via the accessibility tree, that the actual UI renders correctly: title, tagline, the Sign up/Log in toggle, and that tapping "Log in" correctly hides the Full Name field and relabels the button to "Send code" — i.e., the widget tree and state management genuinely work, not just "looks plausible" source.
- iOS was not built (no macOS/Xcode available here); Android was scaffolded but not built to an APK (no Android SDK/emulator here) — `flutter analyze` and `flutter test` still exercise that code path since it's Dart, not platform-specific.

## First-time setup

This repo only contains the `lib/` source and `pubspec.yaml` — the platform
scaffolding (`android/`, `ios/`, etc.) isn't committed. From this directory:

```bash
flutter create --org com.carnanny --project-name car_nanny .
flutter pub get
```

`flutter create .` will not overwrite `lib/main.dart` or `pubspec.yaml` if
you answer "no" to any overwrite prompt for those two files — if it does
prompt, keep the versions already in this folder.

## Running against the backend

The API base URL defaults to `http://10.0.2.2:3000/api/v1` (the Android
emulator's alias for your machine's `localhost`) — this will **not** work when
running on web or desktop (Windows/macOS/Linux), since `10.0.2.2` is an
Android-emulator-only address. Override it for a real device, iOS simulator,
web, or desktop target:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Start the backend first (see `../backend/README.md`).

## Building and running a real Android APK

Verified end-to-end: set up the Android SDK (command-line tools, JDK 17,
platform-tools, platforms 35/36, build-tools 35.0.0/28.0.3 — none of that was
installed initially) and produced a working signed release APK via
`flutter build apk --release --dart-define=API_BASE_URL=http://<your-lan-ip>:3000/api/v1`.

Two real issues surfaced doing this that are now fixed and worth knowing about:

- **`android:usesCleartextTraffic="true"`** is set in `android/app/src/main/AndroidManifest.xml`. Without it, Android silently blocks all plain `http://` traffic for apps targeting API 28+ (we target 36) — the app fails with a generic "connection failed" error that looks identical to a wrong-IP or firewall problem, which cost real debugging time. **This must be removed (or replaced with a proper `network_security_config.xml` scoped to specific trusted hosts) once the backend is served over HTTPS** — leaving a blanket cleartext allowance in a production release is a real security regression.
- **A real device on your Wi-Fi cannot reach `localhost` or `10.0.2.2`** — those only resolve to "the device itself" (phone) or "the host machine, from an emulator" respectively. A physical phone needs your PC's actual LAN IP (`ipconfig` / `Get-NetIPAddress`, the Wi-Fi adapter's IPv4 address), and **that address is DHCP-assigned and can change** (observed changing mid-session here) — if a previously-working APK suddenly can't connect, re-check the current IP before assuming anything else is broken. A DHCP reservation on your router fixes this permanently.

## Demo mode

Several screens (Home, My Garage, Inspection Report, Garage Search, AI
Assistant) fall back to realistic demo data if the backend can't be reached,
so you can see every screen even before the API is running. Actions that
write data (adding a vehicle, booking an inspection/service) require a live
backend and will show an error otherwise.

## Structure

```
lib/
  core/
    api/          Dio-based API client, base URL + auth header + 401 handling
    state/         AuthState (register/login/OTP/session, ChangeNotifier)
    theme/         Design tokens + light/dark ThemeData
    app_router.dart  go_router config (auth gate + 5-tab shell + detail routes)
  shell/           Bottom navigation shell (Home/Garage/Services/AI/Profile)
  features/
    auth/          Phone entry + OTP screens
    home/          Dashboard
    garage/        Vehicle list, add vehicle, vehicle health detail
    inspection/    Book inspection, inspection report (AI recommendation + disclaimer)
    services/      Service category grid, garage search + booking
    ai/            AI Assistant chat
    profile/       Account menu, logout
```

## What's not wired up yet (Phase 2 in the product spec)

Buy-a-Car marketplace, Warranty/Insurance marketplaces, Roadside Assistance,
Concierge services, and full RTL/Arabic string translation (the app declares
`ar` as a supported locale for correct system-level RTL layout mirroring, but
UI strings are still English-only — translate `lib/features/**` strings
before shipping to Arabic-speaking users).
