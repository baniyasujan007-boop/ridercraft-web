# ridercraft_mobile

RiderCraft - premium motorcycle service, parts and accessories mobile app.

## Google Sign-In build configuration

The app uses the SAME existing Web OAuth client ID used by the RiderCraft
website. The backend verifies Google ID tokens against `GOOGLE_CLIENT_ID`
(`POST /auth/google`); on Android the `google_sign_in` plugin mints the ID
token with that client as its audience via `serverClientId`, which is exactly
what the backend expects.

If `GOOGLE_WEB_CLIENT_ID` is missing at build time, the app shows:
"Google Sign-In is not configured for this build."

### Supplying GOOGLE_WEB_CLIENT_ID

Never hardcode the ID in Dart. Pass it at build/run time with `--dart-define`:

```bash
# Development (device/emulator)
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID="EXISTING_WEB_CLIENT_ID"

# Release APK
flutter build apk --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID="EXISTING_WEB_CLIENT_ID"

# Web
flutter build web \
  --dart-define=GOOGLE_WEB_CLIENT_ID="EXISTING_WEB_CLIENT_ID"
```

`EXISTING_WEB_CLIENT_ID` is one of the values already in the repo's env files
(identical on both sides):
- `client/.env` → `REACT_APP_GOOGLE_CLIENT_ID`
- `server/.env` → `GOOGLE_CLIENT_ID`

Never commit. Keep `client/.env` and `server/.env` untracked.

### Safe build helper

`scripts/build_android.sh` (repo root) wraps the commands above. It reads the
ID from `GOOGLE_WEB_CLIENT_ID` or `--client-id=<id>`, falling back to the
`GOOGLE_CLIENT_ID` in `server/.env`, and never prints or commits it:

```bash
./scripts/build_android.sh          # release APK
GOOGLE_WEB_CLIENT_ID="..." ./scripts/build_android.sh web
GOOGLE_WEB_CLIENT_ID="..." ./scripts/build_android.sh run
```

### Android OAuth client (Google Cloud Console)

The Android app package is `com.ridercraft.ridercraft_mobile`. Release builds
use the debug signing configuration (see `android/app/build.gradle.kts`), so
the APK is signed by the default debug keystore
(`~/.android/debug.keystore`, alias `androiddebugkey`).

A Google Cloud Android OAuth 2.0 client must exist for this package with the
actual signing SHA-1/SHA-256 fingerprint of that keystore (the Web OAuth
client — the one `serverClientId` sends — remains unchanged). Verify/register
in: Google Cloud Console → APIs & Services → Credentials → Android OAuth 2.0
Client.

To check the current fingerprint:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android
```

## Running the app

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```