# Release signing (upload keystore)

Google Play rejects debug-signed builds. Publishing needs an **upload keystore**
that you create and keep — it cannot be generated for you, because it is a
credential: the file plus its passwords are what prove a release genuinely comes
from you.

Two things follow from that, and both are permanent:

- **If it leaks**, someone else can publish builds that Android accepts as
  Car Nanny updates.
- **If you lose it**, you can never update the Play listing again. You would
  have to publish a new app under a new package name and lose your install base
  and reviews. (Play App Signing offers a key-reset path, but only if you
  enrolled — see step 4.)

## 1. Create the keystore

Run this yourself, from `mobile/android`. It prompts for a password twice and
for your name/organisation details.

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Notes:
- `-validity 10000` (~27 years) is what Play expects; a key that expires before
  your last update breaks publishing.
- Use a strong, unique password and store it in a password manager **now**.
- The JDK's `keytool` lives at
  `D:\android-sdk\jdk-extract\jdk-17.0.19+10\bin\keytool.exe` if it isn't on
  your PATH.

## 2. Point the build at it

Create `mobile/android/key.properties`:

```properties
storePassword=<the password you just chose>
keyPassword=<same, unless you set a separate key password>
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` is resolved relative to `mobile/android/app/`, so if you keep the
`.jks` in `mobile/android/` use `../upload-keystore.jks`.

Both `key.properties` and `*.jks` are already in `android/.gitignore`. Do not
remove those entries, and do not commit either file. Back them up somewhere
private (password manager, encrypted drive) — not the repo.

## 3. Build a release bundle

Play wants an App Bundle (`.aab`), not an APK:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://cn-production-5a70.up.railway.app/api/v1
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Confirm it is really signed with your key (not the debug key):

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The owner/issuer should show the details you entered in step 1, **not**
`CN=Android Debug`.

## 4. Enrol in Play App Signing

When you upload the first bundle, Play offers Play App Signing. Accept it. Play
then holds the actual *app signing key* and your keystore becomes only the
*upload key* — which means a lost or compromised upload key can be reset by
Google support instead of ending the listing. Without it, step 1's warnings are
absolute.
