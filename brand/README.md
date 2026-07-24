# Car Nanny — Brand Asset Package

## Current source of truth

You provided the real logo files directly: **`CarNanny Black.png`** (500×500,
full lockup on black) and **`CarNanny White.png`** (438×438, a pale/low-contrast
variant on white). Everything in **`final/`** is a plain resize of these two
files — no redrawing, recoloring, cropping, or rounding.

> **Superseded:** the `svg/` and `png/` folders are an earlier vector
> *recreation* I built by hand when only a pasted chat image (not a real
> file) was available. They're kept for reference but are no longer the
> source of truth now that the real files exist — don't use them for
> anything production-facing.

## What's in `final/`

```
final/
  app-icons/      Resized from CarNanny Black.png (full lockup) — 16px to 1024px. Used where icons render large enough for the wordmark to stay legible (Android/iOS launcher icons on modern devices, printed materials, etc.)
  icon-only/      Cropped to just the shield+car+checkmark (no wordmark) from CarNanny Black.png, resized 16px to 1024px + its own favicon.ico. This is the one actually wired into every small/square usage across the apps (see below) — favicons, PWA/manifest icons, social avatars, and both native app icon sets.
  favicon/        favicon.ico is full-lockup (kept for reference/comparison only — not what's wired in); icon-192.png/icon-512.png are the icon-only crop (these ARE wired into the PWA manifest)
  social/         Square avatar at 400/512/1024px — icon-only crop, for LinkedIn/X/Instagram profile pictures
  white-variant/  CarNanny White.png resized to 256/512/1024px, unmodified otherwise
```

### The icon-only crop

`CarNanny Black.png` is the full lockup (shield + car + checkmark + "CAR
NANNY" + tagline) — resizing that down to favicon sizes made the text
illegible (16px read as a gold blob). `icon-only/` is a straight crop of just
the badge — determined by scanning the source pixel-by-pixel to find the
icon's exact bounding box (x:178–331, y:120–292 in the 500×500 original,
wordmark starting at y:304) and extracting a 210×210 square centered on it
with even padding on all sides, clear of the text. No redrawing — just crop
+ resize, same as everything else in this package. At 16–32px it now reads
as a recognizable small badge instead of a blob.

## Things worth knowing before you use these

- **`CarNanny White.png` is genuinely low-contrast, not corrupted.** At normal
  viewing it looks like only the checkmark and "NANNY" are present — the
  shield outline, car icon, and "CAR" are actually in the file, just in very
  pale tones close to the white background color, so they're barely visible
  at a glance. Confirmed by inverting the image's colors, which reveals all
  elements clearly. Resized as-is, this low contrast carries through to every
  size in `white-variant/`.

## Already wired into the apps (using the real, resized/cropped files)

- **Android** — `../mobile/android/app/src/main/res/mipmap-*/ic_launcher.png` — **icon-only** crop at every density (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi)
- **iOS** — `../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` — **icon-only** crop at all 15 required sizes (20/29/40/60/76/83.5pt @1x/2x/3x, plus the 1024 App Store icon). The `ios/` platform folder didn't exist yet in this environment (no prior Xcode/macOS session had generated it) — I ran `flutter create --platforms=ios` to scaffold it (that step needs only the Flutter CLI, not Xcode), then replaced every placeholder icon in the asset catalog directly with the real crop. The 1024 App Store icon was flattened to remove its alpha channel entirely (`hasAlpha: false` confirmed) — Apple's App Store Connect rejects icons submitted with any transparency.
- **Web (browser tabs)** — `../mobile/web/favicon.png`, `../admin/public/favicon.ico` — icon-only crop
- **Web (PWA install icon)** — `../mobile/web/icons/*.png` (192/512, incl. maskable) — icon-only crop
- **Social avatars** — `final/social/avatar-{400,512,1024}.png` — icon-only crop (not auto-wired anywhere, since where you use these — LinkedIn, X, etc. — is outside this codebase; grab whichever size the platform wants)

Everything square/small now uses the icon-only crop consistently. The only
places still using the full lockup are `final/app-icons/` (kept available
for contexts where the wordmark should show, e.g. a splash screen or printed
material) and `final/favicon/favicon.ico` (kept for side-by-side comparison,
superseded by `final/favicon/icon-192.png`'s icon-only sibling for actual use).

## Regenerating

```bash
cd tools
npm install   # first time only

# Run in this order — resize-real-logo.js and ios-icons.js both depend on
# the icon-only-master.png that crop-icon.js produces.
node crop-icon.js          # final/icon-only/ — crop bounds are hardcoded, re-derive if the source image changes
node resize-real-logo.js   # final/app-icons/, favicon/, social/, white-variant/
node ios-icons.js          # writes straight into mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

All scripts read `../CarNanny Black.png` (and White for the white-variant)
directly — replace those files with updated exports (same filenames) and
rerun. If the icon moves within a new export, `crop-icon.js`'s hardcoded
crop box (`x:149-359, y:90-300`) will need updating to match — recompute it
by scanning row/column brightness for the new file rather than guessing
(see the analysis approach in this session: find vertical content bands to
separate icon from wordmark, then the horizontal bounding box within the
icon's band).

After regenerating, re-copy into the apps (these are files, not symlinks,
so edits to `final/` don't automatically propagate):
```bash
cd ..
cp final/icon-only/favicon.ico ../admin/public/favicon.ico
cp final/icon-only/icon-192.png ../admin/public/icon-192.png
cp final/icon-only/icon-32.png ../mobile/web/favicon.png
cp final/favicon/icon-192.png ../mobile/web/icons/Icon-192.png
cp final/favicon/icon-512.png ../mobile/web/icons/Icon-512.png
cp final/favicon/icon-192.png ../mobile/web/icons/Icon-maskable-192.png
cp final/favicon/icon-512.png ../mobile/web/icons/Icon-maskable-512.png
cp final/icon-only/icon-48.png  ../mobile/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp final/icon-only/icon-72.png  ../mobile/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp final/icon-only/icon-96.png  ../mobile/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp final/icon-only/icon-144.png ../mobile/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp final/icon-only/icon-192.png ../mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

(For iOS, `node ios-icons.js` already writes directly into
`mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/` — no manual copy needed.)

**Known limitation:** the source `CarNanny Black.png` is 500×500. Upscaling
its icon crop to 1024px for the iOS App Store icon means that file is
slightly soft/upscaled rather than native-resolution crisp — acceptable for
device home-screen sizes, worth knowing if you're submitting to the App
Store and want the sharpest possible 1024 asset (would need a higher-res
source export).
