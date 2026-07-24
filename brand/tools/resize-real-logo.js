// Resize-only pipeline: takes the user's actual provided logo files
// (CarNanny Black.png, CarNanny White.png) and produces every required
// size. No redrawing, recoloring, or rounding — pure resize (the social/PWA
// icons additionally source from the icon-only crop produced by
// crop-icon.js, so run that script FIRST).
const sharp = require('sharp');
const toIco = require('to-ico');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'final');

const BLACK_SRC = path.join(ROOT, 'CarNanny Black.png');
const WHITE_SRC = path.join(ROOT, 'CarNanny White.png');
// Icon-only crop (no wordmark) — produced by crop-icon.js. Run that script
// first; social avatars and PWA/favicon manifest icons are small/square
// enough that the icon-only crop reads better than the full lockup.
const ICON_ONLY_SRC = path.join(OUT, 'icon-only', 'icon-only-master.png');

async function resizeTo(srcPath, size, outPath) {
  await sharp(srcPath).resize(size, size).png().toFile(outPath);
  console.log('wrote', outPath, `${size}x${size}`);
}

async function main() {
  // --- App icons (from the black master) ---
  const appIconSizes = [1024, 512, 256, 192, 180, 152, 144, 120, 96, 72, 60, 48, 40, 36, 32, 29, 16];
  for (const size of appIconSizes) {
    await resizeTo(BLACK_SRC, size, path.join(OUT, 'app-icons', `icon-${size}.png`));
  }

  // --- Favicons + multi-res .ico ---
  const faviconSizes = [16, 32, 48];
  for (const size of faviconSizes) {
    await resizeTo(BLACK_SRC, size, path.join(OUT, 'favicon', `favicon-${size}.png`));
  }
  const icoBuffers = await Promise.all(
    faviconSizes.map((s) => sharp(BLACK_SRC).resize(s, s).png().toBuffer()),
  );
  fs.writeFileSync(path.join(OUT, 'favicon', 'favicon.ico'), await toIco(icoBuffers));
  console.log('wrote favicon.ico (16/32/48 multi-res)');

  // PWA / manifest icons — icon-only crop (favicon.ico above stays full-lockup for reference)
  await resizeTo(ICON_ONLY_SRC, 192, path.join(OUT, 'favicon', 'icon-192.png'));
  await resizeTo(ICON_ONLY_SRC, 512, path.join(OUT, 'favicon', 'icon-512.png'));

  // --- Social avatars — icon-only crop (reads better at profile-picture sizes, and survives circular cropping) ---
  for (const size of [1024, 512, 400]) {
    await resizeTo(ICON_ONLY_SRC, size, path.join(OUT, 'social', `avatar-${size}.png`));
  }

  // --- White/light variant, resized at the same representative sizes ---
  for (const size of [1024, 512, 256]) {
    await resizeTo(WHITE_SRC, size, path.join(OUT, 'white-variant', `logo-white-${size}.png`));
  }

  console.log('\nAll resize-only assets generated from the real logo files.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
